"""Documented NMOS 6502 opcodes for the disassembler: op -> (mnemonic, mode, length)."""
from __future__ import annotations

LEN = {"imp": 1, "acc": 1, "imm": 2, "zp": 2, "zpx": 2, "zpy": 2, "abs": 3, "abx": 3, "aby": 3,
       "ind": 3, "izx": 2, "izy": 2, "rel": 2}

OPS: dict[int, tuple[str, str]] = {}


def _add(op: int, mn: str, mode: str) -> None:
    OPS[op] = (mn, mode)


G1 = ["ORA", "AND", "EOR", "ADC", "STA", "LDA", "CMP", "SBC"]
M1 = ["izx", "zp", "imm", "abs", "izy", "zpx", "aby", "abx"]
for i, mn in enumerate(G1):
    for b, mode in enumerate(M1):
        if mn == "STA" and mode == "imm":
            continue
        _add(i * 0x20 + b * 4 + 1, mn, mode)

for i, mn in enumerate(["ASL", "ROL", "LSR", "ROR"]):
    for b, mode in ((1, "zp"), (2, "acc"), (3, "abs"), (5, "zpx"), (7, "abx")):
        _add(i * 0x20 + b * 4 + 2, mn, mode)
for mn, base in (("DEC", 0xC2), ("INC", 0xE2)):
    for b, mode in ((1, "zp"), (3, "abs"), (5, "zpx"), (7, "abx")):
        _add(base + b * 4, mn, mode)
for b, mode in ((1, "zp"), (3, "abs"), (5, "zpy")):
    _add(0x82 + b * 4, "STX", mode)
for b, mode in ((0, "imm"), (1, "zp"), (3, "abs"), (5, "zpy"), (7, "aby")):
    _add(0xA2 + b * 4, "LDX", mode)
for b, mode in ((1, "zp"), (3, "abs"), (5, "zpx")):
    _add(0x80 + b * 4, "STY", mode)
for b, mode in ((0, "imm"), (1, "zp"), (3, "abs"), (5, "zpx"), (7, "abx")):
    _add(0xA0 + b * 4, "LDY", mode)
for mn, base in (("CPY", 0xC0), ("CPX", 0xE0)):
    for b, mode in ((0, "imm"), (1, "zp"), (3, "abs")):
        _add(base + b * 4, mn, mode)
_add(0x24, "BIT", "zp")
_add(0x2C, "BIT", "abs")
_add(0x4C, "JMP", "abs")
_add(0x6C, "JMP", "ind")
_add(0x20, "JSR", "abs")
for i, mn in enumerate(["BPL", "BMI", "BVC", "BVS", "BCC", "BCS", "BNE", "BEQ"]):
    _add(0x10 + i * 0x20, mn, "rel")
for op, mn in ((0x00, "BRK"), (0x40, "RTI"), (0x60, "RTS"), (0x08, "PHP"), (0x28, "PLP"), (0x48, "PHA"),
               (0x68, "PLA"), (0x88, "DEY"), (0xA8, "TAY"), (0xC8, "INY"), (0xE8, "INX"), (0x18, "CLC"),
               (0x38, "SEC"), (0x58, "CLI"), (0x78, "SEI"), (0x98, "TYA"), (0xB8, "CLV"), (0xD8, "CLD"),
               (0xF8, "SED"), (0x8A, "TXA"), (0x9A, "TXS"), (0xAA, "TAX"), (0xBA, "TSX"), (0xCA, "DEX"),
               (0xEA, "NOP")):
    _add(op, mn, "imp")
