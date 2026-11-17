; The INIT guard for the Saturn card (scope K6, bank 6, page 1). The same idea as the 16K card's (driver.s, "The INIT guard"; the
; DOS patch table is in docs/DOS_PATCHES.md): DOS's INIT writes the DOS in memory to the new disk, so while INIT runs the driver's
; patches are exchanged with the stock bytes kept here (KSWT), and exchanged back when INIT is over. A disk made this way boots
; plain DOS 3.3 without the driver.
;   K6GD ($BCF9, main RAM, in DOS's unused bytes) is DOS's handler for INIT (the table entry at $9D1E, written by KPATCH6):
;        jsr K6IN / jmp KGD.
;   KGD  tells the two ways in apart by the top of the stack. A fresh INIT: DOS's return address. When INIT has run: the word
;        $0000 that KGD pushed under INIT's return (no return address is $0000).
;        Fresh: KBACKC (a failed INIT may have left DOS stock), KSWAP (DOS is stock now), push $0000, K6GD-1 (INIT's handler
;        returns to the stub) and DOS's INIT ($A54E), and leave: the rts goes to INIT.
;        After INIT: drop the $0000, KBACKC (swap the patches back), leave: the rts goes to what called INIT's handler.
;   KBACKC (also called by the message code, KMSGC, so that a failed INIT's message finds the patches in) swaps back if DOS is
;        stock (KSWF = KSWON). A, X, Y and the flags are kept.
; $A702, the message routine, is not swapped: on a new disk it is  jsr K6MSG  and K6MSG only goes into bank 6 while DOS's output
; is the driver's, so the disk works without the driver (the same reason as KSTUBD on the 16K card).
KSWON = $5A                         ; KSWF = KSWON: DOS is stock now (any other value: the patches are in)
KGD:    tsx
        lda  $0102,x                ; the high byte of the return address on top of the stack: DOS's are below $C0, the driver's
        cmp  #$D0                   ; (KPATCH6 calls K6GD, the same stub) are not: then it is a call to patch DOS
        bcc  @d
        jmp  KPAT
@d:     lda  $0101,x
        ora  $0102,x
        beq  @post                  ; $0000 on top: INIT has run
        jsr  KBACKC
        jsr  KSWAP
        lda  #$00                   ; the marker
        pha
        pha
        lda  #>(K6GD-1)             ; INIT's handler returns to the stub
        pha
        lda  #<(K6GD-1)
        pha
        lda  #$A5                   ; DOS's INIT handler, at $A54F
        pha
        lda  #$4E
        pha
        jmp  KX
@post:  pla
        pla
        jsr  KBACKC
        jmp  KX
KBACKC: php
        pha
        txa
        pha
        tya
        pha
        lda  KSWF
        cmp  #KSWON
        bne  @x
        jsr  KSWAP
@x:     pla
        tay
        pla
        tax
        pla
        plp
        rts
; exchange each range of DOS with KSWT (this page is made writable for it). Entries never cross a page.
KSWAP:  bit  $C08B                  ; RAM read, write enabled (page 1)
        bit  $C08B
        ldx  #0
@e:     ldy  KSWT+2,x               ; the length; 0 ends the table
        beq  @d
        lda  KSWT,x
        sta  @m+1
        sta  @w+1
        lda  KSWT+1,x
        sta  @m+2
        sta  @w+2
        inx
        inx
        inx
@l:     lda  KSWT,x
        pha
@m:     lda  $FFFF                  ; operand set above
        sta  KSWT,x
        pla
@w:     sta  $FFFF
        inc  @m+1
        inc  @w+1
        inx
        dey
        bne  @l
        beq  @e
@d:     lda  KSWF                   ; stock <-> patched
        eor  #KSWON
        sta  KSWF
        bit  $C088                  ; write protected again
        rts
; address, length, then the bytes that are not in DOS now (stock bytes while the patches are in; the patches while INIT runs)
KSWT:   .byte <$A000,>$A000,3, $AD,$00,$02          ; the command names (K6AL)
        .byte <$A04E,>$A04E,2, $00,$A0              ; file names (K6FN)
        .byte <$A59E,>$A59E,9, $A9,$20,$20,$B2,$A5,$F0,$05,$A9,$01   ; HAN in the slot of INT, and the reset stub behind it
        .byte <$A8F1,>$A8F1,3, $49,$4E,$D4          ; its name, "INT"
        .byte <$ADA3,>$ADA3,5, $A9,$16,$8D,$9D,$B3  ; CATALOG: CATINIT
        .byte <$ADAF,>$ADAF,1, $0B                  ; CATALOG header length
        .byte <$AE3A,>$AE3A,4, $0C,$FD,$A9,$15      ; CATALOG: CATWAIT and the page length
        .byte <$B3B0,>$B3B0,8, $C5,$CD,$D5,$CC,$CF,$D6,$A0,$CB   ; CATALOG header text
        .byte <$9D1E,>$9D1E,2, $4E,$A5              ; INIT's handler (the guard)
        .byte 0,0,0
KSWF:   .byte 0                     ; KSWON while DOS is stock (INIT is running)
; The Korean DOS patches, like KPATCH of the 16K card build; each one only if DOS has the stock bytes there. Called by KPATCH6 (driver.s,
; in bank 7) through K6GD (it keeps that block small): leave for the driver as KDISP does.
KPAT:   lda  $A702                  ; messages: lda $AA3F,x / tax (the first byte is checked): jsr K6MSG instead
        cmp  #$BD
        bne  @f
        lda  #$20
        sta  $A702
        lda  #<K6MSG
        sta  $A703
        lda  #>K6MSG
        sta  $A704
@f:     lda  $A04F                  ; file names: jmp $A000 at $A04D
        cmp  #$A0
        bne  @a
        lda  #<K6FN
        sta  $A04E
        lda  #>K6FN
        sta  $A04F
@a:     lda  $A000                  ; command names: lda $0200 at $A000
        cmp  #$AD
        bne  @h
        lda  #$4C
        sta  $A000
        lda  #<K6AL
        sta  $A001
        lda  #>K6AL
        sta  $A002
@h:     lda  $ADAF                  ; the CATALOG header, as in KPATCH
        cmp  #$0B
        bne  @i
        lda  $B3AF
        cmp  #$A0
        bne  @i
        lda  #$08
        sta  $ADAF
        ldx  #$08
@hc:    lda  KHDR6,x
        sta  $B3AF,x
        dex
        bpl  @hc
@i:     lda  $9D1F                  ; the INIT guard: DOS's handler table entry for INIT (address - 1, $A54E)
        cmp  #$A5
        bne  @x                     ; not stock, or the guard already (HAN again): leave it
        lda  #<(K6GD-1)
        sta  $9D1E
        lda  #>(K6GD-1)
        sta  $9D1F
@x:     dec  SatDepth6              ; K6IN's count and SatEnter's, as KDISP does
        dec  SatDepth6
        jmp  SatEnter6
KHDR6:  .byte $A0,$81,$C1,$C2,$C6,$C6,$C8,$D1,$8B
