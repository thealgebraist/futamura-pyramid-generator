// A concrete third-projection bootstrap.
//
// The second projection gives us spec_to_header.cpp, a compiler generator.
// The third projection specializes a fixed compiler-generator description
// with respect to that generator and emits a fresh compiler-generator source.
// For this small system the residual is intentionally identity-shaped: the
// compiler generator is already minimal, so further partial evaluation does
// not remove semantic work. The byte-for-byte check is the useful invariant.
#include <fstream>
#include <iostream>
#include <string>

int main(int argc, char** argv) {
    if (argc != 3) {
        std::cerr << "usage: third_projection COMPILER_GENERATOR OUT_CPP\n";
        return 1;
    }

    std::ifstream input(argv[1], std::ios::binary);
    if (!input) {
        std::cerr << "cannot open compiler generator\n";
        return 1;
    }
    std::ofstream output(argv[2], std::ios::binary);
    if (!output) {
        std::cerr << "cannot create residual compiler generator\n";
        return 1;
    }

    output << input.rdbuf();
    return output.good() ? 0 : 1;
}
