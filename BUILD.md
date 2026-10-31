# K-HANGEUL 빌드 방법

> English version: [BUILD_en.md](BUILD_en.md)

이 문서는 소스에서 부팅 디스크 `disk/K-HANGEUL.DSK`를 만들 때까지의 과정을 처음부터 순서대로 설명합니다. Windows를 기준으로 합니다.

빠른 요약(도구가 이미 설치되어 있고 경로를 고쳤다면):

```
build.bat
```

결과는 `disk\K-HANGEUL.DSK`입니다.


## 1. 필요한 것

| 도구 | 용도 | 시험한 버전 |
|---|---|---|
| cc65 (`ca65`, `ld65`) | 어셈블리를 기계어로 바꿈 | 2.19 |
| AppleCommander (`acx.exe`) | 디스크 이미지에 파일을 넣음 | 14.1 |
| Python 3 | 글꼴 변환, 디스크 만들기, 글꼴 편집기 | 3.12.10, 3.13.7 |
| GNU make | 선택 사항. 있으면 `make`로 빌드, 없으면 `.bat` 파일을 차례로 부름 | |
| 에뮬레이터 | 선택 사항. 만든 디스크를 시험함 (AppleWin 또는 MAME, 애플 II+와 랭귀지 카드) | |

Python 패키지는 디스크를 만드는 데는 필요 없습니다. 글꼴 그림(`src/tools/render/`)에는 Pillow, 속도 시험(`tools/perf/`)에는 py65가 필요합니다(`requirements.txt`).


## 2. 단계별 방법

### 2-1. 소스 받기

```
git clone https://github.com/kapple2/k-hangeul.git
cd k-hangeul
```

이미 받았다면 저장소 맨 위 폴더(`build.bat`, `src`, `docs`, `disk`가 있는 곳)로 이동합니다. 이 문서의 모든 명령은 그 폴더에서 실행합니다.

### 2-2. cc65 설치

1. cc65 Windows 스냅샷(https://cc65.github.io/)을 받아 압축을 풉니다. 예: `D:\opt\devtools\asm\cc65`.
2. `bin` 폴더에 `ca65.exe`와 `ld65.exe`가 있는지 확인합니다.

### 2-3. AppleCommander 설치

1. AppleCommander의 명령줄 도구 `acx.exe`(https://applecommander.github.io/)를 받습니다. 예: `C:\bin\acx.exe`.
2. 확인: `C:\bin\acx.exe -h`

### 2-4. Python 확인

```
py -3 --version
py -3 -c "import tkinter; print('tkinter ok')"
```

둘째 줄이 실패하면 python.org에서 Python을 다시 설치하고, 설치 화면의 기능 선택에서 **tcl/tk and IDLE**를 체크하세요(글꼴 편집기에 필요합니다). 디스크만 만든다면 첫 줄만 되면 됩니다.

### 2-5. 가상 환경 만들기 (선택 사항, 권장)

가상 환경은 이 프로젝트의 Python 패키지를 컴퓨터의 다른 것과 떼어 둡니다. 저장소 맨 위 폴더에서:

```
py -3 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

PowerShell에서는 둘째 줄 대신 `.venv\Scripts\Activate.ps1`을 씁니다(스크립트 실행이 막혀 있으면 `Set-ExecutionPolicy -Scope Process RemoteSigned`을 먼저 실행하세요). 끝내려면 `deactivate`를 입력합니다.

- `.venv`는 `.gitignore`에 들어 있어서 저장소에 올라가지 않습니다.
- 글꼴 편집기(`src\fonteditor\run_editor.bat`)는 `.venv`가 있으면 그것을 씁니다.
- 디스크 빌드(`build.bat`)는 `py -3`를 쓰므로 가상 환경을 켜지 않아도 됩니다.

### 2-6. 도구 경로 고치기

기본 경로는 `cc65`가 `D:\opt\devtools\asm\cc65\bin`, `acx.exe`가 `C:\bin\acx.exe`입니다. 다르면 아래 파일의 `CC65`와 `ACX` 줄을 고칩니다.

| 파일 | 언제 쓰이나 |
|---|---|
| `src\make_all.bat` | 항상 (`build.bat`이 이 파일을 부름) |
| `src\driver\build.bat`, `src\type\build.bat`, `src\typec\build.bat`, `src\stype\build.bat`, `src\stypec\build.bat` | GNU make가 없을 때 (각자 경로를 따로 가지고 있음) |
| 같은 폴더의 `Makefile` | 폴더 안에서 `make`를 직접 쓸 때. 또는 명령줄에서 `make CC65=... ACX=...` |

### 2-7. 빌드

```
build.bat
```

`build.bat`이 하는 일:

1. `src\make_all.bat`을 실행합니다.
   1. 드라이버를 만듭니다. `src\driver\fontgen.py`가 `src\fonteditor\font.json`을 `FONT12.bin`(한글)과 `FONT6X10.bin`(영문)으로 바꾸고, cc65가 `driver.s`를 `K-HANGEUL.bin`으로 만듭니다.
   2. `TYPE`, `TYPEC`, `STYPE`, `STYPEC`를 만듭니다.
   3. `src\tools\mkdist.py`가 예제 글(`src\samples\utf8txt\`)을 N바이트 파일로 바꾸고, 빈 DOS 3.3 디스크(`disk\dos33blank.dsk`)의 사본에 프로그램과 예제를 넣어 `DIST\K-HANGEUL.DSK`를 만듭니다.
2. `DIST\K-HANGEUL.DSK`를 `disk\K-HANGEUL.DSK`로 복사합니다.

마지막에 `disk\K-HANGEUL.DSK is ready`가 나오면 성공입니다. 실패하면 `BUILD FAILED`가 나오고, 그 위의 메시지가 원인입니다.

### 2-8. 결과 확인

```
C:\bin\acx.exe -l disk\K-HANGEUL.DSK
```

`HELLO`, `K-HANGEUL`, `FONT12`, `FONT6X10`, `TYPE`, `TYPEC`, `STYPE`, `STYPEC`, 예제 파일들이 보여야 합니다. 에뮬레이터(애플 II+, 랭귀지 카드 16K, 드라이브 1)에 디스크를 넣고 부팅하면 배너가 나오고 `]` 프롬프트가 뜹니다. 사용법은 `docs\MANUAL.md`를 보세요.

| 만들어지는 것 | 위치 |
|---|---|
| 완성된 디스크 | `disk\K-HANGEUL.DSK` |
| 일반 사용자용: 디스크 사본과 사용 설명서(`MANUAL.md`, `MANUAL_en.md`)만 | `DIST\` (매번 새로 만들어짐, 저장소에 올라가지 않음) |
| 각 프로그램의 중간 결과 | `src\<폴더>\build\` (저장소에 올라가지 않음) |


## 3. 자주 하는 작업

**글꼴 고치기.** `src\fonteditor\run_editor.bat`을 실행해 `font.json`을 고친 뒤 `build.bat`을 다시 실행합니다.

**드라이버 고치기.** `src\driver\driver.s`와 `defs.inc`를 고치고 `build.bat`을 실행합니다. 바이너리를 직접 고치지 마세요. 소스는 어셈블리입니다.

**예제 글 고치기.** `src\samples\utf8txt\`의 UTF-8 파일을 고치고 `build.bat`을 실행합니다(`src\samples\README.md`).

**프로그램 하나만 빌드하기.** 그 폴더에서 `build.bat` 또는 `make`를 실행합니다. 예: `cd src\driver` 후 `build.bat`. 결과는 그 폴더의 `build\`에 생깁니다. 디스크까지 만들려면 맨 위 `build.bat`을 쓰세요.

**빌드 결과 지우기.** `clean.bat`(또는 `build.bat clean`)은 각 `src\<폴더>\build\`(목적 파일과 프로그램 파일), Python 캐시, `DIST\` 안의 내용을 지웁니다. `disk\K-HANGEUL.DSK`와 소스는 지우지 않습니다. GNU make나 cc65가 없어도 됩니다.

**속도 시험(선택).** `tools\perf\README.md`를 보세요. `py65`가 필요하므로 2-5의 가상 환경에 `requirements.txt`를 설치하세요.


## 4. 문제가 생기면

| 증상 | 원인과 해결 |
|---|---|
| `cannot write ...K-HANGEUL.DSK: another program (an emulator?) has it open` | 에뮬레이터가 디스크를 열고 있습니다. 에뮬레이터를 끄고 다시 실행하세요. |
| `missing ...: build the programs first` | 앞 단계의 어셈블이 실패했습니다. 그 위의 cc65 오류 메시지를 보세요. |
| `ca65.exe`나 `ld65.exe`를 찾을 수 없음 | 2-6의 `CC65` 경로를 고치세요. |
| `acx failed` 또는 `acx.exe`를 찾을 수 없음 | 2-6의 `ACX` 경로를 고치세요. |
| `'py'은(는) 내부 또는 외부 명령...` | Python 런처가 없습니다. python.org의 설치 프로그램으로 설치하고 "py launcher"를 선택하세요. |
| 글꼴 편집기가 `No module named tkinter` | 2-4처럼 Python을 다시 설치하며 **tcl/tk and IDLE**를 체크하세요. |
| `build.bat` 실행 후 `BUILD FAILED`만 보임 | 그 위에 나온 첫 오류 메시지를 보세요. 마지막 줄은 요약일 뿐입니다. |
