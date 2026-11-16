# legacy

- `nprint.s`, `nprint.cfg`: NPRINT, the 79-byte `CALL 768` / `USR` printer for text already in memory. TYPE replaced it on the disk; kept as the smallest version. Assemble with `ca65 -t none nprint.s` and `ld65 -C nprint.cfg`.
- `build_driver.py` (in the project's local folder `work/squeezed12/`, not in this repository) made `NEWHANGEUL.bin` from the stock Hangeul2 image by byte-signature patches. It is no longer the build (it refuses to run without `NEWHANGEUL_LEGACY=1`): `../driver/driver.s` is the source now. It stays as a record of what each change to the stock code was.
