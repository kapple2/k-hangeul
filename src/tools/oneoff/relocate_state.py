"""One-time repair: point the text-page variables used by the stock code at $F430-$FD68 at the driver's state.

The first relocation only covered $E3DA-$F42F. This finishes the job in driver.s: every instruction in
$F430-$FD68 whose operand is a text-page address ($0450-$07DD) now names the moved byte (S_xxxx).
usage: relocate_state.py <driver.s> <defs.inc>
"""
import re
import sys
from pathlib import Path

TP_SEGS = ((0x0450, 0x28, 0x00), (0x04D0, 0x28, 0x28), (0x0550, 0x28, 0x50), (0x05D0, 0x04, 0x78),
           (0x064F, 0x21, 0x7C), (0x06A8, 0x2C, 0x9D), (0x0728, 0xB6, 0xC9))
STATE = 0x9400
LO, HI = 0xF430, 0xFD68


def tp(a):
    for old, size, off in TP_SEGS:
        if old <= a < old + size:
            return STATE + off + a - old
    return None


src, defs = Path(sys.argv[1]), Path(sys.argv[2])
dtext = defs.read_text(encoding="utf-8")
names = {}
for m in re.finditer(r"^(\w+) = \$([0-9A-F]{4})\s*;\s*was \$([0-9A-F]{4})", dtext, re.M):
    names[int(m.group(3), 16)] = m.group(1)
new_defs = []
out = []
changed = 0
for line in src.read_text(encoding="utf-8").split("\n"):
    m = re.match(r"^(\s+)(\w+)\s+(.*?)\s*;\s*([0-9A-F]{4})\s{2}([0-9A-F]{2}) ([0-9A-F]{2}) ([0-9A-F]{2})\s*$", line)
    if m and LO <= int(m.group(4), 16) <= HI:
        ind, mn, op, addr, b0, b1, b2 = m.groups()
        target = int(b1, 16) | (int(b2, 16) << 8)
        new = tp(target)
        if new is not None and re.search(r"\$0[4-7][0-9A-F]{2}", op):
            name = names.get(target) or f"S_{target:04X}"
            if target not in names:
                names[target] = name
                new_defs.append(f"{name} = ${new:04X}            ; was ${target:04X} in the text page")
            op2 = re.sub(r"\$0[4-7][0-9A-F]{2}", name, op, count=1)
            line = f"{ind}{mn:4} {op2}".ljust(36) + f"; {addr}  {b0} {b1} {b2}"
            changed += 1
    out.append(line)
src.write_text("\n".join(out), encoding="utf-8")
if new_defs:
    defs.write_text(dtext.rstrip("\n") + "\n" + "\n".join(new_defs) + "\n", encoding="utf-8")
print("instructions changed:", changed, "new names:", len(new_defs))
