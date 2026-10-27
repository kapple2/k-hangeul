# tools: 도구 모음


이 폴더의 도구는 디스크를 만들거나, 예제 글을 바꾸거나, 글꼴을 그림으로 보거나, 옛 드라이버를 어셈블리로 풀어 볼 때 씁니다. 드라이버나 프로그램 자체에는 들어가지 않습니다.

| 파일 | 하는 일 | 언제 쓰나 |
|---|---|---|
| `mkdist.py` | N바이트 예제 파일을 만들고, 디스크 이미지와 `DIST` 폴더를 만듭니다 | `make_all.bat`이 자동으로 실행합니다. 직접 쓸 일은 드뭅니다 |
| `nbyte.py` | N바이트(키 입력) 텍스트와 UTF-8을 서로 바꿉니다 | 예제 글을 고칠 때. 사용법은 `../samples/README.md` |
| `render/` | 글꼴을 그림 파일(PNG)로 만듭니다 | 글꼴을 고친 뒤 전체 모양을 볼 때. 사용법은 `render/README.md` |
| `disasm/` | 옛 한글2 이미지를 어셈블리로 풀던 도구입니다 | 기록용. 사용법은 `disasm/README.md` |

Python 도구는 표준 라이브러리만 쓰는 것(`mkdist.py`, `nbyte.py`, `disasm/`)과 Pillow가 필요한 것(`render/`)이 있습니다. 설치는 `src/PYTHON.md`를 보세요.


---


# tools: helper programs


The tools in this folder make the disk, convert the sample text, draw the font as pictures, or show how the old driver was taken apart. None of them is part of the driver or the programs.

| file | what it does | when to use it |
|---|---|---|
| `mkdist.py` | makes the N-byte sample files, then the disk image and the `DIST` folder | `make_all.bat` runs it for you. You rarely call it yourself |
| `nbyte.py` | converts N-byte (keystroke) text to UTF-8 and back | editing the sample story. See `../samples/README.md` |
| `render/` | draws the font as PNG pictures | after changing the font, to see the whole set. See `render/README.md` |
| `disasm/` | the tools that took the old Hangeul2 image apart into assembly | a record only. See `disasm/README.md` |

Some Python tools use only the standard library (`mkdist.py`, `nbyte.py`, `disasm/`). `render/` needs Pillow. See `src/PYTHON.md` for setup.
