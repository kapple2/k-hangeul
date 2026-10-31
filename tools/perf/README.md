# perf: offline 6502 simulator and profiler

These tools run the real driver code in py65 (a Python 6502 emulator), so a driver change can be timed and compared without an emulator window. They are used for speed work and for checking that two driver builds draw exactly the same pixels.

| file | what it does |
|---|---|
| `sim6502.py` | the simulator: loads a memory snapshot taken at the `]` prompt, lays a built driver on top, and runs routines |
| `bench_sim.py` | cycle counts for the driver's draw paths |
| `diff_sim.py` | draws the same text with two driver builds and compares every hi-res byte |
| `prof_sim.py` | exact cycle profile by routine |
| `profile_report.py` | summarises a `pc.txt` sample file by routine |
| `hgr2png.py` | turns a dumped hi-res page into a PNG (needs Pillow) |

py65 is not part of the project: `pip install --target <dir> py65`, then set `PY65=<dir>`. A snapshot is a 64K memory dump from an emulator at the `]` prompt; it is not in the repository. Each script prints its usage in its first lines. Naming routines from the stock Hangeul2 is optional: set `HANGEUL_LST` (`prof_sim.py`) or give a third argument (`profile_report.py`) to a saved listing.

The scripts expect `labels.json` (routine name to address). `ld65` writes `build/driver.lbl` in the driver build; turn it into `labels.json` (`{"NAME": address, ...}`) before using these tools. The driver image is `build/K-HANGEUL.bin`.
