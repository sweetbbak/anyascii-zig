# anyascii-zig

a Zig port of the `anyascii` C implementation.

Converts Unicode characters to their best ASCII representation
AnyAscii provides ASCII-only replacement strings for practically all Unicode characters. Text is converted character-by-character without considering the context. The mappings for each script are based on popular existing romanization systems. Symbolic characters are converted based on their meaning or appearance. All ASCII characters in the input are left unchanged, every other character is replaced with printable ASCII characters. Unknown characters and some known characters are replaced with an empty string and removed.

| Symbols    | Input     | Output                |
| ---------- | --------- | --------------------- |
| Emojis     | 👑 🌴     | `:crown: :palm_tree:` |
| Misc.      | ☆ ♯ ♰ ⚄ ⛌ | \* # + 5 X            |
| Letterlike | № ℳ ⅋ ⅍   | No M & A/S            |

This project uses `Zig mach` (0.14.0-dev.2577+271452d22)
but it is also compatible with:

- `Zig 0.13.0`
- `Zig master` (as of 1/11/25)

# Use in your project

```bash
# or pick a specific branch or commit
zig fetch --save https://github.com/sweetbbak/anyascii-zig/archive/refs/heads/main.zip
```

in `build.zig`:

```zig
// Add anyascii.zig dependency.
const anyascii = b.dependency("anyascii-zig", .{
    .target = target,
    .optimize = optimize,
});
exe.root_module.addImport("anyascii", anyascii.module("anyascii"));
```

# Using the C library

build the shared library and the static library

```bash
zig build -Doptimize=ReleaseFast
```

install the given header file at `include/anyascii.h` and the shared object (or static object) to your prefered location

```c
#include "../include/anyascii.h"

#include <stdio.h>
#include <stdlib.h>

static char* actual;

int main() {
    actual = malloc(256);
    anyascii(0xD55C, actual); // 한
    printf("anyascii: %s\n", actual);  // Han (Korean)

    char* output = malloc(256);
    anyascii_string("René François Lacôte", output);

    printf("anyascii_string: %s\n", output);
}

```

you can try out the simple example in the `example` directory:

```bash
zig build -Doptimize=ReleaseFast

gcc -o ascii example/anyascii.c \
    -Wall -Wextra -Werror -Os -fPIE \
    -I./include -L zig-out/lib \
    -l:libanyascii.a -lc

./ascii
```

# Examples

| input                     | got                         |
| ------------------------- | --------------------------- |
| 'René François Lacôte'    | 'Rene Francois Lacote'      |
| 'Blöße'                   | 'Blosse'                    |
| 'Trần Hưng Đạo'           | 'Tran Hung Dao'             |
| 'Nærøy'                   | 'Naeroy'                    |
| 'Φειδιππίδης'             | 'Feidippidis'               |
| 'Δημήτρης Φωτόπουλος'     | 'Dimitris Fotopoylos'       |
| 'Борис Николаевич Ельцин' | 'Boris Nikolaevich El'tsin' |
| 'Володимир Горбулін'      | 'Volodimir Gorbulin'        |
| 'Търговище'               | 'T'rgovishche'              |
| '深圳'                    | 'ShenZhen'                  |
| '深水埗'                  | 'ShenShuiBu'                |
| '화성시'                  | 'HwaSeongSi'                |
| '華城市'                  | 'HuaChengShi'               |
| 'さいたま'                | 'saitama'                   |
| '埼玉県'                  | 'QiYuXian'                  |
| 'ደብረ ዘይት'                 | 'debre zeyt'                |
| 'ደቀምሓረ'                   | 'dek'emhare'                |
| 'دمنهور'                  | 'dmnhwr'                    |
| 'Աբովյան'                 | 'Abovyan'                   |
| 'სამტრედია'               | 'samt'redia'                |
| 'אברהם הלוי פרנקל'        | ''vrhm hlvy frnkl'          |
| '⠠⠎⠁⠽⠀⠭⠀⠁⠛'               | '+say x ag'                 |
| 'ময়মনসিংহ'                | 'mymnsimh'                  |
| 'ထန်တလန်'                 | 'thntln'                    |
| 'પોરબંદર'                 | 'porbmdr'                   |

# links

upstream anyascii that this project is ported from:
[anyascii](https://github.com/anyascii/anyascii)

used this project for reference:
[anyascii/go](https://github.com/anyascii/go)

learned about anyascii and got the idea from here:
[zigzedd/anyascii.zig](https://github.com/zigzedd/anyascii.zig)
