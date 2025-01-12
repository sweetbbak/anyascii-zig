const std = @import("std");
const table = @import("table.zig");
const bank = table.bank;

fn _anyascii(utf32: u32) []const u8 {
    const blocknum = utf32 >> 8;
    const b = table.block(blocknum);
    const lo = (utf32 & 0xff) * 3;
    if (b.len <= lo) return "";

    const l = b[lo + 2];
    const len = if ((l & 0x80) == 0) 3 else l & 0x7f;

    if (len <= 3) {
        return b[lo .. lo + len];
    } else {
        // why u15-u32???
        const i = (@as(u32, @intCast(b[lo])) << 8) | (b[lo + 1]);
        return bank[i .. i + len];
    }

    return "";
}

inline fn copyForward(dest: [*]u8, src: [*]const u8, count: usize) [*]u8 {
    var i: usize = 0;
    while (i < count) : (i += 1) {
        dest[i] = src[i];
    }
    return dest;
}

/// convert a UTF-8 codepoint into an ascii string and copy the bytes into
/// the given string
pub export fn anyascii(utf32: u32, str: [*]u8) callconv(.C) c_ulong {
    // this is a slice, so it is not guaranteed to be null terminated
    const string: []const u8 = _anyascii(utf32);
    _ = copyForward(str, @ptrCast(string), string.len);
    return @intCast(string.len);
}

/// takes a Unicode string and a mutable string that the resulting ascii values
/// are written into
pub export fn anyascii_string(input: [*:0]u8, output: [*:0]u8) callconv(.C) c_ulong {
    const slice: []const u8 = std.mem.sliceTo(input, 0x00);
    var uni = std.unicode.Utf8View.init(slice) catch return 1;
    var iterator = uni.iterator();

    var written: usize = 0;
    while (iterator.nextCodepoint()) |codepoint| {
        const string: []const u8 = _anyascii(codepoint);
        @memcpy(output + written, string);
        written += string.len;
    }

    return written;
}

/// test a string for testing
fn check(input: []const u8, output: []const u8) !void {
    const alloc = std.testing.allocator;
    const actual = alloc.alloc(u8, 256) catch @panic("OOM");
    defer alloc.free(actual);

    const in = alloc.dupeZ(u8, input) catch @panic("OOM");
    defer alloc.free(in);

    const len = anyascii_string(in, @ptrCast(actual));
    std.debug.print("| '{s}' | '{s}' |\n", .{ input, actual[0..len] });

    if (!(std.mem.eql(u8, actual[0..len], output))) return error.NoMatch;
}

/// check a codepoint for testing
fn checkcp(utf32: u32, str: []const u8) !void {
    const alloc = std.testing.allocator;
    const buf = alloc.alloc(u8, 256) catch @panic("OOM");
    defer alloc.free(buf);

    const len = anyascii(utf32, @ptrCast(buf));
    std.debug.print("{s}\n", .{buf[0..len]});

    if (!(std.mem.eql(u8, buf[0..len], str))) return error.NoMatch;
}

test "anyascii codepoints and strings" {
    try check("sample", "sample");

    try checkcp(0x0080, "");
    try checkcp(0x00ff, "y");
    try checkcp(0xe000, "");
    try checkcp(0xffff, "");
    try checkcp(0x000e0020, " ");
    try checkcp(0x000e007e, "~");
    try checkcp(0x000f0000, "");
    try checkcp(0x000f0001, "");
    try checkcp(0x0010ffff, "");
    try checkcp(0x00110000, "");
    try checkcp(0x7fffffff, "");
    try checkcp(0x80000033, "");
    try checkcp(0xffffffff, "");

    std.debug.print("|input | got |\n", .{});
    std.debug.print("|------|-----|\n", .{});
    try check("René François Lacôte", "Rene Francois Lacote");
    try check("Blöße", "Blosse");
    try check("Trần Hưng Đạo", "Tran Hung Dao");
    try check("Nærøy", "Naeroy");
    try check("Φειδιππίδης", "Feidippidis");
    try check("Δημήτρης Φωτόπουλος", "Dimitris Fotopoylos");
    try check("Борис Николаевич Ельцин", "Boris Nikolaevich El'tsin");
    try check("Володимир Горбулін", "Volodimir Gorbulin");
    try check("Търговище", "T'rgovishche");
    try check("深圳", "ShenZhen");
    try check("深水埗", "ShenShuiBu");
    try check("화성시", "HwaSeongSi");
    try check("華城市", "HuaChengShi");
    try check("さいたま", "saitama");
    try check("埼玉県", "QiYuXian");
    try check("ደብረ ዘይት", "debre zeyt");
    try check("ደቀምሓረ", "dek'emhare");
    try check("دمنهور", "dmnhwr");
    try check("Աբովյան", "Abovyan");
    try check("სამტრედია", "samt'redia");
    try check("אברהם הלוי פרנקל", "'vrhm hlvy frnkl");
    try check("⠠⠎⠁⠽⠀⠭⠀⠁⠛", "+say x ag");
    try check("ময়মনসিংহ", "mymnsimh");
    try check("ထန်တလန်", "thntln");
    try check("પોરબંદર", "porbmdr");
    try check("महासमुंद", "mhasmumd");
    try check("ಬೆಂಗಳೂರು", "bemgluru");
    try check("សៀមរាប", "siemrab");
    try check("ສະຫວັນນະເຂດ", "sahvannaekhd");
    try check("കളമശ്ശേരി", "klmsseri");
    try check("ଗଜପତି", "gjpti");
    try check("ਜਲੰਧਰ", "jlmdhr");
    try check("රත්නපුර", "rtnpur");
    try check("கன்னியாகுமரி", "knniyakumri");
    try check("శ్రీకాకుళం", "srikakulm");
    try check("สงขลา", "sngkhla");
    try check("👑 🌴", ":crown: :palm_tree:");
    try check("☆ ♯ ♰ ⚄ ⛌", "* # + 5 X");
    try check("№ ℳ ⅋ ⅍", "No M & A/S");

    try check("トヨタ", "toyota");
    try check("ߞߐߣߊߞߙߌ߫", "konakri");
    try check("𐬰𐬀𐬭𐬀𐬚𐬎𐬱𐬙𐬭𐬀", "zarathushtra");
    try check("ⵜⵉⴼⵉⵏⴰⵖ", "tifinagh");
    try check("𐍅𐌿𐌻𐍆𐌹𐌻𐌰", "wulfila");
    try check("ދިވެހި", "dhivehi");
    try check("ᨅᨔ ᨕᨘᨁᨗ", "bs ugi");
    try check("ϯⲙⲓⲛϩⲱⲣ", "timinhor");
    try check("𐐜 𐐢𐐮𐐻𐑊 𐐝𐐻𐐪𐑉", "Dh Litl Star");
    try check("ꁌꐭꑤ", "pujjytxiep");
    try check("ⰳⰾⰰⰳⱁⰾⰹⱌⰰ", "glagolica");
    try check("ᏎᏉᏯ", "SeQuoYa");
    try check("ㄓㄨㄤ ㄅㄥ ㄒㄧㄠ", "zhuang beng xiao");
    try check("ꚩꚫꛑꚩꚳ ꚳ꛰ꛀꚧꚩꛂ", "ipareim m'shuoiya");
    try check("ᓀᐦᐃᔭᐍᐏᐣ", "nehiyawewin");
    try check("ᠤᠯᠠᠭᠠᠨᠴᠠᠪ", "ulaganqab");
    try check("𐑨𐑯𐑛𐑮𐑩𐑒𐑤𐑰𐑟 𐑯 𐑞 𐑤𐑲𐑩𐑯", "andr'kliiz n dh lai'n");
}
