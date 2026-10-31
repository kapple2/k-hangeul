"""Run the real driver code in py65 on top of a memory snapshot taken at the ] prompt.

Sim(snapshot, driver_bin, labels_json)  load the snapshot, overlay a built driver image
call(addr, a, x, y)                     JSR to addr, return cycles used
cout(byte)                              the stock COUT entry ($EE63), the path BASIC PRINT takes
hgr()                                   the 8K hi-res page as bytes

py65 is not part of the project. Install with
  pip install --target <dir> py65
and point PY65 at <dir>.
"""
from __future__ import annotations

import json
import os
import sys
from pathlib import Path

sys.path.insert(0, os.environ.get("PY65", ""))
from py65.devices.mpu6502 import MPU  # noqa: E402

COPY0, DST = 0x6C, 0xD000
RET = 0x02F0
COUT = 0xEE63


class RoLC(bytearray):
    """RAM whose language-card range ($D000-$FFFF) ignores writes, as after the loader's $C080."""

    ignored = 0

    def __setitem__(self, key, value):
        if isinstance(key, int) and key >= 0xD000:
            RoLC.ignored += 1
            return
        super().__setitem__(key, value)


class Sim:
    def __init__(self, snapshot: Path, driver_bin: Path | None = None, labels: Path | None = None,
                 font_bin: Path | None = None):
        self.mem = bytearray(Path(snapshot).read_bytes())
        self.labels: dict[str, int] = {}
        if labels:
            raw = json.loads(Path(labels).read_text())
            used = raw.pop("_used", [])
            self.labels = raw
            if driver_bin:
                data = Path(driver_bin).read_bytes()
                n = max(used) - DST + 1
                self.mem[DST:DST + n] = data[COPY0:COPY0 + n]
        if font_bin:
            f = Path(font_bin).read_bytes()
            self.mem[0x0800:0x0800 + len(f)] = f
        self.mem = RoLC(self.mem)
        self.cpu = MPU(memory=self.mem)
        self.mem[RET] = 0xEA

    def reset_screen(self) -> None:
        for i in range(0x2000, 0x4000):
            self.mem[i] = 0

    def call(self, addr: int, a: int = 0, x: int = 0, y: int = 0, limit: int = 5_000_000) -> int:
        c = self.cpu
        c.a, c.x, c.y = a, x, y
        c.sp = 0xF0
        ret = RET - 1
        self.mem[0x100 + c.sp] = ret >> 8
        self.mem[0x100 + c.sp - 1] = ret & 0xFF
        c.sp -= 2
        c.pc = addr
        start = c.processorCycles
        while c.pc != RET:
            c.step()
            if c.processorCycles - start > limit:
                raise RuntimeError(f"call ${addr:04X} did not return (pc=${c.pc:04X})")
        return c.processorCycles - start

    def cout(self, ch: int) -> int:
        return self.call(COUT, a=ch)

    def hgr(self) -> bytes:
        return bytes(self.mem[0x2000:0x4000])


def profile_calls(sim: "Sim", fn) -> dict[int, int]:
    """Run fn() and return cycles spent at each instruction address."""
    cyc: dict[int, int] = {}
    cpu = sim.cpu
    orig = cpu.step

    def step():
        pc = cpu.pc
        before = cpu.processorCycles
        orig()
        cyc[pc] = cyc.get(pc, 0) + cpu.processorCycles - before
        return cpu

    cpu.step = step
    try:
        fn()
    finally:
        cpu.step = orig
    return cyc
