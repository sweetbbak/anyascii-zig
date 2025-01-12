#include <stddef.h>
#include <stdint.h>
#define ZIG_ANYASCII_H

// convert a UTF-8 codepoint into an ascii string and copy the bytes into
// the given string
size_t anyascii(uint32_t utf32, char* str);
/// takes a Unicode string and a mutable string that the resulting ascii values
/// are written into
size_t anyascii_string(char* input, char* output);
