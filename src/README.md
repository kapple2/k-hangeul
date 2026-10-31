# src: 소스 코드


## 폴더별 설명

| 폴더 / 파일 | 무엇인가 | 결과물 |
|---|---|---|
| `driver/` | K-HANGEUL 한글 드라이버. `driver.s`(본체), `defs.inc`(이름 정의), `driver.cfg`(링크 설정), `build.bat` / `Makefile`(빌드), `fontgen.py`(`font.json`을 글꼴 파일로 바꿈), `hello.bas`(디스크 부팅 프로그램 `HELLO`), `demo.bas`(예제 `DEMO`), `../docs/MEMORY_LAYOUT.md`(메모리 배치), `../docs/DOS_PATCHES.md`(DOS에 하는 패치) | `build/K-HANGEUL.bin`, `build/FONT12.bin`, `build/FONT6X10.bin` |
| `type/` | `&TYPE` 명령. `type.s`, `core.inc`(파일 읽기 코드, `typec`과 `stype`도 씀), `../docs/TYPE.md`, 예제 `typedemo.bas`, `storyt.bas`, `sampleb.bin` | `build/TYPE.bin` |
| `typec/` | `TYPEC`. `&` 명령 없이 `]` 프롬프트에서 파일을 찍는 프로그램 | `build/TYPEC.bin` |
| `stype/` | `&STYPE` 명령(픽셀 줄이 펼쳐지는 효과). `stype.s`, `score.inc`(줄 그리기 루틴, `stypec`도 씀), `../docs/STYPE.md`, 예제 `stypedemo.bas`, `storys.bas` | `build/STYPE.bin` |
| `stypec/` | `STYPEC`. `STYPE` 효과를 파일 이름을 물어보는 프로그램으로 만든 것 | `build/STYPEC.bin` |
| `fonteditor/` | 글꼴 편집기. `editor.py`(편집기), `run_editor.bat`(실행), `font.json`(드라이버가 그리는 모든 글리프), `../docs/FONT_EDITOR.md` | 편집 결과는 `font.json`에 저장 |
| `samples/` | 디스크에 올라가는 예제 글. 「날개」 `NALGAE1`-`16`(N바이트 형식), `mixed.bas`, `story.bas`. `utf8txt/`는 같은 글의 UTF-8 사본(편집용). 자세한 설명은 `samples/README.md` | 디스크 파일 |
| `tools/` | `mkdist.py`(디스크와 `DIST` 만들기), `nbyte.py`(N바이트 ↔ UTF-8), `render/`(글꼴 그림), `disasm/`(옛 드라이버를 풀던 기록). 자세한 설명은 `tools/README.md` | `DIST\K-HANGEUL.DSK` 등(mkdist), 그 밖은 파일 |
| `make_all.bat` / `Makefile` | 모든 것을 한 번에 만듭니다. 다섯 프로그램을 빌드하고 `mkdist.py`를 실행합니다 | 아래 "빌드 결과" 참고 |
| `README.md`, `PYTHON.md` | 이 설명, Python 설정(패키지 목록 `requirements.txt`는 저장소 맨 위에 있음) | |


## 빌드하는 법

```
cd src
make_all.bat            빌드 전체 (GNU make가 있으면 make를 씀)
make_all.bat clean      빌드 폴더와 DIST를 지움 (저장소 맨 위의 clean.bat도 같은 일을 함)
```

각 프로그램 폴더에서는 `build.bat`(빌드만), `build.bat disk`(빌드 후 작업용 디스크에 복사), 또는 `make`(GNU make)로 따로 빌드할 수 있습니다. cc65 경로는 각 `build.bat`과 `Makefile` 위쪽에서 고치세요.


## 빌드 결과(최종 디스크는 어디에?)

`make_all.bat`은 마지막에 `tools/mkdist.py`를 실행하며, 이 파일은 **`src` 폴더의 바로 위 폴더**에 다음을 만듭니다.

- `DIST\K-HANGEUL.DSK`: 최종 사용자 디스크(DOS 3.3 + 드라이버 + 예제). `disk/dos33blank.dsk`를 복사한 뒤 파일을 넣습니다.
- `DIST\MANUAL.md`, `DIST\MANUAL_en.md`: 사용 설명서 (개발자용 문서는 `docs\`에 있고 `DIST`에 복사하지 않습니다)

`DIST`는 매번 새로 만들어집니다. 그래서 파일을 고치고 싶으면 `DIST`가 아니라 원본을 고치세요.


## 기타 파일

- `disk/NEWHANGEUL.DSK`(저장소에 없음): `build.bat disk`가 쓰는 작업용 디스크입니다. 없으면 `disk` 옵션은 실패하고, 일반 빌드는 괜찮습니다.

---


# src: source code


## What each folder holds

| folder / file | what it is | output |
|---|---|---|
| `driver/` | the K-HANGEUL Hangul driver: `driver.s` (the whole driver), `defs.inc` (names), `driver.cfg` (link layout), `build.bat` / `Makefile` (build), `fontgen.py` (turns `font.json` into the font files), `hello.bas` (the boot program `HELLO`), `demo.bas` (the example `DEMO`), `../docs/MEMORY_LAYOUT.md` (memory map), `../docs/DOS_PATCHES.md` (what is patched in DOS) | `build/K-HANGEUL.bin`, `build/FONT12.bin`, `build/FONT6X10.bin` |
| `type/` | the `&TYPE` command: `type.s`, `core.inc` (the file reader, also used by `typec` and `stype`), `../docs/TYPE.md`, examples `typedemo.bas`, `storyt.bas`, `sampleb.bin` | `build/TYPE.bin` |
| `typec/` | `TYPEC`: prints a file at the `]` prompt, without the `&` command | `build/TYPEC.bin` |
| `stype/` | the `&STYPE` command (rows unroll pixel by pixel): `stype.s`, `score.inc` (the row-drawing routines, also used by `stypec`), `../docs/STYPE.md`, examples `stypedemo.bas`, `storys.bas` | `build/STYPE.bin` |
| `stypec/` | `STYPEC`: the `STYPE` effect as a program that asks for a file name | `build/STYPEC.bin` |
| `fonteditor/` | the font editor: `editor.py`, `run_editor.bat` (starts it), `font.json` (every glyph the driver draws), `../docs/FONT_EDITOR.md` | edits are saved in `font.json` |
| `samples/` | the sample text that goes on the disk: the story `NALGAE1`-`16` (N-byte format), `mixed.bas`, `story.bas`. `utf8txt/` holds UTF-8 copies for editing. See `samples/README.md` | disk files |
| `tools/` | `mkdist.py` (makes the disk and `DIST`), `nbyte.py` (N-byte ↔ UTF-8), `render/` (font pictures), `disasm/` (record of how the old driver was taken apart). See `tools/README.md` | `DIST\K-HANGEUL.DSK` and others (mkdist); files otherwise |
| `make_all.bat` / `Makefile` | builds everything: the five programs, then runs `mkdist.py` | see "Where the final disk is" |
| `README.md`, `PYTHON.md` | this file and the Python setup (the package list, `requirements.txt`, is at the top of the repository) | |


## How to build

```
cd src
make_all.bat            build everything (uses make if it is installed)
make_all.bat clean      remove the build folders and DIST (clean.bat at the top of the repository does the same)
```

In each program folder you can also build alone: `build.bat` (build only), `build.bat disk` (build, then copy to the working disk), or `make` (GNU make). Set the cc65 path at the top of each `build.bat` and `Makefile`.


## Where the final disk is

At the end, `make_all.bat` runs `tools/mkdist.py`, which writes into the folder **above `src`**:

- `DIST\K-HANGEUL.DSK`: the final user disk (DOS 3.3, the driver and the examples). It starts from `disk/dos33blank.dsk` and adds the files.
- `DIST\MANUAL.md`, `DIST\MANUAL_en.md`: the user manual (the developer documents stay in `docs\` and are not copied to `DIST`).

`DIST` is rebuilt every time, so change the originals, not `DIST`.


## Other files

- `disk/NEWHANGEUL.DSK` (not in the repository): the working disk used by `build.bat disk`. Without it, only the `disk` option fails; the normal build works.
