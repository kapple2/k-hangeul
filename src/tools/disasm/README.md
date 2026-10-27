# disasm: 디스어셈블리 도구


이 폴더의 세 파일(`opcodes.py`, `analyze.py`, `disasm.py`)은 옛 한글2 드라이버 이미지(`HANGEUL.bin`)를 어셈블리 소스로 풀던 도구입니다. 그 결과가 `src/driver/driver.s`입니다. 지금은 `driver.s`가 원본이므로, 이 도구는 **만드는 과정을 보여 주는 기록**입니다.


### 왜 바로 실행할 수 없나

- 입력으로 옛 한글2 이미지(`HANGEUL.bin`)와 그 목록(`HANGEUL.lst`)이 필요합니다. 둘 다 한글2 원본에서 온 것이라 이 저장소에 넣지 않았습니다.
- `analyze.py`와 `disasm.py`는 원래 개발 폴더의 경로(`work/hangeul2/`)를 찾습니다. 그 파일을 같은 위치에 두어야 합니다.


### 다른 파일을 풀어 보고 싶을 때

아무 6502 프로그램이나 풀어 보려면 cc65에 들어 있는 `da65`를 쓰세요. 이 저장소의 빌드가 쓰는 cc65 폴더에 있습니다.

```
rem K-HANGEUL 드라이버 본체를 $0F94에서 풀기
"D:\opt\devtools\asm\cc65\bin\da65.exe" --start-addr 0x0F94 DIST\bin\K-HANGEUL.bin

rem 옆의 파일 TYPE.bin을 $8E00에서 풀기, 결과를 파일로
"D:\opt\devtools\asm\cc65\bin\da65.exe" --start-addr 0x8E00 DIST\bin\TYPE.bin > type_listing.s
```

`da65`는 데이터와 코드를 자동으로 구별하지 못하므로, 결과에서 글자나 표가 이상하게 보이면 `.byte`로 된 부분을 직접 고치세요. 드라이버 소스(`driver.s`)에서 이름을 붙인 방식(`L_xxxx`, `D_xxxx`, `S_xxxx`)을 따르면 읽기 쉽습니다. 이름의 뜻은 `src/README.md`의 "Notes for the driver"에 있습니다.


### 파일 설명

| 파일 | 하는 일 |
|---|---|
| `opcodes.py` | 6502 명령 표: 명령 길이와 이름 |
| `analyze.py` | 실행되는 코드와 데이터를 찾아 나눕니다 |
| `disasm.py` | 나눈 결과를 ca65 소스로 씁니다 |


---


# disasm: disassembly tools


The three files in this folder (`opcodes.py`, `analyze.py`, `disasm.py`) are the tools that turned the old Hangeul2 driver image (`HANGEUL.bin`) into an assembly source. That source is `src/driver/driver.s`. The source is now the real code, so these tools are **a record of how it was made**.


### Why they cannot run as they are

- They need the old Hangeul2 image (`HANGEUL.bin`) and its listing (`HANGEUL.lst`) as input. Both come from the original Hangeul2 program, so they are not in this repository.
- `analyze.py` and `disasm.py` look for files in the development folder (`work/hangeul2/`). Those files would have to be in the same place.


### To disassemble another program

For any 6502 program, use `da65`, which comes with cc65 (the same folder the build uses):

```
rem the K-HANGEUL driver, loaded at $0F94
"D:\opt\devtools\asm\cc65\bin\da65.exe" --start-addr 0x0F94 DIST\bin\K-HANGEUL.bin

rem TYPE, loaded at $8E00, listing written to a file
"D:\opt\devtools\asm\cc65\bin\da65.exe" --start-addr 0x8E00 DIST\bin\TYPE.bin > type_listing.s
```

`da65` cannot always tell code from data, so check any part that comes out as `.byte` or as nonsense, and fix it by hand. Name labels the way `driver.s` does (`L_xxxx` for unnamed code, `D_xxxx` for unnamed data, `S_xxxx` for state bytes) and the listing is easier to read. The naming rules are in `src/README.md`, "Notes for the driver".


### The files

| file | what it does |
|---|---|
| `opcodes.py` | the 6502 opcode table: instruction names and lengths |
| `analyze.py` | finds which bytes are code and which are data |
| `disasm.py` | writes the split result as ca65 source |
