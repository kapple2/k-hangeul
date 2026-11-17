; made by src/tools/genkerr.py: do not edit (change the texts there). Korean Applesoft error messages, johab pairs, $00 ended.
KEM0:     .byte $46,$4F,$52,$20,$B4,$F4,$B7,$71,$00    ; $00 NEXT WITHOUT FOR: FOR 없음
KEM1:     .byte $A2,$85,$A4,$F3,$00    ; $10 SYNTAX: 문법
KEM2:     .byte $47,$4F,$53,$55,$42,$20,$B4,$F4,$B7,$71,$00    ; $16 RETURN WITHOUT GOSUB: GOSUB 없음
KEM3:     .byte $B8,$61,$9E,$61,$20,$8F,$7B,$00    ; $2A OUT OF DATA: 자료 끝
KEM4:     .byte $88,$74,$20,$A4,$F1,$B6,$E1,$00    ; $35 ILLEGAL QUANTITY: 값 범위
KEM5:     .byte $90,$F1,$C3,$B1,$00    ; $45 OVERFLOW: 넘침
KEM6:     .byte $A1,$41,$A1,$A1,$9F,$A1,$20,$A6,$81,$B9,$A2,$00    ; $4D OUT OF MEMORY: 메모리 부족
KEM7:     .byte $B4,$F4,$93,$65,$20,$A2,$85,$B8,$77,$00    ; $5A UNDEF'D STATEMENT: 없는 문장
KEM8:     .byte $C0,$F1,$B8,$61,$20,$A4,$F1,$B6,$E1,$00    ; $6B BAD SUBSCRIPT: 첨자 범위
KEM9:     .byte $A4,$81,$B5,$69,$20,$BA,$97,$A5,$A2,$00    ; $78 REDIM'D ARRAY: 배열 중복
KEM10:     .byte $30,$B7,$61,$9D,$A1,$20,$90,$61,$92,$91,$00    ; $85 DIVISION BY ZERO: 0으로 나눔
KEM11:     .byte $BB,$A2,$B8,$F3,$20,$A6,$89,$88,$61,$00    ; $95 ILLEGAL DIRECT: 직접 불가
KEM12:     .byte $D1,$77,$20,$94,$61,$9F,$71,$00    ; $A3 TYPE MISMATCH: 형 다름
KEM13:     .byte $A2,$85,$B8,$61,$B5,$69,$20,$8B,$B1,$00    ; $B0 STRING TOO LONG: 문자열 김
KEM14:     .byte $AF,$A2,$20,$A5,$A2,$B8,$73,$00    ; $BF FORMULA TOO COMPLEX: 식 복잡
KEM15:     .byte $89,$81,$AD,$A2,$20,$A6,$89,$88,$61,$00    ; $D2 CAN'T CONTINUE: 계속 불가
KEM16:     .byte $B4,$F4,$93,$65,$20,$D0,$71,$AE,$81,$00    ; $E0 UNDEF'D FUNCTION: 없는 함수
KEERR:    .byte $20,$B5,$A1,$9F,$41,$00    ; ERROR: ' 오류'
KEIN:    .byte $20,$BA,$89,$20,$00    ; IN: ' 줄 '
KEMT:                       ; key, address of the text: the ROM offset of the first character of a message; $F1 the I of ' IN '; $F2 the space of ' ERROR'
        .byte $00
        .word KEM0
        .byte $10
        .word KEM1
        .byte $16
        .word KEM2
        .byte $2A
        .word KEM3
        .byte $35
        .word KEM4
        .byte $45
        .word KEM5
        .byte $4D
        .word KEM6
        .byte $5A
        .word KEM7
        .byte $6B
        .word KEM8
        .byte $78
        .word KEM9
        .byte $85
        .word KEM10
        .byte $95
        .word KEM11
        .byte $A3
        .word KEM12
        .byte $B0
        .word KEM13
        .byte $BF
        .word KEM14
        .byte $D2
        .word KEM15
        .byte $E0
        .word KEM16
        .byte $F1
        .word KEIN
        .byte $F2
        .word KEERR
KEMTEND = * - KEMT - 3
