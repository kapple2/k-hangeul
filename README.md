# K-HANGEUL (캐플한글)

애플 II+의 고해상도 화면에 작고 읽기 쉬운 한글(12×12)과 영문(6×10)을 보여 주는 드라이버입니다. 한글2(Hangeul2)를 고쳐 만들었습니다. 주 용도는 텍스트 BASIC 프로그램을 한글로 쓰는 것입니다. 화면은 46칸 × 16줄이고, 한 줄에 한글 23자가 들어갑니다. DOS 3.3과 언어 카드(16K)가 필요합니다.

| 폴더 | 내용 |
|---|---|
| `docs/` | 사용 설명서. `MANUAL.md`(한국어), `MANUAL_en.md`(English). `STRUCTURE.md`는 저장소 구조를 설명합니다 |
| `src/` | 모든 소스: 드라이버, 프로그램 네 개, 글꼴 편집기, 예제, 디스크 만들기. 자세한 설명은 `src/README.md` |
| `disk/` | `K-HANGEUL.DSK`: 완성된 사용자 디스크(부팅용). `dos33blank.dsk`: 그 디스크를 만드는 빈 DOS 3.3 디스크 |


## 빌드

cc65 어셈블러(ca65, ld65)와 Python 3이 필요합니다. `acx.exe`(AppleCommander)는 디스크 이미지에 프로그램을 넣을 때만 필요합니다.

```
cd src
make_all.bat
```

결과: 저장소 바로 아래의 `DIST\K-HANGEUL.DSK`(사용자 디스크), `DIST\bin`(프로그램 파일), `DIST\docs`(문서)입니다. cc65와 AppleCommander의 경로는 `src\make_all.bat`과 각 `Makefile` 위쪽에서 정합니다. Python과 선택 패키지는 `src/PYTHON.md`에 있습니다.


## 글꼴 고치기

`src\fonteditor\run_editor.bat`을 실행합니다. `font.json`을 고치며, 고칠 때마다 다시 빌드하세요.

---


# K-HANGEUL

K-HANGEUL is a driver that shows small, readable Hangul (12×12) and English (6×10) on the hi-res screen of an Apple II Plus. It is a modified Hangeul2. Its main use is writing text BASIC programs in Korean. The screen is 46 columns by 16 rows, so one line holds 23 Hangul syllables. It needs DOS 3.3 and a language card (16K).

| folder | contents |
|---|---|
| `docs/` | the user manual: `MANUAL.md` (Korean), `MANUAL_en.md` (English). `STRUCTURE.md` describes the repository |
| `src/` | all source: the driver, four programs, the font editor, samples and the disk builder. See `src/README.md` |
| `disk/` | `K-HANGEUL.DSK`: the finished user disk (boot it). `dos33blank.dsk`: the blank DOS 3.3 disk it is made from |


## Build

You need the cc65 assembler (ca65, ld65) and Python 3. `acx.exe` (AppleCommander) is needed only to put programs on a disk image.

```
cd src
make_all.bat
```

Result: `DIST\K-HANGEUL.DSK` (the user disk), `DIST\bin` (the program files) and `DIST\docs` (the documents), in the folder above `src`. Set the cc65 and AppleCommander paths at the top of `src\make_all.bat` and each `Makefile`. Python and optional packages are described in `src/PYTHON.md`.


## Edit the font

Run `src\fonteditor\run_editor.bat`. It edits `font.json`. Rebuild after each change.
