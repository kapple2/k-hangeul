# samples: 예제 글


이 폴더에는 디스크에 들어가는 예제 글이 있습니다. 「날개」(이상)를 16개 파일로 나눈 `NALGAE1.txt`-`NALGAE16.txt`, 그리고 BASIC 예제 `mixed.bas`, `story.bas`입니다. `utf8txt/` 폴더에는 같은 글을 UTF-8(일반 텍스트 편집기에서 읽는 형식)로 바꾼 사본이 있습니다.


### 파일 형식(N바이트)

`NALGAE*.txt`는 UTF-8이나 한글 코드표 파일이 아닙니다. 애플 II의 자판이 보내는 **키 입력 바이트**를 그대로 저장한 것입니다. 한글2와 3327 한글에서 쓰던 방식이며 "N바이트"라고 부릅니다. 드라이버가 이 바이트를 받아서 글자를 조합합니다. 그래서 글자 하나가 키 여러 개로 저장됩니다.

| 바이트 | 뜻 |
|---|---|
| `$8B` (Ctrl-K) | 한글 시작 |
| `$81` (Ctrl-A) | 한글 끝 |
| `$C1`-`$DA` (대문자, 최상위 비트 켜짐) | 2벌식 키. 예: `$D2` = `R` = ㄱ, `$CB` = `K` = ㅏ |
| `$AD` `$BD` `$AA` `$BC` `$BE` `$BB` `$AB` | 된소리와 ㅒ ㅖ 키: `-` `=` `*` `<` `>` `;` `+` |
| `$8D` | 줄바꿈(CR). 디스크에서는 LF로 바뀌어 DOS 텍스트 파일이 됩니다 |
| `$A0` 등 그 밖의 값 | 영문, 숫자, 공백, 문장부호: ASCII 값에 최상위 비트를 켠 것 |

예: 파일의 첫 바이트는 `8B D3 CB C6 D2 CF 81`입니다. `8B`는 한글 시작, `D3 CB C6`은 `S K F` = 날(ㄴ ㅏ ㄹ), `D2 CF`는 `R O` = 개(ㄱ ㅐ), `81`은 한글 끝입니다. 그래서 글 첫 줄은 「날개」입니다.


### UTF-8 사본(`utf8txt/`)

`utf8txt/NALGAE1.txt`-`NALGAE16.txt`는 같은 글을 UTF-8, LF 줄바꿈, BOM 없이 저장한 것입니다. 편집기에서 읽고 고칠 수 있습니다. 디스크에 넣는 파일은 아닙니다. 빌드가 이 파일들에서 N바이트 파일을 만듭니다.


### 변환 방법

변환 도구는 `../tools/nbyte.py`입니다. 표준 Python만 씁니다.

```
rem N바이트 -> UTF-8 (읽기, 편집용)
py -3 src\tools\nbyte.py decode src\samples\NALGAE1.txt src\samples\utf8txt\NALGAE1.txt

rem UTF-8 -> N바이트 (디스크에 넣을 파일)
py -3 src\tools\nbyte.py encode src\samples\utf8txt\NALGAE1.txt src\samples\NALGAE1.txt

rem 변환이 정확한지 확인 (N바이트 -> UTF-8 -> N바이트 가 같은지)
py -3 src\tools\nbyte.py check src\samples\NALGAE1.txt
```

`check`가 `OK: round trip is exact`를 내면 변환이 정확합니다. 16개 파일 모두 이 방법으로 확인했습니다.


### 글을 고쳐서 디스크에 넣는 순서

1. `utf8txt\NALGAE3.txt`를 편집기로 고칩니다. 한글은 자유롭게 쓸 수 있습니다.
2. `src\make_all.bat`을 실행합니다. 빌드가 `utf8txt`의 글을 N바이트 파일 `NALGAE1`-`16`으로 바꾼 뒤 디스크를 만듭니다.
3. 필요하면 `py -3 src\tools\nbyte.py check src\samples\NALGAE3.txt`로 변환이 정확한지 확인합니다.

`src\samples\NALGAE*.txt`는 빌드가 만드는 결과이므로 직접 고치지 마세요. 원본은 `utf8txt/`입니다. 빌드 중에 `cannot store` 오류가 나면 `make_all.bat`이 멈추니, 그 글자를 바꾸세요.

---


# samples: sample text


This folder holds the sample text that goes on the disk: `NALGAE1.txt`-`NALGAE16.txt` (the story 「날개」 by Yi Sang, split into 16 files), and the BASIC examples `mixed.bas` and `story.bas`. The `utf8txt/` folder holds UTF-8 copies of the same story, for reading and editing.


### File format (N-byte)

`NALGAE*.txt` is neither UTF-8 nor a Korean code table. It stores the **key bytes the Apple II keyboard sends**, as they are. This is the "N-byte" format of Hangeul2 and the 3327 Hangul system. The driver turns the bytes into syllables, so one syllable is stored as several keys.

| byte | meaning |
|---|---|
| `$8B` (Ctrl-K) | start a Hangul run |
| `$81` (Ctrl-A) | end a Hangul run |
| `$C1`-`$DA` (uppercase, high bit set) | two-set keys. For example `$D2` = `R` = ㄱ, `$CB` = `K` = ㅏ |
| `$AD` `$BD` `$AA` `$BC` `$BE` `$BB` `$AB` | the tense keys and ㅒ ㅖ: `-` `=` `*` `<` `>` `;` `+` |
| `$8D` | line end (CR). On the disk it becomes LF, the normal DOS text line end |
| other values, such as `$A0` | ASCII with the high bit set: English, digits, space, punctuation |

Example: the file starts `8B D3 CB C6 D2 CF 81`. `8B` starts Hangul, `D3 CB C6` is `S K F` = 날 (ㄴ ㅏ ㄹ), `D2 CF` is `R O` = 개 (ㄱ ㅐ), and `81` ends the run. So the first line is 「날개」.


### UTF-8 copies (`utf8txt/`)

`utf8txt/NALGAE1.txt`-`NALGAE16.txt` are the same story in UTF-8 with LF line ends and no BOM. Edit these. They are not put on the disk directly: the build makes the N-byte files from them.


### How to convert

The converter is `../tools/nbyte.py`. It uses only the Python standard library.

```
rem N-byte -> UTF-8 (to read and edit)
py -3 src\tools\nbyte.py decode src\samples\NALGAE1.txt src\samples\utf8txt\NALGAE1.txt

rem UTF-8 -> N-byte (the file that goes on the disk)
py -3 src\tools\nbyte.py encode src\samples\utf8txt\NALGAE1.txt src\samples\NALGAE1.txt

rem check that a file survives decode and encode unchanged
py -3 src\tools\nbyte.py check src\samples\NALGAE1.txt
```

`check` prints `OK: round trip is exact` when the conversion is lossless. All 16 files pass this check.


### To change the story and put it on the disk

1. Edit `utf8txt\NALGAE3.txt` in any editor. Hangul can be typed freely.
2. Run `src\make_all.bat`. The build turns the text in `utf8txt` into the N-byte files `NALGAE1`-`16`, then makes the disk.
3. Optional: run `py -3 src\tools\nbyte.py check src\samples\NALGAE3.txt` to confirm the conversion is exact.

Do not edit `src\samples\NALGAE*.txt` by hand: the build writes them from `utf8txt/`. If the build stops with `cannot store`, change that character.
