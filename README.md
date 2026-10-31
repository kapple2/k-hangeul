# K-HANGEUL (캐플한글)

애플 II+(와 IIe, IIc, IIgs)의 고해상도 화면에 작고 읽기 쉬운 한글(12×12)과 영문(6×10)을 보여 주는 드라이버입니다. 한글2(Hangeul2)를 고쳐 만들었습니다. 주 용도는 텍스트 BASIC 프로그램을 한글로 쓰는 것입니다. 화면은 46칸 × 16줄이고, 한 줄에 한글 23자가 들어갑니다. DOS 3.3과 언어 카드(16K)가 필요합니다. 한글 BASIC 명령어 부가 프로그램(KBASIC)을 위한 연결 자리가 있지만, KBASIC 자체는 이 저장소에 없습니다.

| 폴더 | 내용 |
|---|---|
| `docs/` | 사용 설명서. `MANUAL.md`(한국어), `MANUAL_en.md`(English). `STRUCTURE.md`는 저장소 구조를 설명합니다 |
| `src/` | 모든 소스: 드라이버, 프로그램 네 개, 글꼴 편집기, 예제, 디스크 만들기. 자세한 설명은 `src/README.md` |
| `disk/` | `K-HANGEUL.DSK`: 완성된 사용자 디스크(부팅용). `dos33blank.dsk`: 그 디스크를 만드는 빈 DOS 3.3 디스크 |


## 빌드

cc65 어셈블러(ca65, ld65)와 Python 3이 필요합니다. `acx.exe`(AppleCommander)는 디스크 이미지에 프로그램을 넣을 때만 필요합니다.

```
build.bat
```

결과: `disk\K-HANGEUL.DSK`(사용자 디스크). 저장소 바로 아래의 `DIST\`에는 일반 사용자용 디스크 사본과 사용 설명서만 만들어집니다. 빌드 결과를 지우려면 `clean.bat`을 실행하세요. 단계별 방법, 도구 경로, Python 가상 환경은 [BUILD.md](BUILD.md)에 있습니다. Python 자세한 내용은 `src/PYTHON.md`에 있습니다.


## 글꼴 고치기

`src\fonteditor\run_editor.bat`을 실행합니다. `font.json`을 고치며, 고칠 때마다 다시 빌드하세요.

---


# K-HANGEUL

K-HANGEUL is a driver that shows small, readable Hangul (12×12) and English (6×10) on the hi-res screen of an Apple II Plus (and IIe, IIc, IIgs). It is a modified Hangeul2. Its main use is writing text BASIC programs in Korean. The screen is 46 columns by 16 rows, so one line holds 23 Hangul syllables. It needs DOS 3.3 and a language card (16K). It has hooks for an optional Korean BASIC keyword add-on (KBASIC), but KBASIC itself is not in this repository.

| folder | contents |
|---|---|
| `docs/` | the user manual: `MANUAL.md` (Korean), `MANUAL_en.md` (English). `STRUCTURE.md` describes the repository |
| `src/` | all source: the driver, four programs, the font editor, samples and the disk builder. See `src/README.md` |
| `disk/` | `K-HANGEUL.DSK`: the finished user disk (boot it). `dos33blank.dsk`: the blank DOS 3.3 disk it is made from |


## Build

You need the cc65 assembler (ca65, ld65) and Python 3. `acx.exe` (AppleCommander) is needed only to put programs on a disk image.

```
build.bat
```

Result: `disk\K-HANGEUL.DSK` (the user disk), plus a `DIST\` folder at the top of the repository with only what an ordinary user needs: a copy of the disk and the user manual. Run `clean.bat` to remove the build output. Step-by-step instructions, the tool paths and the Python virtual environment are in [BUILD_en.md](BUILD_en.md). Python details are in `src/PYTHON.md`.


## Edit the font

Run `src\fonteditor\run_editor.bat`. It edits `font.json`. Rebuild after each change.
