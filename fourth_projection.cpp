// Fourth-stage self-application/bootstrap.
//
// Classical Futamura projections stop at three. This next stage is therefore
// a practical bootstrap: specialize the third-stage generator with the fixed
// language specification, producing a no-input program that emits the
// specialized compiler generator source.
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

std::string escape(std::string value) {
    std::string result;
    for (char c : value) {
        if (c == '\\' || c == '"') result.push_back('\\');
        if (c == '\n') { result += "\\n"; continue; }
        result.push_back(c);
    }
    return result;
}

std::string fixed_compiler_source(const std::vector<Entry>& entries) {
    std::ostringstream source;
    source << "#include <iostream>\nint main() {\n"
           << "    std::cout << \"#pragma once\\n\"\n"
           << "                 << \"#include <string_view>\\n\\n\"\n"
           << "                 << \"enum class Kind { text, number };\\n\"\n"
           << "                 << \"struct Field { std::string_view sql, cpp; Kind kind; };\\n\"\n"
           << "                 << \"constexpr Field schema[] = {\\n\"\n";
    for (const Entry& entry : entries)
        source << "                 << \"    {\\\"" << escape(entry.name)
               << "\\\", \\\"" << escape(entry.member) << "\\\", Kind::"
               << entry.kind << "},\\n\"\n";
    source << "                 << \"};\\n\";\n    return 0;\n}\n";
    return source.str();
}

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "usage: fourth_projection LANGUAGE.spec OUT_CPP\n";
        return 1;
    }
    try {
        std::ofstream output(argv[2]);
        if (!output) throw std::runtime_error("cannot create residual bootstrap");
        const std::string compiler = fixed_compiler_source(read_spec(argv[1]));
        output << "#include <iostream>\nint main() {\n"
               << "    std::cout << \"" << escape(compiler) << "\";\n"
               << "    return 0;\n}\n";
        return output.good() ? 0 : 1;
    } catch (const std::exception& error) {
        std::cerr << error.what() << '\n';
        return 1;
    }
}
