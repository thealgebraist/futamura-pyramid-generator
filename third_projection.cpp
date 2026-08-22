// Real third-stage partial evaluation.
// A fixed language specification is consumed now, producing a compiler
// source that emits the fixed schema without reading a spec at runtime.
#include <fstream>
#include <iostream>
#include <sstream>
#include <string>
#include <vector>

struct Entry { std::string name, kind, member; };

std::vector<Entry> read_spec(const char* path) {
    std::ifstream input(path);
    if (!input) throw std::runtime_error("cannot open language spec");
    std::vector<Entry> entries;
    std::string name, kind, member, rest;
    while (input >> name) {
        if (name.starts_with('#')) { std::getline(input, rest); continue; }
        if (!(input >> kind >> member) || (kind != "text" && kind != "number"))
            throw std::runtime_error("invalid language specification");
        entries.push_back({name, kind, member});
    }
    return entries;
}

std::string quote(const std::string& value) {
    std::string result = "\\\"";
    for (char c : value) {
        if (c == '\\' || c == '"') result.push_back('\\');
        result.push_back(c);
    }
    return result + "\\\"";
}

std::string residual_compiler(const std::vector<Entry>& entries) {
    std::ostringstream out;
    out << "#include <iostream>\n\n"
           "int main() {\n"
           "    std::cout << \"#pragma once\\n\"\n"
           "                 << \"#include <string_view>\\n\\n\"\n"
           "                 << \"enum class Kind { text, number };\\n\"\n"
           "                 << \"struct Field { std::string_view sql, cpp; Kind kind; };\\n\"\n"
           "                 << \"constexpr Field schema[] = {\\n\"\n";
    for (const Entry& entry : entries) {
        out << "                 << \"    {"
            << quote(entry.name) << ", " << quote(entry.member)
            << ", Kind::" << entry.kind << "},\\n\"\n";
    }
    out << "                 << \"};\\n\";\n"
           "    return 0;\n"
           "}\n";
    return out.str();
}

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "usage: third_projection LANGUAGE.spec OUT_CPP\n";
        return 1;
    }
    try {
        std::ofstream output(argv[2]);
        if (!output) throw std::runtime_error("cannot create residual compiler");
        output << residual_compiler(read_spec(argv[1]));
        return output.good() ? 0 : 1;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
