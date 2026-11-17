; made by src/tools/genkerr.py: do not edit. Korean Applesoft error messages as keystroke text (Saturn card, bank 6).
KEK:    .byte $00,$10,$16,$2A,$35,$45,$4D,$5A,$6B,$78,$85,$95,$A3,$B0,$BF,$D2,$E0,$F1,$F2
KEKN = 19
KET:
        .byte $C6,$CF,$D2,$A0,$8B,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00    ; $00 FOR 없음
        .byte $8B,$C1,$CE,$D3,$D1,$CA,$D1,$81,$00    ; $10 문법
        .byte $C7,$CF,$D3,$D5,$C2,$A0,$8B,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00    ; $16 GOSUB 없음
        .byte $8B,$D7,$CB,$C6,$D9,$81,$A0,$8B,$AD,$CD,$D8,$81,$00    ; $2A 자료 끝
        .byte $8B,$D1,$CA,$C1,$C4,$CE,$CC,$81,$00    ; $35 범위
        .byte $8B,$D3,$CA,$C1,$C3,$CC,$C1,$81,$00    ; $45 넘침
        .byte $8B,$C1,$D0,$C1,$C8,$C6,$CC,$81,$A0,$8B,$D1,$CE,$D7,$C8,$D2,$81,$00    ; $4D 메모리 부족
        .byte $8B,$D7,$CE,$C6,$81,$A0,$8B,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00    ; $5A 줄 없음
        .byte $8B,$C3,$CA,$C1,$D7,$CB,$81,$00    ; $6B 첨자
        .byte $8B,$D1,$CF,$C4,$D5,$C6,$81,$A0,$8B,$D7,$CE,$C4,$D1,$C8,$D2,$81,$00    ; $78 배열 중복
        .byte $B0,$8B,$C4,$CD,$C6,$C8,$81,$A0,$8B,$D3,$CB,$D3,$CE,$C1,$81,$00    ; $85 0으로 나눔
        .byte $8B,$D7,$CC,$D2,$D7,$CA,$D1,$81,$A0,$8B,$D1,$CE,$C6,$D2,$CB,$81,$00    ; $95 직접 불가
        .byte $8B,$C7,$D5,$C4,$81,$A0,$8B,$C5,$CB,$C6,$CD,$C1,$81,$00    ; $A3 형 다름
        .byte $8B,$C1,$CE,$D3,$D7,$CB,$C4,$D5,$C6,$81,$A0,$8B,$D2,$CC,$C1,$81,$00    ; $B0 문자열 김
        .byte $8B,$D4,$CC,$D2,$81,$A0,$8B,$D1,$C8,$D2,$D7,$CB,$D1,$81,$00    ; $BF 식 복잡
        .byte $8B,$D2,$AB,$D4,$C8,$D2,$81,$A0,$8B,$D1,$CE,$C6,$D2,$CB,$81,$00    ; $D2 계속 불가
        .byte $8B,$C4,$CA,$D1,$D4,$D3,$CD,$D3,$81,$A0,$8B,$C7,$CB,$C1,$D4,$CE,$81,$00    ; $E0 없는 함수
        .byte $A0,$8B,$D7,$CE,$C6,$81,$A0,$00    ; $F1  줄 
        .byte $A0,$8B,$C4,$C8,$C6,$C2,$81,$00    ; $F2  오류
