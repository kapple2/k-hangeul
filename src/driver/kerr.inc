; Korean Applesoft error messages (plain 16K card build). Included in driver.s in the KERRRES segment: the file carries it
; behind the banner, and KRC copies it to $1CC0 when the start-up banner has run (the banner's place is free after boot).
; The keys KEK and the texts KET are made by src/tools/genkerr.py (kerr_text.inc); the text of key number n is found by
; counting off n $00 ends.
;
; What the ROM does to print "?UNDEF'D STATEMENT ERROR IN 10" (checked on the Apple II+, II e, IIc ROMs: the same):
;   $D41C "?"                           JSR OUTQUES  (left alone)
;   $D423 the message, one character per JSR OUTDO, X = the offset of that character in the message table at $D260
;   $D431 " ERROR" and the bell         JSR STROUT
;   $D439 " IN " and the line number    JSR $ED19 -> STROUT (only in a program)
; OUTDO's JSR COUT leaves $66 $DB on the stack. KBOUT (the start of COUT) calls KEFILT with the driver's stack as it is
; there: our return, KBOUT's PHA, the return into the output stub $940A, DOS's output hook ($9FAA), then $66 $DB and the
; caller of OUTDO (the message loop, $D425: $25 $D4) or, for STROUT, $4B $DB and STROUT's caller ($D433, $ED1F). Any other
; output has other frames, so it goes on unchanged. No DOS hook in the chain (CSW set to the driver directly) shifts the
; frames: the text then stays English.
; The first character of a message prints the Korean text (looked up by its offset in KEK); the other characters are
; swallowed. " ERROR" prints " 오류" at its space, " IN " prints " 줄 " at its I; the rest of each is swallowed; the digits
; of the line number are not touched.
KEA = $94F8                         ; the character, X and Y, kept while KEFILT works (the dead glyph buffer, free from $94F8)
KEX = $94F9
KEY = $94FA
KERRBASE:
; KEFILT: A = the character, X and Y as COUT got them. Returns A, X and Y as they were; carry set = the character was
; swallowed (the Korean text, or nothing, was printed in its place).
KEFILT:
        sta  KEA
        stx  KEX
        sty  KEY
        tsx
        lda  $0108,x                ; $66 $DB: OUTDO's JSR COUT
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
@pass:  clc                         ; (here, so that every branch to it reaches)
        bcc  @x
@w2:    cmp  #$DB                   ; (A = $010B) the caller of OUTDO must be STROUT's loop ($4B $DB): SPC and TAB (OUTSP, called
        bne  @pass                  ; from $DB35 = $37 $DB) and other output come through here too, and a statement's
        lda  $010A,x                ; return address $D822 is under them: they must not be taken for ?EXTRA IGNORED
        cmp  #$4B
        bne  @pass
        ldy  #3                     ; STROUT's caller (the words at $010C/D) against the four in TH/TL: ED $1F is " IN " (from
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
@g:     ldy  #0                     ; the text is the X'th: count off X ends
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
        jsr  KPUTS
@sw:    sec
@x:     ldx  KEX
        ldy  KEY
        lda  KEA
        rts
TH:     .byte $ED,$D4,$D8,$DB       ; the callers of STROUT: high bytes,
TL:     .byte $1F,$33,$22,$96       ; low bytes,
TC:     .byte $C9,$A0,$D8,$CE       ; the character that gets the Korean text (I of " IN ", space of " ERROR", X of EXTRA, N of REENTER),
TK:     .byte $F1,$F2,$F4,$F5       ; and its key in KEK
; KPUTS: print the $00 ended text at (KPL): johab pairs and ASCII go to PLOTCH (the plot that PACK ends in; a lead byte waits
; for the byte after it). No text has a control character (message 0 of DOS, CR, bell, CR, is left to DOS's own text). A, X and Y
; are not kept.
KPUTS:  ldy  #0
        lda  (KPL),y
        beq  @r
        sta  CHAR
        jsr  PLOTCH
        inc  KPL
        bne  KPUTS
        inc  KPL+1
        bne  KPUTS
@r:     rts
.include "kerr_text.inc"
KERREND:
