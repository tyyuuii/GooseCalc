// calc_history.goose — ring buffer + text persistence. Stores full expression strings.

import calc_bridge;

const HISTORY_CAPACITY: i32 = 32;

struct HistoryEntry {
    text: u8[128],  // full expression like "10 + 10 = 20"
    ok: bool,
}

struct History {
    entries: HistoryEntry[32],
    count: i32,
    head: i32,
}

fn new_history() -> History {
    return History {
        entries: [HistoryEntry { text: [0; 128], ok: false }; 32],
        count: 0, head: 0,
    };
}

fn history_push(h: History&, text: u8[>..], ok: bool) {
    let idx = (h.head + h.count) % 32;
    // Copy text into fixed buffer
    var i = 0;
    while i < text.len && text[i] != 0 && i < 127 {
        h.entries[idx].text[i] = text[i];
        i += 1;
    }
    h.entries[idx].text[i] = 0;
    h.entries[idx].ok = ok;
    if h.count < 32 { h.count += 1; }
    else { h.head = (h.head + 1) % 32; }
}

fn hist_path() -> u8[256] {
    var buf: u8[256] = [0; 256];
    let dir = data_path();
    let suffix = "/history.txt";
    let total = dir.len + suffix.len;
    if total >= 255 { return buf; }
    for i in 0..dir.len { buf[i] = dir[i]; }
    for i in 0..suffix.len { buf[dir.len + i] = suffix[i]; }
    return buf;
}

fn history_save(h: const History&) -> bool {
    // Disabled for now - os module not available
    return true;
}

fn history_load() -> History {
    return new_history();
}