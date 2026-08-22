#pragma once
#include <string_view>

enum class Kind { text, number };
struct Field { std::string_view sql, cpp; Kind kind; };
constexpr Field schema[] = {
    {"NAME", "name", Kind::text},
    {"COUNTRY", "country", Kind::text},
    {"BUILT_YEAR", "built_year", Kind::number},
    {"HEIGHT_M", "height_m", Kind::number},
    {"SITELINKS", "sitelinks", Kind::number},
};
