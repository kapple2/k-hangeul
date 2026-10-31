# 글꼴 편집기

`run_editor.bat`을 실행하세요. 드라이버가 그리는 모든 글리프가 들어 있는 `src/fonteditor/font.json`을 편집합니다.


## 고칠 수 있는 것

- **한글 조각**: 초성 6개 뱅크, 중성 2개 뱅크, 종성. 화면의 한 글자는 조각 세 개를 OR로 합친 것입니다. 미리보기에서는 고치는 조각이 노란색, 나머지 두 조각이 회색으로 보이고, 겹치는 곳은 흰색입니다.
- **영문**: 숫자, 대문자, 소문자, 기호입니다(왼쪽 목록의 마지막 네 그룹, 아래로 스크롤하세요). 글리프는 가로 6픽셀, 세로 10줄입니다. 화면에서는 12줄 칸의 아래 10줄에 놓이므로, 칸의 위 2줄은 비어 있습니다. 글자는 `0`-`9`, `A`-`Z`, `a`-`z`와 기호 33개입니다. 공백은 빈 칸입니다.

왼쪽 버튼은 그리기, 오른쪽 버튼은 지우기입니다. **Undo**(Ctrl-Z)는 고치는 조각을 한 단계 되돌립니다. **Revert piece**는 원래 글꼴의 그 글리프로 되돌립니다(원본은 `font.json`에 남아 있습니다). **Save**(Ctrl-S)는 `font.json`을 저장하고, 이전 파일은 `font.prev.json`으로 남깁니다.

**현재 위치 찾기.** 고치는 글자는 목록에서 노란 배경으로 강조되고, 그 그룹의 제목(예: "종성" 또는 "English: Upper case")도 강조됩니다. 목록은 저절로 스크롤해서 그것들을 보여 줍니다. 그리드 위의 제목도 노란색입니다.

**이 조각을 쓰는 글자들.** 창 오른쪽 아래(미리보기 글 아래)에는, 고치는 글리프를 쓰는 모든 글자가 나옵니다. 내 조각은 노란색, 나머지는 회색입니다. 초성이면 그 뱅크에서 그 초성을 쓰는 모든 음절, 중성이면 그 모음을 가진 모든 음절(뱅크에 따라 받침이 있거나 없는 것), 종성이면 그 받침으로 끝나는 모든 음절입니다. 영문이면 고치는 글자를 다른 모든 글자와 왼쪽과 오른쪽으로 나란히 보여 줍니다(간격 확인용). 이 시트는 픽셀을 그린 뒤 잠시 후에 갱신되고, 자체 스크롤바가 있습니다.

미리보기 글은 마음대로 바꿀 수 있습니다. 한글 음절은 12픽셀, 영문 글자는 6픽셀을 쓰고, 줄은 화면처럼 46칸에서 넘어갑니다. 기본 예문에는 `0O1lI|`가 들어 있어서 헷갈리는 글자들이 어떻게 다른지 볼 수 있습니다.


## 새 글꼴 쓰기

편집기는 `font.json`만 바꿉니다. 디스크에 올리려면 프로젝트 폴더에서 `make_all.bat`을 실행하세요(결과는 `DIST\K-HANGEUL.DSK`). 또는 `src\driver`에서 `build.bat disk`를 실행하세요. 둘 다 `font.json`을 `FONT12.bin`(한글)과 `FONT6X10.bin`(영문, 디스크 파일 `FONT6X10`)으로 바꾸고 드라이버를 다시 만듭니다.


## 처음부터 같았던 영문 글리프

편집기의 첫 버전에서는 `0`과 `O`가 같은 비트맵이었고, `I`와 `|`도 같았습니다(`l`과 `1`은 원래 달랐습니다). 이제 그것들을 고치는 것은 여러분의 몫입니다.


---


# Font editor

Run `run_editor.bat`. It edits `src/fonteditor/font.json`, which holds every glyph the driver draws.


## What you can edit

- **Hangul pieces**: the 6 banks of initials, the 2 banks of vowels, and the finals. A syllable on screen is the three pieces ORed together, so the preview shows the piece you edit in yellow, the other two in gray, and white where they overlap.
- **English**: digits, upper case, lower case and symbols (the last four groups in the left list; scroll down). Each glyph is 6 pixels wide and 10 rows high. On the screen it sits in the bottom 10 rows of a 12-row cell, so the top 2 rows of the cell are empty. The glyphs are `0`-`9`, `A`-`Z`, `a`-`z` and the 33 symbols. Space is blank.

Left button draws, right button erases. **Undo** (Ctrl-Z) goes back a step in the piece you are editing; **Revert piece** restores the glyph as it was in the original font (the original copy is kept in `font.json`). **Save** (Ctrl-S) writes `font.json` and keeps the previous file as `font.prev.json`.

**Finding your place.** The letter you are editing is highlighted in the list (yellow background), and so is the title of its group (for example "종성" or "English: Upper case"). The list scrolls by itself to show them. The title above the grid is in yellow too.

**Letters that use this piece.** The lower right of the window (below the preview text) shows every letter that uses the glyph you are editing, with your piece in yellow and the rest in gray: for an initial, all syllables that use that initial in that bank; for a vowel, all syllables with that vowel (with or without a final, depending on the bank); for a final, all syllables that end with it; for an English character, the character next to every other character, on the left and on the right (to check the gaps). The sheet updates a moment after each pixel you draw and has its own scroll bar.

The preview text is yours to change. A Hangul syllable takes 12 pixels and an English character 6, and lines wrap at 46 columns like the screen. The default sample has `0O1lI|` so you can see which look-alikes differ.


## Using the new font

The editor only changes `font.json`. To put it on the disk run `make_all.bat` in the project folder (the result is `DIST\K-HANGEUL.DSK`), or `build.bat disk` in `src\driver`. Both turn `font.json` into `FONT12.bin` (Hangul) and `FONT6X10.bin` (English; the disk file `FONT6X10`) and rebuild the driver.


## English glyphs that were the same

In the first version of this font `0` and `O` had the same bitmap, and so did `I` and `|`. (`l` and `1` already differed.) They are for you to change now.
