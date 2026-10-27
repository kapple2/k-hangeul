# STYPEC: 명령줄 `STYPE`

`STYPEC`은 `TYPEC`에 `STYPE`의 부드러운 효과를 더한 것입니다(`../stype/STYPE.md` 참고). 글줄마다 화면 밖에 먼저 그린 뒤, 화면에 픽셀 줄 하나씩 위에서 아래로 보여 줍니다. 독립된 프로그램이므로 설치할 것이 없고(`&` 명령이 없음), 남기는 것도 없습니다.


## 사용법

```
]BRUN STYPEC

FILE NAME
]SAMPLE1

FILE NAME
]NALGAE1,5
```

`FILE NAME`이 물어보면 그 파일을 찍고 다시 물어봅니다. 빈 줄(Return)에서 끝납니다. 이름 뒤에 쉼표를 찍고 0부터 255 사이의 수를 쓸 수 있습니다. 이것이 **기다림**으로, `&STYPE`의 세 번째 인자와 같습니다(`NALGAE1,5`는 픽셀 줄마다 약 5밀리초를 기다립니다). 없으면 기다림은 0입니다. 소문자 이름도 됩니다. 디스크에 없는 파일은 DOS 오류 `FILE NOT FOUND`를 내고, DOS를 통해 프로그램을 끝냅니다.


## 멈추기

찍는 도중 **Ctrl-C**를 누르면 그 바이트를 그린 뒤에 찍기를 멈추고, 키를 가져가 `FILE NAME` 질문으로 돌아갑니다. 이전에는 찍는 동안 Ctrl-C가 무시되어 키보드 버퍼에 남았고, 다음 `FILE NAME` 질문이 그것을 파일 이름으로 받아서 `ERROR #6`이 나왔습니다. 기다리는 동안 Ctrl-C를 누르면 남은 기다림도 건너뜁니다. **Ctrl-S**는 멈춥니다(아무 키나 누르면 계속합니다. 드라이버 자체의 멈춤입니다). **Ctrl-Reset**은 빠져나갑니다(`HAN`을 치면 드라이버가 다시 켜집니다). 검사에는 바이트마다 약 10사이클이 듭니다(바이트 하나를 그리는 데는 약 7,000사이클).


## 어디에 있나

| 항목 | 값 |
|---|---|
| 원본 | `src/stypec/stypec.s`(`typec.s`에서 만듦), `../stype/score.inc`(줄 그리기 루틴, `STYPE`과 같이 씀), `../type/core.inc`(파일 읽기 코드) |
| 빌드 | `src\stypec\build.bat`(또는 그 폴더에서 `make`). `make_all.bat`이 다른 것과 함께 만듭니다 |
| 올라가는 주소 | `$8A00`, 951바이트(`$8A00-$8DB6`) |
| 줄 버퍼 | 코드 바로 뒤의 512바이트(파일에는 들어 있지 않음) |
| 섹터 버퍼 | `$9200`과 `$9300` |
| 디스크 파일 | `STYPEC`(바이너리, 종류 B) |

`BRUN STYPEC`은 `HIMEM`을 낮추지 않습니다. BASIC 메모리의 위쪽 2.5KB(`$8A00-$93FF`)를 덮어쓰므로, BASIC 프로그램이 없는 `]` 프롬프트에서 실행하거나, 그 자리를 쓰지 않는 짧은 프로그램에서 실행하세요. 드라이버의 줄 그리기 모드는 K-HANGEUL 드라이버가 올라가 있어야 합니다(디스크의 `HELLO`가 올립니다).


## 함께 보기

`STYPE.md`는 줄 그리기 모드와 기다림을 설명합니다. `TYPEC.md`는 기본 버전을 설명합니다.


---


# STYPEC: the command-line `STYPE`

`STYPEC` is `TYPEC` with the smooth effect of `STYPE` (see `../stype/STYPE.md`): each row of text is drawn off screen and then shown on the screen one pixel row at a time from top to bottom. It is a program of its own: it needs nothing installed (no `&` command) and leaves nothing behind.


## Use

```
]BRUN STYPEC

FILE NAME
]SAMPLE1

FILE NAME
]NALGAE1,5
```

It asks `FILE NAME`, prints that file, and asks again; an empty line (Return) ends it. After the name you may type a comma and a number from 0 to 255: the **wait** between pixel rows, as the third argument of `&STYPE` (`NALGAE1,5` waits about 5 ms after each pixel row). Without it the wait is 0. Lower case names are accepted; a file that is not on the disk gives the DOS error `FILE NOT FOUND` and ends the program through DOS.


## Stopping

Press **Ctrl-C** while it prints: the printing stops after the byte being drawn, the key is taken, and control returns to the `FILE NAME` prompt. Before this, Ctrl-C was ignored while printing and stayed in the keyboard buffer, where the next `FILE NAME` prompt took it as a file name (`ERROR #6`). Ctrl-C during a wait also skips the remaining waits. **Ctrl-S** pauses (any key continues; this is the driver's own pause) and **Ctrl-Reset** breaks out (type `HAN` to switch the driver on again). The check costs about 10 cycles per byte (drawing a byte takes about 7,000).


## Where it lives

| item | value |
|---|---|
| source | `src/stypec/stypec.s` (from `typec.s`), `../stype/score.inc` (the strip routines, shared with `STYPE`), `../type/core.inc` (the file reader) |
| build | `src\stypec\build.bat` (or `make` in that folder); `make_all.bat` builds it with everything else |
| load address | `$8A00`, 951 bytes (`$8A00-$8DB6`) |
| strip buffer | 512 bytes right after the code (not stored in the file) |
| sector buffers | `$9200` and `$9300` |
| disk file | `STYPEC` (binary, type B) |

`BRUN STYPEC` does not lower `HIMEM`: it overwrites the top 2.5 KB of BASIC memory (`$8A00-$93FF`), so run it at the `]` prompt with no BASIC program, or from a short program that does not use that area. The driver's strip mode needs the K-HANGEUL driver to be loaded (the disk's `HELLO` does it).


## See also

`STYPE.md` explains the strip mode and the wait. `TYPEC.md` describes the plain version.
