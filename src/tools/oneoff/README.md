# oneoff: one-time edit scripts

Each script was run once to change `driver.s` or `font.json`. They are kept as a record of those changes. The sources are now the real code, so do not run these again: they would change the sources a second time.

- `apply_round2.py`: the banner text and sizes (set by symbol), the HAN entry, the state fill and the K-HANGEUL name in `driver.s`.
- `apply_round3.py`: the English font as a file (`FONT6X10`), loaded into the language card at start-up.
- `relocate_state.py`: points the text-page variables used by the stock code at `$F430-$FD68` at the driver's own state. Usage: `relocate_state.py <driver.s> <defs.inc>`.
- `ascii_from_galmuri.py`: puts the GalmuriMono9 font into `font.json` as the English glyphs. Usage: `ascii_from_galmuri.py <font.json> <GalmuriMono9.bdf>`.
