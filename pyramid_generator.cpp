#include <algorithm>
#include <expected>
#include <fstream>
#include <iostream>
#include <regex>
#include <sstream>
#include <string>
#include <string_view>
#include <variant>
#include <vector>
#include "pyramid_language.hpp"

const Field* field(std::string name) {
    std::ranges::transform(name, name.begin(), [](unsigned char c) {
        return static_cast<char>(std::toupper(c));
    });
    for (const auto& item : schema) if (item.sql == name) return &item;
    return nullptr;
}

struct TextEq { const Field* field; std::string op, value; };
struct NumberCmp { const Field* field; std::string op; double value; };
using Predicate = std::variant<TextEq, NumberCmp>;
struct Query { std::vector<Predicate> predicates; std::size_t limit = 256; };

std::string trim(std::string s) {
    const auto a = s.find_first_not_of(" \t\r\n");
    if (a == std::string::npos) return {};
    return s.substr(a, s.find_last_not_of(" \t\r\n") - a + 1);
}

std::vector<std::string> split(std::string_view s, std::string_view sep) {
    std::vector<std::string> out;
    for (std::size_t a = 0;;) {
        const auto b = s.find(sep, a);
        out.push_back(trim(std::string(s.substr(a, b == s.npos ? b : b - a))));
        if (b == s.npos) return out;
        a = b + sep.size();
    }
}

std::expected<Query, std::string> compile_dsl(std::string source) {
    Query query;
    static const std::regex top(R"(^SELECT\s+TOP\s+([0-9]+)\s+)", std::regex::icase);
    std::smatch top_match;
    if (std::regex_search(source, top_match, top)) {
        query.limit = std::stoull(top_match[1].str());
        source.replace(0, static_cast<std::size_t>(top_match[0].length()), "SELECT ");
    } else {
        static const std::regex malformed_top(R"(^SELECT\s+TOP\b)", std::regex::icase);
        if (std::regex_search(source, malformed_top))
            return std::unexpected("TOP requires a non-negative integer");
    }
    if (source.starts_with("SELECT FROM")) source.replace(6, 1, " * ");
    static const std::regex select(
        R"(^SELECT\s+(.+?)\s+FROM\s+PYRAMIDS(\s+WHERE\s+(.+))?$)",
        std::regex::icase);
    std::smatch m;
    if (!std::regex_match(source, m, select)) return std::unexpected("invalid SELECT");

    const std::string where = m[3].matched ? m[3].str() : "";
    static const std::regex predicate(
        R"(^([A-Za-z_]+)\s*(CONTAINS|>=|<=|!=|=|>|<)\s*(.+)$)",
        std::regex::icase);

    for (const auto& expression : split(where, " AND ")) {
        if (expression.empty()) continue;
        std::smatch p;
        if (!std::regex_match(expression, p, predicate))
            return std::unexpected("invalid predicate: " + expression);
        const Field* f = field(p[1].str());
        if (!f) return std::unexpected("unknown field: " + p[1].str());
        std::string op = p[2].str();
        std::ranges::transform(op, op.begin(), [](unsigned char c) {
            return static_cast<char>(std::toupper(c));
        });
        const std::string literal = trim(p[3].str());
        if (f->kind == Kind::text) {
            if (op != "=" && op != "!=" && op != "CONTAINS")
                return std::unexpected("invalid text operator");
            query.predicates.emplace_back(TextEq{f, op, literal});
        } else {
            if (op == "CONTAINS") return std::unexpected("numeric CONTAINS");
            try { query.predicates.emplace_back(NumberCmp{f, op, std::stod(literal)}); }
            catch (...) { return std::unexpected("invalid numeric literal"); }
        }
    }
    return query;
}

std::string specialize(const Query& q) {
    std::ostringstream out;
    out << "for (const Pyramid& record : pyramids) {\n    if (";
    if (q.predicates.empty()) out << "true";
    for (std::size_t i = 0; i < q.predicates.size(); ++i) {
        if (i) out << " && ";
        std::visit([&](const auto& p) {
            using P = std::decay_t<decltype(p)>;
            if constexpr (std::is_same_v<P, TextEq>)
                if (p.op == "CONTAINS")
                    out << "contains(record." << p.field->cpp
                        << ", " << p.value << ')';
                else
                    out << "record." << p.field->cpp << ' '
                        << (p.op == "=" ? "==" : p.op)
                        << ' ' << p.value;
            else {
                const std::string op = p.op == "=" ? "==" : p.op;
                out << "record." << p.field->cpp << ".has_value() && *record."
                    << p.field->cpp << ' ' << op << ' ' << p.value;
            }
        }, q.predicates[i]);
    }
    out << ") {\n        emit(record);\n        if (++count == "
        << q.limit << ") break;\n    }\n}\n";
    return out.str();
}

std::string render(std::string_view records, std::string_view loop) {
    return "#include <iostream>\n#include <optional>\n#include <string>\n#include <vector>\n\n"
           "struct Pyramid { std::string name, country; std::optional<int> built_year; "
           "std::optional<double> height_m; };\nconst std::vector<Pyramid> pyramids{\n" +
           std::string(records) + "};\n"
           "bool contains(const std::string& a, const std::string& b) { return a.find(b) != std::string::npos; }\n"
           "void emit(const Pyramid& r) { std::cout << r.name << '\\n'; }\n"
           "int main() { std::size_t count = 0;\n" + std::string(loop) + "}\n";
}

std::string cpp_quote(std::string_view value) {
    std::string out = "\"";
    for (char c : value) {
        if (c == '\\' || c == '"') out.push_back('\\');
        out.push_back(c);
    }
    return out + "\"";
}

std::string read_records(const char* path) {
    std::ifstream input(path);
    if (!input) throw std::runtime_error("cannot open records file");

    std::ostringstream output;
    std::string line;
    while (std::getline(input, line)) {
        if (line.empty()) continue;
        const auto parts = split(line, "|");
        if (parts.size() != 4) throw std::runtime_error(
            "records must be NAME|COUNTRY|BUILT_YEAR|HEIGHT_M");
        output << "    Pyramid{" << cpp_quote(parts[0]) << ", "
               << cpp_quote(parts[1]) << ", " << parts[2] << ", "
               << parts[3] << "},\n";
    }
    return output.str();
}

int main(int argc, char** argv) {
    const std::string sql = argc > 1 ? argv[1]
        : "SELECT TOP 4 FROM PYRAMIDS WHERE BUILT_YEAR=-2560";
    const auto query = compile_dsl(sql);
    if (!query) { std::cerr << query.error() << '\n'; return 1; }
    const std::string records = argc > 2
        ? read_records(argv[2])
        : "    Pyramid{\"Great Pyramid of Giza\", \"Egypt\", -2560, 146.6},\n"
          "    Pyramid{\"Pyramid of Khafre\", \"Egypt\", -2570, 136.4},\n";
    std::cout << render(records, specialize(*query));
}
