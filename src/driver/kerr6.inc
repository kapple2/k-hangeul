; Korean Applesoft error messages, Saturn card: the code and the keystroke text are in bank 6, page 1 (scope K6, segment BANK6).
; Same idea as kerr.inc (read it first): KBOUT in the driver (bank 7) does  jsr K6FN  (the stub at $951A, which also serves DOS's
; file name check). K6FN is  jsr K6IN / jmp KDISP: bank 6 is mapped, SatDepth6 counted, and the stack is as kerr.inc's KEFILT
; finds it, because the entry stub $940A is the same in both arrangements. The code returns to the driver (bank 7, page 2,
; card write enabled) by  jmp SatEnter  (its rts goes to KBOUT, or, when the character was swallowed, to the output stub: the
; return into KBOUT and the pushed A are dropped first), after two  dec SatDepth6  (K6IN's count and SatEnter's).
; The text is printed through K6PUT, like the Korean DOS messages. The texts are counted off by their $00 ends: KEK is
; their keys, in the same order (kerr6_text.inc).
SatEnter6 = $95EE                   ; SatEnter (SATR3 + 11): driver.s asserts it
SatDepth6 = $9511                   ; SATDEPTH
KDISP:  sta  KEA
        stx  KEX
        tsx
        lda  $0102,x                ; the return address: the high byte is $D1 for KBOUT, DOS's is not
        cmp  #$D1
        beq  @e
        lda  KEA
        ldx  KEX
        jmp  KFNC                   ; DOS's file name check
@pass:  ldx  KEX
        lda  KEA
        dec  SatDepth6
        dec  SatDepth6
        jmp  SatEnter6
@e:     lda  $0108,x                ; $66 $DB: OUTDO's JSR COUT
        cmp  #$66
        bne  @pass
        lda  $0109,x
        cmp  #$DB
        bne  @pass
        lda  $010B,x                ; the caller of OUTDO, high byte
        cmp  #$D4
        bne  @w2
        lda  $010A,x
        cmp  #$25                   ; the message loop at $D425
        bne  @pass
        lda  KEX                    ; the key is the table offset of this character (the carry is set: cmp equal)
        bcs  @look
@w2:    lda  $010D,x                ; STROUT's caller: ED $1F is " IN " (from $ED19), D4 $33 is " ERROR" (from $D431)
        cmp  #$ED
        bne  @d4
        lda  $010C,x
        cmp  #$1F
        bne  @pass
        ldx  #$F1
        lda  #$C9                   ; the I
        bne  @t
@d4:    cmp  #$D4
        bne  @pass
        lda  $010C,x
        cmp  #$33
        bne  @pass
        lda  KEA
        cmp  #$87                   ; the bell stays the ROM's
        beq  @pass
        ldx  #$F2
        lda  #$A0                   ; the space
@t:     cmp  KEA
        beq  @k
        ldx  #$FF                   ; another character of it: no text, swallow
@k:     txa
@look:  sty  KEY
        ldx  #KEKN-1
@m:     cmp  KEK,x
        beq  @g
        dex
        bpl  @m
        bmi  @sw
@g:     lda  KEX                    ; the printing calls COUT, which comes back through here for every character and
        pha                         ; overwrites KEA and KEX: keep the X of the ROM on the stack meanwhile
        ldy  #0                     ; the text is the X'th: count off X ends
@w:     dex
        bmi  @p
@s:     iny
        lda  KET-1,y
        bne  @s
        beq  @w
@p:     tya
        clc
        adc  #<KET
        sta  KPL
        lda  #>KET
        adc  #0
        sta  KPL+1
        ldy  #0
@o:     lda  (KPL),y
        beq  @r
        jsr  KPUTC                  ; keeps A, X and Y
        iny
        bne  @o
@r:     pla
        sta  KEX
        ldy  KEY
@sw:    pla                         ; swallowed: drop the return into KBOUT, take the character, leave for the output stub
        pla
        pla
        ldx  KEX
        dec  SatDepth6
        dec  SatDepth6
        jmp  SatEnter6
.include "kerr6_text.inc"
