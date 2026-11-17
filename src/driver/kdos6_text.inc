; made by src/tools/genkerr.py: do not edit. Korean DOS error messages as keystrokes (Saturn card, bank 6).
KMSGK2 = 16                    ; the first message number whose text is in the second table
KOFF:                           ; start of the Korean text of message 0..15, in KSTR1 or (from KMSGK2 on) KSTR2
        .byte $00,$04,$13,$13,$23,$2F,$39,$48,$56,$69,$77,$85,$95,$A1,$AF,$BD
KSTR1:
        .byte $8D,$87,$8D,$00    ; 0 : CR BELL CR
        .byte $8B,$C4,$CA,$D3,$C4,$CA,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00    ; 1 LANGUAGE NOT AVAILABLE: 언어없음
        .byte $8B,$D1,$CA,$C1,$C4,$CE,$CC,$81,$A0,$8B,$C4,$C8,$C6,$C2,$81,$00    ; 2 RANGE ERROR: 범위 오류
        .byte $8B,$BC,$CD,$D2,$CC,$D2,$CD,$C1,$D7,$CC,$81,$00    ; 4 WRITE PROTECTED: 쓰기금지
        .byte $8B,$D7,$CB,$C6,$D9,$AD,$CD,$D8,$81,$00    ; 5 END OF DATA: 자료끝
        .byte $8B,$D6,$CB,$C4,$CC,$C6,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00    ; 6 FILE NOT FOUND: 파일없음
        .byte $8B,$D1,$C8,$C6,$C6,$C2,$C1,$C5,$CB,$C6,$CD,$C1,$81,$00    ; 7 VOLUME MISMATCH: 볼륨다름
        .byte $8B,$C4,$CC,$D1,$C3,$CE,$C6,$C6,$D5,$D2,$81,$A0,$8B,$C4,$C8,$C6,$C2,$81,$00    ; 8 I/O ERROR: 입출력 오류
        .byte $8B,$D2,$C8,$C4,$D2,$CB,$D3,$D1,$CE,$D7,$C8,$D2,$81,$00    ; 9 DISK FULL: 공간부족
        .byte $8B,$D6,$CB,$C4,$CC,$C6,$D7,$CB,$C1,$D2,$CC,$C1,$81,$00    ; 10 FILE LOCKED: 파일잠김
        .byte $8B,$C1,$CE,$D3,$D1,$CA,$D1,$81,$A0,$8B,$C4,$C8,$C6,$C2,$81,$00    ; 11 SYNTAX ERROR: 문법 오류
        .byte $8B,$D1,$CA,$D6,$CA,$D1,$CE,$D7,$C8,$D2,$81,$00    ; 12 NO BUFFERS AVAILABLE: 버퍼부족
        .byte $8B,$C7,$D5,$C4,$D4,$CC,$D2,$C5,$CB,$C6,$CD,$C1,$81,$00    ; 13 FILE TYPE MISMATCH: 형식다름
        .byte $8B,$C4,$D9,$C4,$C6,$C9,$C4,$C3,$C8,$D2,$C8,$CB,$81,$00    ; 14 PROGRAM TOO LARGE: 용량초과
        .byte $8B,$D7,$CC,$D2,$D7,$CA,$D1,$D1,$CE,$C6,$D2,$CB,$81,$00    ; 15 NOT DIRECT COMMAND: 직접불가
KSTR2:
