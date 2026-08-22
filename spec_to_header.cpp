// Second Futamura projection for the small pyramid DSL.
// A fixed language interpreter (this program) specialized by a language
// specification emits the schema header consumed by the first-stage compiler.
#include <fstream>
#include <iostream>
#include <string>
#include <string_view>

int main(int argc, char** argv) {
    if (argc != 2) {
        std::cerr << "usage: spec_to_header LANGUAGE.spec\n";
        return 1;
    }
    std::ifstream input(argv[1]);
    if (!input) { std::cerr << "cannot open language spec\n"; return 1; }

    std::cout << "#pragma once\n#include <string_view>\n\n"
                 "enum class Kind { text, number };\n"
                 "struct Field { std::string_view sql, cpp; Kind kind; };\n"
                 "constexpr Field schema[] = {\n";

    std::string comment, name, kind, member;
    while (input >> name) {
        if (name.starts_with('#')) { std::getline(input, comment); continue; }
        if (!(input >> kind >> member) || (kind != "text" && kind != "number")) {
            std::cerr << "invalid language specification\n";
            return 1;
        }
        std::cout << "    {\"" << name << "\", \"" << member << "\", Kind::"
                  << kind << "},\n";
    }
    std::cout << "};\n";
}
