// this maybe wrong IDK lmao Im not a C programmer
// gcc -o ascii anyascii.c -Wall -Wextra -Werror -Os -fPIE -I. -L zig-out/lib -l:libanyascii.a -lc
#include "../include/anyascii.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static char* actual;

int main() {
    actual = malloc(256);
    anyascii(0x1f451, actual);
    printf("anyascii: %s\n", actual);  // Han (Korean)
    memset(actual, 0, 256);

    anyascii(0x0024, actual);
    printf("anyascii: %s\n", actual);  // Han (Korean)
    memset(actual, 0, 256);

    anyascii(0x00A2, actual);
    printf("anyascii: %s\n", actual);  // Han (Korean)
    memset(actual, 0, 256);

    anyascii(0xD55C, actual);
    printf("anyascii: %s\n", actual);  // Han (Korean)
    memset(actual, 0, 256);

    char* output = malloc(256);
    anyascii_string("René François Lacôte", output);

    printf("anyascii_string: %s\n", output);
}
