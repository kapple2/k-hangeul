# Python 설정

이 프로젝트의 Python 프로그램은 여러 개입니다. 그림 그리기(`tools/render/`)만 Pillow가 필요하고, 나머지는 표준 라이브러리만 씁니다.

| 스크립트 | 하는 일 | 필요한 것 |
|---|---|---|
| `driver/fontgen.py` | `fonteditor/font.json`을 드라이버 빌드용 글꼴 파일로 바꿈 | Python 3 |
| `fonteditor/editor.py` | 글꼴 편집기 창 | Python 3과 **tkinter** |
| `tools/mkdist.py` | 디스크 이미지와 `DIST`를 만듦. AppleCommander(`acx.exe`)를 부름 | Python 3 |
| `tools/nbyte.py` | 예제 글의 N바이트와 UTF-8을 서로 바꿈 | Python 3 |
| `tools/render/*.py` | 글꼴을 그림 파일(PNG)로 만듦 | Python 3과 **Pillow** |
| `tools/disasm/*.py` | 옛 드라이버를 풀던 도구(기록용. 원본 이미지가 필요함) | Python 3 |

빌드 스크립트는 Python 런처(`py -3`)로 실행합니다. 확인하려면:

```
py -3 --version
py -3 -c "import tkinter; print('tkinter ok')"
```

두 번째 줄이 실패하면 python.org에서 Python을 다시 설치하고, 설치 화면의 기능 선택에서 **tcl/tk and IDLE**를 체크하세요.


### 가상 환경(선택 사항)

가상 환경은 이 프로젝트의 Python 패키지를 컴퓨터의 다른 것과 떼어 둡니다. 패키지를 추가할 때만 필요합니다(`requirements.txt` 참고). 글꼴 편집기는 `.venv`가 있으면 그것을 씁니다.

프로젝트 폴더(`src`와 `docs`가 있는 곳)에서:

```
py -3 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

나오려면 `deactivate`를 입력합니다. `.venv`는 `.gitignore`에 들어 있어서 저장소에 올라가지 않습니다.

가상 환경을 쓰지 않으려면 건너뛰세요. `py -3 src\fonteditor\editor.py`는 기본 Python으로 실행됩니다.


### 패키지 목록

저장소 맨 위의 `requirements.txt`에 목록이 있습니다. 그림 그리기(`tools/render/`, `tools/perf/hgr2png.py`)에 `pillow`가 필요하고, 6502 시뮬레이터(`tools/perf/`)에 `py65`가 필요합니다. 디스크 빌드와 글꼴 편집기에는 둘 다 필요 없습니다.


### 명령

프로젝트 폴더에서:

```
src\fonteditor\run_editor.bat                              글꼴 편집기
py -3 src\driver\fontgen.py src\fonteditor\font.json out   out 폴더에 글꼴 파일 만들기
py -3 src\tools\mkdist.py . C:\bin\acx.exe                 디스크와 DIST 만들기
```

`src\make_all.bat`은 전부를 한 번에 실행합니다(`README.md` 참고).


### 사용한 버전

Windows 11에서 Python 3.12.10과 3.13.7로 시험했습니다. 이 둘만 시험했습니다. 스크립트는 표준 라이브러리만 쓰므로 다른 Python 3 버전도 잘 될 가능성이 크지만, 시험하지는 않았습니다.

---


# Python setup

This project has several Python programs. Only the picture tools (`tools/render/`) need Pillow; the rest use the standard library only.

| script | what it does | needs |
|---|---|---|
| `driver/fontgen.py` | turns `fonteditor/font.json` into the font files for the driver build | Python 3 |
| `fonteditor/editor.py` | the font editor window | Python 3 with **tkinter** |
| `tools/mkdist.py` | builds the disk image and `DIST`; calls AppleCommander (`acx.exe`) | Python 3 |
| `tools/nbyte.py` | converts the N-byte sample text to UTF-8 and back | Python 3 |
| `tools/render/*.py` | draws the font as PNG pictures | Python 3 and **Pillow** |
| `tools/disasm/*.py` | the tools that took the old driver apart (a record; needs the original image) | Python 3 |

The build scripts run these with the Python launcher (`py -3`). To check:

```
py -3 --version
py -3 -c "import tkinter; print('tkinter ok')"
```

If the second line fails, install Python again from python.org and tick **tcl/tk and IDLE** on the features page.


### Virtual environment (optional)

A virtual environment keeps the project's Python packages apart from everything else on your computer. It is needed only if you add packages (see `requirements.txt`). The font editor uses `.venv` if it is there.

From the project folder (the one with `src` and `docs`):

```
py -3 -m venv .venv
.venv\Scripts\activate
python -m pip install --upgrade pip
python -m pip install -r requirements.txt
```

To leave, type `deactivate`. `.venv` is listed in `.gitignore`, so it is never committed.

To skip it, run `py -3 src\fonteditor\editor.py` with the system Python.


### Requirements

`requirements.txt` at the top of the repository lists the packages. The picture tools (`tools/render/`, `tools/perf/hgr2png.py`) need `pillow`; the 6502 simulator (`tools/perf/`) needs `py65`. The disk build and the font editor need neither.


### Commands

From the project folder:

```
src\fonteditor\run_editor.bat                              font editor
py -3 src\driver\fontgen.py src\fonteditor\font.json out   font files into the folder out
py -3 src\tools\mkdist.py . C:\bin\acx.exe                 disk and DIST
```

`src\make_all.bat` runs everything (see `README.md`).


### Versions used

Python 3.12.10 and 3.13.7 on Windows 11. These are the only versions tried. The scripts use only the standard library, so other Python 3 versions are likely to work but are untested.
