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
        sty  KEY
        tsx
        lda  $0102,x                ; the return address: the high byte is $D1 for KBOUT, DOS's is not
        cmp  #$D1
        beq  @e
        lda  KEA
        ldx  KEX
        jmp  KFNC                   ; DOS's file name check
@pass:  ldx  KEX
        ldy  KEY
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
@w2:    ldy  #3                     ; STROUT's caller (the words at $010C/D) against the four in TH/TL: ED $1F is " IN " (from
@l:     lda  $010D,x                ; $ED19), D4 $33 is " ERROR" and BREAK (from $D431), D8 $22 is ?EXTRA IGNORED (the INPUT
        cmp  TH,y                   ; handler's caller, NEWSTT), DB $96 is ?REENTER (from $DB94)
        bne  @n
        lda  $010C,x
        cmp  TL,y
        beq  @h
@n:     dey
        bpl  @l
        bmi  @pass
@h:     lda  KEA
        cmp  #$87                   ; the bell after " ERROR" and the CR before BREAK or after ?EXTRA IGNORED are the ROM's:
        beq  @pass                  ; they go on (COUT called from here with a control character did not come back)
        cmp  #$8D
        beq  @pass
        cmp  #$BF                   ; the ? of the INPUT messages (and of INPUT's prompt, which has the same caller as ?EXTRA IGNORED)
        beq  @pass
        ldx  #$F3                   ; the key of the text for BREAK, if this is the B (STOP and Ctrl-C come through here too)
        cmp  #$C2
        beq  @k
        ldx  TK,y                   ; the key of the text of this caller, if this is the character in TC (the I, the space, the X, the N)
        cmp  TC,y
        beq  @k
        ldx  #$FF                   ; another character of it: no text, swallow
@k:     txa
@look:
        ldx  #KEKN-1
@m:     cmp  KEK,x
        beq  @g
        dex
        bpl  @m
        bmi  @sw
@g:     lda  KEX                    ; the printing calls COUT, which comes back through here for every character and
        pha                         ; overwrites KEA, KEX and KEY: keep the X and Y of the ROM on the stack meanwhile
        lda  KEY
        pha
        lda  #<KET                  ; the text is the X'th: count off X ends (the table is longer than 256 bytes)
        sta  KPL
        lda  #>KET
        sta  KPL+1
        ldy  #0
@w:     dex
        bmi  @o
@s:     lda  (KPL),y
        beq  @z
        inc  KPL
        bne  @s
        inc  KPL+1
        bne  @s
@z:     inc  KPL
        bne  @w
        inc  KPL+1
        bne  @w
@o:     lda  (KPL),y
        beq  @r
        jsr  KPUTC                  ; keeps A, X and Y
        iny
        bne  @o
@r:     pla
        sta  KEY
        pla
        sta  KEX
@sw:    pla                         ; swallowed: drop the return into KBOUT, take the character, leave for the output stub
        pla
        pla
        ldx  KEX
        ldy  KEY
        dec  SatDepth6
        dec  SatDepth6
        jmp  SatEnter6
TH:     .byte $ED,$D4,$D8,$DB       ; the callers of STROUT: high bytes,
TL:     .byte $1F,$33,$22,$96       ; low bytes,
TC:     .byte $C9,$A0,$D8,$CE       ; the character that gets the Korean text (I of " IN ", space of " ERROR", X of EXTRA, N of REENTER),
TK:     .byte $F1,$F2,$F4,$F5       ; and its key in KEK
.include "kerr6_text.inc"
