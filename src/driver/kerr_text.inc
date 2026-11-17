; made by src/tools/genkerr.py: do not edit (change the texts there). Korean Applesoft error messages, johab pairs, $00 ended.
KEK:    .byte $00,$10,$16,$2A,$35,$45,$4D,$5A,$6B,$78,$85,$95,$A3,$B0,$BF,$D2,$E0,$F1,$F2    ; the key of each text: the ROM offset of the first character of a message; $F1 the I of ' IN '; $F2 the space of ' ERROR'
KEKN = 19
KET:                        ; the texts in the order of the keys, each ended by $00
        .byte $46,$4F,$52,$20,$B4,$F4,$B7,$71,$00    ; $00 FOR 없음
        .byte $A2,$85,$A4,$F3,$00    ; $10 문법
        .byte $47,$4F,$53,$55,$42,$20,$B4,$F4,$B7,$71,$00    ; $16 GOSUB 없음
        .byte $B8,$61,$9E,$61,$20,$8F,$7B,$00    ; $2A 자료 끝
        .byte $A4,$F1,$B6,$E1,$00    ; $35 범위
        .byte $90,$F1,$C3,$B1,$00    ; $45 넘침
        .byte $A1,$41,$A1,$A1,$9F,$A1,$20,$A6,$81,$B9,$A2,$00    ; $4D 메모리 부족
        .byte $BA,$89,$20,$B4,$F4,$B7,$71,$00    ; $5A 줄 없음
        .byte $C0,$F1,$B8,$61,$00    ; $6B 첨자
        .byte $A4,$81,$B5,$69,$20,$BA,$97,$A5,$A2,$00    ; $78 배열 중복
        .byte $30,$B7,$61,$9D,$A1,$20,$90,$61,$92,$91,$00    ; $85 0으로 나눔
        .byte $BB,$A2,$B8,$F3,$20,$A6,$89,$88,$61,$00    ; $95 직접 불가
        .byte $D1,$77,$20,$94,$61,$9F,$71,$00    ; $A3 형 다름
        .byte $A2,$85,$B8,$61,$B5,$69,$20,$8B,$B1,$00    ; $B0 문자열 김
        .byte $AF,$A2,$20,$A5,$A2,$B8,$73,$00    ; $BF 식 복잡
        .byte $89,$81,$AD,$A2,$20,$A6,$89,$88,$61,$00    ; $D2 계속 불가
        .byte $B4,$F4,$93,$65,$20,$D0,$71,$AE,$81,$00    ; $E0 없는 함수
        .byte $20,$BA,$89,$20,$00    ; $F1  줄 
        .byte $20,$B5,$A1,$9F,$41,$00    ; $F2  오류
