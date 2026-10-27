# render: 글꼴 그림 만들기


글꼴 편집기로 `font.json`을 고친 뒤, 전체 모양을 한눈에 보고 싶을 때 씁니다. 그림은 드라이버가 실제로 그리는 것과 같은 픽셀로 만들어집니다.


### 준비

- Python 3과 Pillow: `py -3 -m pip install -r src\requirements.txt`(`src/PYTHON.md` 참고)
- 한글이 보이는 TrueType 글꼴 파일(제목과 줄 이름에 씀). Windows에는 보통 `C:\Windows\Fonts\malgun.ttf`가 있습니다. 다른 글꼴이면 두 번째 인자로 경로를 줍니다.
- `src/fonteditor/font.json`이 있어야 합니다.


### 사용법

프로젝트 폴더에서:

```
rem 한글 음절 11,172자 전부를 초성마다 PNG 한 장씩 (19장)
py -3 src\tools\render\render_syllables.py

rem 영문 글자를 여러 높이로 보여 주는 그림 (지금 글꼴과 시험용 높이)
py -3 src\tools\render\render_english.py

rem 출력 폴더와 제목 글꼴을 직접 지정할 때
py -3 src\tools\render\render_syllables.py out\syll "C:\Windows\Fonts\malgun.ttf"
```

결과는 기본적으로 `src\tools\render\out\` 아래에 생깁니다. 이 폴더는 `.gitignore`에 있어 저장소에 올라가지 않습니다.

`render_syllables.py`는 끝에 "identical-bitmap duplicates"(같은 모양의 음절이 몇 개인지)와 "blank"(빈 음절)를 알려 줍니다. 모양이 같은 음절이 많으면 그 글꼴 조각이 서로 겹친다는 뜻입니다.


### 파일 설명

| 파일 | 하는 일 |
|---|---|
| `hangul_font.py` | `font.json`을 읽고 한 음절의 12줄 픽셀을 만듭니다. 드라이버의 계산과 같습니다 |
| `render_syllables.py` | 한글 음절 전체 그림 |
| `render_english.py` | 영문 글자 그림. 10줄 글꼴과, 높이를 늘리거나 줄인 시험 그림 |

`render_english.py`의 8줄과 12줄 그림은 10줄 글꼴을 늘리거나 줄인 것입니다. 실제 글꼴이 아니라 크기와 균형을 보기 위한 그림입니다. 실제 높이의 글꼴은 편집기에서 직접 그리세요.


### 이 폴더에 없는 것

예전에는 MAME에서 찍은 화면을 그림으로 바꾸는 도구와, 같은 모양의 음절을 찾는 도구가 있었습니다. 화면 도구는 MAME 메모리 스냅샷과 py65가 필요하고, 중복 찾기는 지금 중복이 없어서 `render_syllables.py`의 보고로 대신합니다.


---


# render: font pictures


Use this after you change `font.json` in the font editor, to see the whole set at once. The pictures are drawn with the same pixels the driver draws.


### Setup

- Python 3 and Pillow: `py -3 -m pip install -r src\requirements.txt` (see `src/PYTHON.md`).
- A TrueType font that shows Hangul, for titles and labels. On Windows this is usually `C:\Windows\Fonts\malgun.ttf`. For another font, give its path as the second argument.
- `src/fonteditor/font.json` must exist.


### How to run

From the project folder:

```
rem all 11,172 Hangul syllables, one PNG per initial consonant (19 files)
py -3 src\tools\render\render_syllables.py

rem English letters at several heights (the current font and mock-ups)
py -3 src\tools\render\render_english.py

rem choose the output folder and the label font
py -3 src\tools\render\render_syllables.py out\syll "C:\Windows\Fonts\malgun.ttf"
```

The results go to `src\tools\render\out\` by default. That folder is listed in `.gitignore`, so it is not committed.

`render_syllables.py` prints how many syllables are blank and how many share a bitmap with another syllable. Many shared bitmaps mean two font pieces overlap.


### The files

| file | what it does |
|---|---|
| `hangul_font.py` | reads `font.json` and builds the 12 pixel rows of one syllable, the same way the driver does |
| `render_syllables.py` | draws all Hangul syllables |
| `render_english.py` | draws the English letters: the current 10-row font, and smaller and taller mock-ups |

The 8-row and 12-row English pictures stretch or shrink the 10-row glyphs. They judge size and balance only. They are not real fonts. Draw a real font in the font editor.


### Not included

The old tool that turned MAME screen dumps into pictures needs MAME memory snapshots and py65, and is not in this repository. The duplicate finder is replaced by the report at the end of `render_syllables.py`.
