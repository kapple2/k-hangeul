; made by src/tools/genkerr.py: do not edit. Korean DOS error messages as johab pairs ($0D, $07 go to COUT), $00 ended.
KSTR1:
        .byte $0D,$07,$0D,$00    ; 0 : CR BELL CR
        .byte $B4,$E5,$B4,$E1,$20,$B4,$F4,$B7,$71,$00    ; 1 LANGUAGE NOT AVAILABLE: 언어 없음
        .byte $A4,$F1,$B6,$E1,$20,$B5,$A1,$9F,$41,$00    ; 2 RANGE ERROR: 범위 오류
        .byte $B3,$61,$8B,$A1,$20,$8B,$71,$BB,$A1,$96,$51,$00    ; 4 WRITE PROTECTED: 쓰기 금지됨
        .byte $B8,$61,$9E,$61,$20,$8F,$7B,$00    ; 5 END OF DATA: 자료 끝
        .byte $CC,$61,$B7,$A9,$B7,$69,$20,$C0,$78,$B7,$69,$20,$AE,$81,$20,$B4,$F4,$B7,$71,$00    ; 6 FILE NOT FOUND: 파일을 찾을 수 없음
        .byte $A5,$A9,$9F,$51,$20,$A4,$E5,$D1,$A1,$20,$94,$61,$9F,$71,$00    ; 7 VOLUME MISMATCH: 볼륨 번호 다름
        .byte $B7,$B3,$C2,$89,$9D,$62,$20,$B5,$A1,$9F,$41,$00    ; 8 I/O ERROR: 입출력 오류
        .byte $97,$A1,$AF,$61,$C7,$61,$20,$88,$61,$97,$62,$20,$C0,$71,$00    ; 9 DISK FULL: 디스크 가득 참
        .byte $CC,$61,$B7,$A9,$20,$B8,$71,$8B,$B1,$00    ; 10 FILE LOCKED: 파일 잠김
        .byte $A2,$85,$A4,$F3,$20,$B5,$A1,$9F,$41,$00    ; 11 SYNTAX ERROR: 문법 오류
        .byte $A4,$E1,$CC,$E1,$20,$A6,$81,$B9,$A2,$00    ; 12 NO BUFFERS AVAILABLE: 버퍼 부족
        .byte $CC,$61,$B7,$A9,$20,$B9,$B7,$9F,$41,$20,$94,$61,$9F,$71,$00    ; 13 FILE TYPE MISMATCH: 파일 종류 다름
        .byte $CF,$61,$9D,$A1,$8B,$61,$9C,$91,$B7,$A1,$20,$90,$E1,$A2,$81,$20,$C7,$71,$00    ; 14 PROGRAM TOO LARGE: 프로그램이 너무 큼
        .byte $BB,$A2,$B8,$F3,$20,$A1,$77,$9D,$77,$20,$B4,$61,$93,$B1,$00    ; 15 NOT DIRECT COMMAND: 직접 명령 아님
KOFF:                           ; start of the text of message 0..15 in KSTR1
        .byte $00,$04,$0E,$0E,$18,$24,$2C,$40,$4F,$5B,$6A,$74,$7E,$88,$97,$AA
KDOSTEXT = 185
