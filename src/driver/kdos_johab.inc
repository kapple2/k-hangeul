; made by src/tools/genkerr.py: do not edit. Korean DOS error messages as johab pairs ($0D, $07 go to COUT), $00 ended.
KSTR1:
        .byte $0D,$07,$0D,$00    ; 0 : CR BELL CR
        .byte $B4,$E5,$B4,$E1,$B4,$F4,$B7,$71,$00    ; 1 LANGUAGE NOT AVAILABLE: 언어없음
        .byte $A4,$F1,$B6,$E1,$20,$B5,$A1,$9F,$41,$00    ; 2 RANGE ERROR: 범위 오류
        .byte $B3,$61,$8B,$A1,$8B,$71,$BB,$A1,$00    ; 4 WRITE PROTECTED: 쓰기금지
        .byte $B8,$61,$9E,$61,$8F,$7B,$00    ; 5 END OF DATA: 자료끝
        .byte $CC,$61,$B7,$A9,$B4,$F4,$B7,$71,$00    ; 6 FILE NOT FOUND: 파일없음
        .byte $A5,$A9,$9F,$51,$94,$61,$9F,$71,$00    ; 7 VOLUME MISMATCH: 볼륨다름
        .byte $B7,$B3,$C2,$89,$9D,$62,$20,$B5,$A1,$9F,$41,$00    ; 8 I/O ERROR: 입출력 오류
        .byte $89,$B7,$88,$65,$A6,$81,$B9,$A2,$00    ; 9 DISK FULL: 공간부족
        .byte $CC,$61,$B7,$A9,$B8,$71,$8B,$B1,$00    ; 10 FILE LOCKED: 파일잠김
        .byte $A2,$85,$A4,$F3,$20,$B5,$A1,$9F,$41,$00    ; 11 SYNTAX ERROR: 문법 오류
        .byte $A4,$E1,$CC,$E1,$A6,$81,$B9,$A2,$00    ; 12 NO BUFFERS AVAILABLE: 버퍼부족
        .byte $D1,$77,$AF,$A2,$94,$61,$9F,$71,$00    ; 13 FILE TYPE MISMATCH: 형식다름
        .byte $B6,$77,$9C,$B7,$C1,$A1,$89,$C1,$00    ; 14 PROGRAM TOO LARGE: 용량초과
        .byte $BB,$A2,$B8,$F3,$A6,$89,$88,$61,$00    ; 15 NOT DIRECT COMMAND: 직접불가
KOFF:                           ; start of the text of message 0..15 in KSTR1
        .byte $00,$04,$0D,$0D,$17,$20,$27,$30,$39,$45,$4E,$57,$61,$6A,$73,$7C
