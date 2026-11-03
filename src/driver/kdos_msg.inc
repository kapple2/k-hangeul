; Korean DOS error messages: the routine and the texts.
; Included twice by driver.s: in the 16K card build (KX = KEXIT, KPUTC = COUT, KGUARD = 1) and, for a Saturn card, in the
; BANK6 segment (scope K6: KX = SatLeave1, KPUTC = the K6PUT stub, KGUARD = 0). See docs/DOS_KOREAN_REPORT.md section 9.
KMSGC:                          ; entered from KSTUB with the card on; X = message number; the stack top is the caller's return
.if KGUARD
        jsr  KBACKC                 ; INIT failed (the INIT guard): the patches again
.endif
        lda  CSWH
        cmp  #$94                   ; DOS's output is not the driver's (PR#n): leave the English text
        beq  @k
        lda  #$A7                   ; go on at $A705, the  tax  that DOS's routine runs after  lda $AA3F,x
        pha
        lda  #$04
        pha
        lda  $AA3F,x
        jmp  KX
@k:     ldy  KOFF,x
        cpx  #KMSGK2
        bcs  @b
@a:     lda  KSTR1,y
        beq  @e
        jsr  KPUTC                   ; keeps A, X and Y
        iny
        bne  @a
@e:     jmp  KX                  ; leave (card off), then rts to the caller
@b:     lda  KSTR2,y
        beq  @e
        jsr  KPUTC
        iny
        bne  @b
        beq  @e

KMSGK2 = 14                    ; the first message number whose text is in the second table
KOFF:                           ; start of the Korean text of message 0..15, in KSTR1 or (from KMSGK2 on) KSTR2
        .byte $00,$04,$24,$24,$34,$47,$56,$68,$81,$94,$AB,$BC,$CC,$DB,$00,$1B
KSTR1:
        .byte $8D,$87,$8D,$00   ; 0 CR BELL CR: (CR, bell, CR)
        .byte $8B,$C4,$CA,$D3,$C4,$CA,$C6,$CD,$C6,$81,$A0,$8B,$BC,$CD,$C6,$81,$A0,$8B,$D4,$CE,$81,$A0,$8B,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00   ; 1 LANGUAGE NOT AVAILABLE: 언어를 쓸 수 없음
        .byte $8B,$D1,$CA,$C1,$C4,$CE,$CC,$81,$A0,$8B,$C4,$C8,$C6,$C2,$81,$00   ; 2 RANGE ERROR: 범위 오류
        .byte $8B,$BC,$CD,$D2,$CC,$81,$A0,$8B,$D2,$CD,$C1,$D7,$CC,$C5,$C8,$CC,$C1,$81,$00   ; 4 WRITE PROTECTED: 쓰기 금지됨
        .byte $8B,$C5,$D0,$C4,$CC,$D8,$CA,$81,$A0,$8B,$AD,$CD,$D8,$81,$00   ; 5 END OF DATA: 데이터 끝
        .byte $8B,$D6,$CB,$C4,$CC,$C6,$81,$A0,$8B,$C4,$CA,$D1,$D4,$C4,$CD,$C1,$81,$00   ; 6 FILE NOT FOUND: 파일 없음
        .byte $8B,$D1,$C8,$C6,$C6,$C2,$C1,$81,$A0,$8B,$D1,$CA,$D3,$C7,$C8,$81,$A0,$8B,$C5,$CB,$C6,$CD,$C1,$81,$00   ; 7 VOLUME MISMATCH: 볼륨 번호 다름
        .byte $8B,$C4,$CC,$D1,$C3,$CE,$C6,$C6,$D5,$D2,$81,$A0,$8B,$C4,$C8,$C6,$C2,$81,$00   ; 8 I/O ERROR: 입출력 오류
        .byte $8B,$C5,$CC,$D4,$CD,$DA,$CD,$81,$A0,$8B,$D2,$CB,$C5,$CD,$D2,$81,$A0,$8B,$C3,$CB,$C1,$81,$00   ; 9 DISK FULL: 디스크 가득 참
        .byte $8B,$D6,$CB,$C4,$CC,$C6,$81,$A0,$8B,$D7,$CB,$C1,$D2,$CC,$C1,$81,$00   ; 10 FILE LOCKED: 파일 잠김
        .byte $8B,$C1,$CE,$D3,$D1,$CA,$D1,$81,$A0,$8B,$C4,$C8,$C6,$C2,$81,$00   ; 11 SYNTAX ERROR: 문법 오류
        .byte $8B,$D1,$CA,$D6,$CA,$81,$A0,$8B,$D1,$CE,$D7,$C8,$D2,$81,$00   ; 12 NO BUFFERS AVAILABLE: 버퍼 부족
        .byte $8B,$D6,$CB,$C4,$CC,$C6,$81,$A0,$8B,$D7,$C8,$C4,$C6,$C2,$81,$A0,$8B,$C5,$CB,$C6,$CD,$C1,$81,$00   ; 13 FILE TYPE MISMATCH: 파일 종류 다름
KSTR2:
        .byte $8B,$D6,$CD,$C6,$C8,$D2,$CD,$C6,$CF,$C1,$C4,$CC,$81,$A0,$8B,$D3,$CA,$C1,$CE,$81,$A0,$8B,$DA,$CD,$C1,$81,$00   ; 14 PROGRAM TOO LARGE: 프로그램이 너무 큼
        .byte $8B,$D7,$CC,$D2,$D7,$CA,$D1,$81,$A0,$8B,$C1,$D5,$C4,$C6,$D5,$C4,$81,$A0,$8B,$C4,$CB,$D3,$CC,$C1,$81,$00   ; 15 NOT DIRECT COMMAND: 직접 명령 아님
