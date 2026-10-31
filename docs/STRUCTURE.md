# 저장소 구조


이 저장소는 K-HANGEUL 드라이버의 소스, 빌드 도구, 설명서를 담고 있습니다. 모든 소스는 `src/` 아래에 있고, 설명서는 `docs/`와 각 폴더에 있습니다.

```
README.md                     저장소 소개와 빌드 방법
BUILD.md, BUILD_en.md         빌드 방법을 단계별로 설명
build.bat                     한 번에 빌드해서 disk/K-HANGEUL.DSK를 만듦
clean.bat                     빌드 결과(build/, DIST/ 안의 내용)를 지움
requirements.txt              Python 패키지 목록
.gitignore                    빌드 결과와 가상 환경을 올리지 않게 하는 목록
docs/
  MANUAL.md                   사용 설명서 (한국어)
  MANUAL_en.md                사용 설명서 (English)
  STRUCTURE.md                이 문서
  TYPE.md, TYPE_en.md         &TYPE 명령
  TYPEC.md                    TYPEC (한국어/English 한 파일)
  STYPE.md, STYPE_en.md       &STYPE 명령
  STYPEC.md                   STYPEC (한국어/English 한 파일)
  MEMORY_LAYOUT.md, _en.md    메모리 배치
  DOS_PATCHES.md, _en.md      DOS에 하는 패치
  FONT_EDITOR.md              글꼴 편집기
disk/
  K-HANGEUL.DSK               완성된 사용자 디스크 (부팅용)
  dos33blank.dsk              사용자 디스크를 만드는 빈 DOS 3.3 디스크
src/
  make_all.bat, Makefile      전체 빌드
  README.md                   src 폴더 설명
  PYTHON.md                   Python 설정
  driver/                     드라이버 소스, 글꼴 만들기
  type/, typec/               &TYPE 명령과 TYPEC
  stype/, stypec/             &STYPE 명령과 STYPEC
  fonteditor/                 글꼴 편집기와 font.json
  samples/                    디스크의 예제 글 (N바이트)
    utf8txt/                  예제 글의 UTF-8 사본
  tools/                      도구 (mkdist.py, nbyte.py, render/, disasm/)
```


### 빌드 흐름

1. `src/driver/`, `src/type/`, `src/typec/`, `src/stype/`, `src/stypec/`의 `build.bat` 또는 `Makefile`이 각 프로그램을 어셈블합니다(cc65).
2. `src/driver/fontgen.py`가 `src/fonteditor/font.json`을 글꼴 파일로 바꿉니다.
3. `src/tools/mkdist.py`가 먼저 `src/samples/utf8txt/`에서 N바이트 예제 파일을 만들고, 프로그램과 예제 글을 `disk/dos33blank.dsk`의 사본에 넣어 `DIST\K-HANGEUL.DSK`를 만듭니다. 설명서도 `DIST\docs\`에 복사합니다.

`make_all.bat`은 1~3을 한 번에 합니다. 최종 디스크를 `disk/`에도 넣으려면 빌드 후 `DIST\K-HANGEUL.DSK`를 `disk\`로 복사하세요.


### 무엇을 고치면 되나

| 바꾸려는 것 | 고칠 곳 |
|---|---|
| 드라이버 동작 | `src/driver/driver.s`와 `defs.inc` |
| 글꼴 모양 | 글꼴 편집기(`src/fonteditor/run_editor.bat`)로 `font.json` |
| 예제 글 | `src/samples/utf8txt/`를 고친 뒤 `make_all.bat` (`src/samples/README.md`) |
| 디스크 목록 | `src/tools/mkdist.py` |
| 명령 동작 | `src/type/type.s`, `src/stype/stype.s`, `src/stype/score.inc` 등 |

`DIST/`, `build/`, `out/`, `.venv/`는 빌드나 실행의 결과이므로 고치지 않습니다. `.gitignore`에 들어 있습니다.


### 저장소에 없는 것

개발 중의 메모, 진행 기록, 예전 실험 폴더, 원본 한글2 파일, 그리고 한글2 원본에서 나온 이미지는 넣지 않았습니다. 디스어셈블리 도구는 들어 있지만 원본 이미지가 없어서 바로 실행할 수 없습니다(`src/tools/disasm/README.md`).


---


# Repository structure


This repository holds the source of the K-HANGEUL driver, its build tools and its documentation. All source is under `src/`. Documents are in `docs/` and in each folder.

```
README.md                     what the repository is and how to build it
BUILD.md, BUILD_en.md         step-by-step build guide
build.bat                     builds everything and writes disk/K-HANGEUL.DSK
clean.bat                     removes the build output (build/ folders, the contents of DIST/)
requirements.txt              Python package list
.gitignore                    keeps build output and the virtual environment out of git
docs/
  MANUAL.md                   user manual (Korean)
  MANUAL_en.md                user manual (English)
  STRUCTURE.md                this document
  TYPE.md, TYPE_en.md         the &TYPE command
  TYPEC.md                    TYPEC (Korean and English in one file)
  STYPE.md, STYPE_en.md       the &STYPE command
  STYPEC.md                   STYPEC (Korean and English in one file)
  MEMORY_LAYOUT.md, _en.md    the memory map
  DOS_PATCHES.md, _en.md      what is patched in DOS
  FONT_EDITOR.md              the font editor
disk/
  K-HANGEUL.DSK               the finished user disk (boot it)
  dos33blank.dsk              the blank DOS 3.3 disk the user disk is made from
src/
  make_all.bat, Makefile      builds everything
  README.md                   guide to the src folders
  PYTHON.md                   Python setup
  driver/                     driver source and font build
  type/, typec/               the &TYPE command and TYPEC
  stype/, stypec/             the &STYPE command and STYPEC
  fonteditor/                 the font editor and font.json
  samples/                    sample text for the disk (N-byte)
    utf8txt/                  UTF-8 copies of the sample text
  tools/                      tools (mkdist.py, nbyte.py, render/, disasm/)
```


### How a build flows

1. The `build.bat` or `Makefile` in `src/driver/`, `src/type/`, `src/typec/`, `src/stype/` and `src/stypec/` assembles each program with cc65.
2. `src/driver/fontgen.py` turns `src/fonteditor/font.json` into the font files.
3. `src/tools/mkdist.py` first makes the N-byte sample files from `src/samples/utf8txt/`, then puts the programs and the sample text on a copy of `disk/dos33blank.dsk`, making `DIST\K-HANGEUL.DSK`. It also copies the documents to `DIST\docs\`.

`make_all.bat` does steps 1 to 3 at once. To keep the final disk in `disk/` as well, copy `DIST\K-HANGEUL.DSK` to `disk\` after the build.


### Where to make a change

| to change | edit |
|---|---|
| driver behaviour | `src/driver/driver.s` and `defs.inc` |
| the look of the font | `font.json`, in the font editor (`src/fonteditor/run_editor.bat`) |
| the sample story | `src/samples/utf8txt/`, then run `make_all.bat` (see `src/samples/README.md`) |
| what goes on the disk | `src/tools/mkdist.py` |
| command behaviour | `src/type/type.s`, `src/stype/stype.s`, `src/stype/score.inc`, and so on |

`DIST/`, `build/`, `out/` and `.venv/` are build or run output. Do not edit them. They are listed in `.gitignore`.


### What is not in the repository

Development notes, progress logs, old experiment folders, the original Hangeul2 files, and images made from the original Hangeul2 program are left out. The disassembly tools are included, but they need the original image to run (see `src/tools/disasm/README.md`).
