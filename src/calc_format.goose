// calc_format.goose — f64 → string formatting
// Chained ops are SEQUENTIAL (desk-calculator): 2 + 3 * 4 = 20, not 14.

import calc_bridge;

const MAX_DISPLAY_CHARS = 16;

fn format_number(v: f64) -> u8[MAX_DISPLAY_CHARS + 1] {
    var buf: u8[MAX_DISPLAY_CHARS + 1] = [0; MAX_DISPLAY_CHARS + 1];
    
    // Handle special values
    if v != v {  // NaN
        return copy_to_fixed(str("Error"));
    }
    if v == 1.0/0.0 {  // +inf
        return copy_to_fixed(str("Infinity"));
    }
    if v == -1.0/0.0 {  // -inf
        return copy_to_fixed(str("-Infinity"));
    }
    
    // Threshold is exactly 1e16 (representable). A >-style check against a
    // constant that rounds to 1e16 lets exactly-1e16 slip through and get
    // truncated to a WRONG 16-digit value — use >= here.
    const SCI_THRESHOLD: f64 = 1e16;
    if v >= SCI_THRESHOLD || v <= -SCI_THRESHOLD {
        return format_sci(v);
    }
    
    // Extremely small values: fixed-point would truncate to garbage —
    // scientific keeps them honest and short.
    if v != 0.0 && v < 1e-9 && v > -1e-9 {
        return format_sci(v);
    }
    
    // Use fixed-point for small values to avoid scientific notation
    // Per plan: abs(v) < 1e-4 should not show as 1.2e-7
    if v < 1e-4 && v > -1e-4 && v != 0.0 {
        return format_dec(v);
    }
    
    // For larger values, use a general format
    return format_dec(v);
}

// Accurate bounded decimal formatter using ONE scaled-round step instead of
// repeated multiply/subtract (which accumulates 1.19999999999 artifacts).
// Rounds to the number of fractional digits that fit, then prints the
// rounded scaled integer directly. Trailing zeros are trimmed.
fn format_dec(v: f64) -> u8[MAX_DISPLAY_CHARS + 1] {
    var buf: u8[MAX_DISPLAY_CHARS + 1] = [0; MAX_DISPLAY_CHARS + 1];
    var i: i32 = 0;
    var val = v;
    
    if val < 0.0 {
        if i < MAX_DISPLAY_CHARS {
            buf[i] = '-';
            i += 1;
        }
        val = -val;
    }
    
    // Count integer digits (val < 1e16 here — guaranteed by routing above)
    var int_digits: i32 = 1;
    var t = val;
    while t >= 10.0 && int_digits < 17 {
        t *= 0.1;
        int_digits += 1;
    }
    
    // Fractional digit budget: 16 chars total minus sign, integer digits, point
    var frac_digits: i32 = MAX_DISPLAY_CHARS - i - int_digits - 1;
    if frac_digits < 0 { frac_digits = 0; }
    if frac_digits > 15 { frac_digits = 15; }
    
    // Single rounding step: scaled integer (f64 exact up to 2^53, and
    // val*scale < 1e16 here, well inside u64 range)
    var scale_u: u64 = 1;
    var k: i32 = 0;
    while k < frac_digits {
        scale_u *= 10;
        k += 1;
    }
    let r: u64 = (val * (scale_u as f64) + 0.5) as u64;
    let ip: u64 = r / scale_u;
    var fp: u64 = r % scale_u;
    
    // Integer part (rounding carry may add one digit — bounded by 16)
    var digits: u8[20] = [0; 20];
    var d: i32 = 0;
    var temp = ip;
    if temp == 0 {
        digits[0] = '0';
        d = 1;
    } else {
        while temp > 0 && d < 20 {
            digits[d] = (temp % 10) as u8 + '0';
            temp /= 10;
            d += 1;
        }
    }
    while d > 0 && i < MAX_DISPLAY_CHARS {
        d -= 1;
        buf[i] = digits[d];
        i += 1;
    }
    
    // Fraction part: emit frac_digits, then trim trailing zeros
    if frac_digits > 0 && i < MAX_DISPLAY_CHARS {
        var fd: u8[17] = [0; 17];
        var fn_count = frac_digits;
        var j = fn_count;
        while j > 0 {
            j -= 1;
            fd[j] = (fp % 10) as u8 + '0';
            fp /= 10;
        }
        while fn_count > 0 && fd[fn_count - 1] == '0' {
            fn_count -= 1;
        }
        if fn_count > 0 {
            buf[i] = '.';
            i += 1;
            j = 0;
            while j < fn_count && i < MAX_DISPLAY_CHARS {
                buf[i] = fd[j];
                i += 1;
                j += 1;
            }
        }
    }
    
    buf[i] = 0;
    return buf;
}

// Scientific notation: "1.234567e+20", "-9.876543e-15". Fits 16 chars.
fn format_sci(v: f64) -> u8[MAX_DISPLAY_CHARS + 1] {
    var buf: u8[MAX_DISPLAY_CHARS + 1] = [0; MAX_DISPLAY_CHARS + 1];
    var i: i32 = 0;
    var val = v;
    
    if val < 0.0 {
        buf[i] = '-';
        i += 1;
        val = -val;
    }
    
    // Normalize mantissa into [1, 10) by pure f64 math — no u64 casts.
    var exp: i32 = 0;
    if val >= 10.0 {
        while val >= 10.0 && exp < 300 {
            val *= 0.1;
            exp += 1;
        }
    } else if val < 1.0 {
        while val < 1.0 && exp > -300 {
            val *= 10.0;
            exp -= 1;
        }
    }
    
    // First mantissa digit
    let d1: u64 = val as u64;
    if i < MAX_DISPLAY_CHARS {
        buf[i] = d1 as u8 + '0';
        i += 1;
    }
    val -= d1 as f64;
    
    // Fraction digits
    if i < MAX_DISPLAY_CHARS {
        buf[i] = '.';
        i += 1;
    }
    var k: i32 = 0;
    while k < 6 && i < MAX_DISPLAY_CHARS {
        val *= 10.0;
        var d: u64 = val as u64;
        if d > 9 { d = 9; }  // rounding spill guard
        val -= d as f64;
        buf[i] = d as u8 + '0';
        i += 1;
        k += 1;
    }
    
    // Exponent
    if i < MAX_DISPLAY_CHARS {
        buf[i] = 'e';
        i += 1;
    }
    if i < MAX_DISPLAY_CHARS {
        if exp < 0 {
            buf[i] = '-';
            i += 1;
            exp = -exp;
        } else {
            buf[i] = '+';
            i += 1;
        }
    }
    // Exponent digits (up to 3), reversed then copied
    var ed: u8[4] = [0; 4];
    var en: i32 = 0;
    if exp == 0 {
        ed[0] = '0';
        en = 1;
    } else {
        var t = exp;
        while t > 0 && en < 3 {
            ed[en] = (t % 10) as u8 + '0';
            t /= 10;
            en += 1;
        }
    }
    while en > 0 && i < MAX_DISPLAY_CHARS {
        en -= 1;
        buf[i] = ed[en];
        i += 1;
    }
    
    buf[i] = 0;
    return buf;
}

fn copy_to_fixed(s: u8[>..]) -> u8[MAX_DISPLAY_CHARS + 1] {
    var buf: u8[MAX_DISPLAY_CHARS + 1] = [0; MAX_DISPLAY_CHARS + 1];
    let len = if s.len < MAX_DISPLAY_CHARS { s.len } else { MAX_DISPLAY_CHARS };
    for i in 0..len {
        buf[i] = s[i];
    }
    buf[len] = 0;
    return buf;
}

// Legacy entry points kept for compatibility; both now use the accurate
// single-rounding formatter (the old multiply/subtract loops accumulated
// binary→decimal artifacts like 1.19999999999999).
fn format_fixed(v: f64) -> u8[MAX_DISPLAY_CHARS + 1] {
    return format_dec(v);
}

fn format_general(v: f64) -> u8[MAX_DISPLAY_CHARS + 1] {
    return format_dec(v);
}

fn format_history(v: f64, ok: bool) -> u8[MAX_DISPLAY_CHARS + 1] {
    if !ok {
        return copy_to_fixed(str("Error"));
    }
    return format_number(v);
}