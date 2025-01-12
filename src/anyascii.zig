const std = @import("std");
const Allocator = std.mem.Allocator;
const table = @import("table.zig");
const bank = table.bank;

/// Convert a unicode codepoint to its ascii equivalent.
pub fn convert(utf32: u32) []const u8 {
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

/// transliterate a string into its ascii equivalent using a fixed size
/// buffer known at compile time
// pub fn anyascii_string(input: []const u8, comptime bufsize: usize) ![]const u8 {
pub fn transliterate(input: []const u8, writer: anytype) !usize {
    var uni = try std.unicode.Utf8View.init(input);
    var iterator = uni.iterator();

    var written: usize = 0;
    while (iterator.nextCodepoint()) |codepoint| {
        const string: []const u8 = convert(codepoint);
        const n = try writer.write(string);
        written += n;
    }

    return written;
}

/// convert a given UTF-8 string to its ASCII equivalent using anyascii
/// using an allocator
pub fn to_string(allocator: Allocator, str: []const u8) ![]u8 {
    // Get a UTF8 iterator.
    var iterator = (try std.unicode.Utf8View.init(str)).iterator();

    // Initialize a out string array list where ascii equivalents will be appended.
    var outStr = try std.ArrayList(u8).initCapacity(allocator, str.len | 15);
    defer outStr.deinit();

    // Get a writer to the array list.
    const writer = outStr.writer().any();

    // For each codepoint, convert it to ascii.
    while (iterator.nextCodepoint()) |codepoint| {
        const chars = convert(codepoint);
        _ = try writer.write(chars);
    }

    // Return the built full ascii equivalent.
    return outStr.toOwnedSlice();
}

/// Test the conversion of a given UTF-8 character to its ASCII equivalent.
fn check_alloc(input: []const u8, expected: []const u8) !void {
    const allocator = std.testing.allocator;
    const buf = try to_string(allocator, input);
    defer allocator.free(buf);
    try std.testing.expectEqualStrings(expected, buf);
}

/// Test the conversion of a given UTF-8 character to its ASCII equivalent.
fn check(input: []const u8, expected: []const u8) !void {
    var buf: [256]u8 = undefined;
    var fbs = std.io.fixedBufferStream(&buf);
    const writer = fbs.writer().any();

    const n = try transliterate(input, writer);
    try std.testing.expectEqualStrings(expected, buf[0..n]);
}

/// check a codepoint for testing
fn checkcp(utf32: u32, str: []const u8) !void {
    const output = convert(utf32);
    if (!(std.mem.eql(u8, output, str))) return error.NoMatch;
}

test "anyascii codepoints" {
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
}

test "anyascii strings allocated" {
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

test "anyascii strings" {
    try check_alloc("René François Lacôte", "Rene Francois Lacote");
    try check_alloc("Blöße", "Blosse");
    try check_alloc("Trần Hưng Đạo", "Tran Hung Dao");
    try check_alloc("Nærøy", "Naeroy");
    try check_alloc("Φειδιππίδης", "Feidippidis");
    try check_alloc("Δημήτρης Φωτόπουλος", "Dimitris Fotopoylos");
    try check_alloc("Борис Николаевич Ельцин", "Boris Nikolaevich El'tsin");
    try check_alloc("Володимир Горбулін", "Volodimir Gorbulin");
    try check_alloc("Търговище", "T'rgovishche");
    try check_alloc("深圳", "ShenZhen");
    try check_alloc("深水埗", "ShenShuiBu");
    try check_alloc("화성시", "HwaSeongSi");
    try check_alloc("華城市", "HuaChengShi");
    try check_alloc("さいたま", "saitama");
    try check_alloc("埼玉県", "QiYuXian");
    try check_alloc("ደብረ ዘይት", "debre zeyt");
    try check_alloc("ደቀምሓረ", "dek'emhare");
    try check_alloc("دمنهور", "dmnhwr");
    try check_alloc("Աբովյան", "Abovyan");
    try check_alloc("სამტრედია", "samt'redia");
}
