# TYPEC: 명령줄 TYPE

`BRUN TYPEC`은 N바이트(자판 입력) 한글 글이 들어 있는 DOS 텍스트 파일을 찍습니다. `]` 프롬프트에서 쓰도록 만든 것입니다. `&TYPE` 명령과 같은 파일 읽기 코드(`src/type/core.inc`)를 쓰는 독립된 프로그램입니다. 아무것도 설치하지 않고, 메모리에 아무것도 남기지 않으며, `HIMEM`도 바꾸지 않습니다.

```
]BRUN TYPEC

FILE NAME
]nalgae1
...글 내용...

FILE NAME
]                      (빈 줄로 프로그램을 끝냅니다)
```

- 이름은 대문자로 바꾸므로 `nalgae1`과 `NALGAE1`은 같습니다. 최대 30자입니다.
- 파일을 찍을 때마다 다시 물어봅니다. 빈 줄에서 Return을 누르면 BASIC으로 돌아갑니다.
- 디스크에 없는 이름이나 텍스트 파일이 아닌 것은 DOS 오류(`FILE NOT FOUND`, `FILE TYPE MISMATCH`)를 내고 `]` 프롬프트로 돌아갑니다.
- 질문은 한 줄에, 이름은 다음 줄에 나옵니다. 드라이버의 줄 편집기가 한 줄 전체를 입력 줄로 받아서, `]`만 건너뛰기 때문입니다.


## 멈추기

찍는 도중 **Ctrl-C**를 누르면 그 바이트를 그린 뒤에 찍기를 멈추고, 키를 가져가 `FILE NAME` 질문으로 돌아갑니다. 이전에는 찍는 동안 Ctrl-C가 무시되어 키보드 버퍼에 남았고, 다음 `FILE NAME` 질문이 그것을 파일 이름으로 받아서 `ERROR #6`이 나왔습니다. **Ctrl-S**는 멈춥니다(아무 키나 누르면 계속합니다. 드라이버 자체의 멈춤입니다). **Ctrl-Reset**은 빠져나갑니다(`HAN`을 치면 드라이버가 다시 켜집니다). 검사에는 바이트마다 약 10사이클이 듭니다(바이트 하나를 그리는 데는 약 7,000사이클).

| 항목 | 값 |
|---|---|
| 원본 | `src/typec/typec.s`, `src/type/core.inc` 포함 |
| 빌드 | `src\typec\build.bat`(또는 `make`). `build.bat disk`는 `TYPEC`을 프로젝트 디스크에 복사합니다 |
| 올라가는 주소 | `$8E00`, 486바이트. 섹터 버퍼는 `$9200`과 `$9300` |
| 디스크 파일 | `TYPEC`(바이너리) |

BASIC 문자열 영역의 `HIMEM` 바로 아래에 올라가므로, 그 근처에 문자열이 많은 BASIC 프로그램이 있는 동안에는 실행하지 마세요. 프로그램에서는 `&TYPE`(`TYPE.md`)을 쓰세요.


---


# TYPEC: the command-line TYPE

`BRUN TYPEC` prints a DOS text file of N-byte (keystroke) Hangul text, for use at the `]` prompt. It is the same file reader as the `&TYPE` command (`src/type/core.inc`) in a program of its own: it installs nothing, leaves nothing in memory, and does not change `HIMEM`.

```
]BRUN TYPEC

FILE NAME
]nalgae1
...the story text...

FILE NAME
]                      (an empty line ends the program)
```

- The name is made upper case, so `nalgae1` and `NALGAE1` are the same. Up to 30 characters.
- It asks again after each file. Press Return on an empty line to go back to BASIC.
- A name that is not on the disk, or a file that is not a text file, gives the normal DOS error (`FILE NOT FOUND`, `FILE TYPE MISMATCH`) and returns to the `]` prompt.
- The question is on a row of its own and the name on the next one, because the driver's line editor takes the whole row as the typed line and skips only the `]`.


## Stopping

Press **Ctrl-C** while it prints: the printing stops after the byte being drawn, the key is taken, and control returns to the `FILE NAME` prompt. Before this, Ctrl-C was ignored while printing and stayed in the keyboard buffer, where the next `FILE NAME` prompt took it as a file name (`ERROR #6`). **Ctrl-S** pauses (any key continues; this is the driver's own pause) and **Ctrl-Reset** breaks out (type `HAN` to switch the driver on again). The check costs about 10 cycles per byte (drawing a byte takes about 7,000).

| item | value |
|---|---|
| source | `src/typec/typec.s`, with `src/type/core.inc` |
| build | `src\typec\build.bat` (or `make`); `build.bat disk` copies `TYPEC` to the project disk |
| load address | `$8E00`, 486 bytes; sector buffers `$9200` and `$9300` |
| disk file | `TYPEC` (binary) |

It loads in the BASIC string area just under `HIMEM`, so do not run it while a program holds strings that near the top. For a program, use `&TYPE` (`TYPE.md`).
