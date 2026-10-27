; score.inc: smooth rendering of text, shared by STYPE (the & command) and STYPEC (the command-line program).
;
; The K-HANGEUL driver has a "strip mode" (see LINEX and NLHOOK in src/driver/driver.s). While the byte
; STRIPF is $40 the driver draws the 12 pixel rows of the current text row into a buffer in main RAM
; instead of the screen. Here the bytes of the text are sent to the driver one at a time in strip mode.
; At the end of every text row (carriage return, or the wrap at the right edge) the driver calls `scb`
; first; `scb` shows the finished row on the screen, one pixel row at a time with an optional wait, and
; prepares the strip for the next row. The old text is not scrolled smoothly: the driver scrolls as usual.
;
; Use: define OUTC = soutc before including core.inc, set `delay` (0 = no wait, 1 to 255 = about that many
; milliseconds between pixel rows), call `ssetup`, print the text with `soutc` (or `file` from core.inc),
; then call `sfinish`.

; the driver's state (see src/driver/defs.inc)
STRIPF    = $95DD                ; $40 while the driver draws into the strip (0 otherwise)
STRIPLO   = $95DE                ; where the strip is
STRIPHI   = $95DF
STRIPVEC  = $95E0                ; the routine to call at the end of every row (2 bytes)
YOFFSET   = $94A3                ; vertical offset of the characters, in pixel rows (S_06AE)
CVZ       = $25                  ; cursor row
WNDBTMZ   = $23                  ; first row below the text window
STRIDE    = 42                   ; bytes from one pixel row of the strip to the next

; ssetup: tell the driver where the strip is, and fill the strip with the current screen row.
; The ROM's HOME only writes spaces into the old text page; the driver clears the screen on the next
; character it prints (HOMECK, which looks at $0400). If that is still pending, print a space and
; backspace first, or the strip would be filled with the old screen.
ssetup:   lda $0400
          cmp #$A0
          bne :+
          lda #$A0
          jsr $FDED
          lda #$88
          jsr $FDED
:         lda #<strip
          sta STRIPLO
          lda #>strip
          sta STRIPHI
          lda #<scb
          sta STRIPVEC
          lda #>scb
          sta STRIPVEC+1
          lda #0
          sta dirty
          lda CVZ
          jmp sload

; sfinish: show the last row if anything was printed on it; strip mode off
sfinish:  lda dirty
          beq :+
          jsr sreveal
          lda #0
          sta dirty
:         lda #0
          sta STRIPF
          rts

; soutc: print one byte (A, high bit set) in strip mode. Strip mode is on only while the driver prints,
; so an error from the disk between two bytes cannot leave the screen in strip mode.
soutc:    pha
          cmp #$8D
          beq :+
          lda #1                 ; something other than a carriage return: the row has changed
          sta dirty
:         lda #$40
          sta STRIPF
          pla
          jsr $FDED              ; COUT, to the driver
          lda #0
          sta STRIPF
          rts

; scb: called by the driver in strip mode when a text row ends (the cursor is still on that row).
; The driver does not scroll or move the cursor until this returns.
scb:      ldx #3                 ; keep $06-$09: the driver may be in the middle of a character
:         lda $06,x
          sta zsave,x
          dex
          bpl :-
          lda dirty
          beq @next
          jsr sreveal
          lda #0
          sta dirty
@next:    ldx CVZ                ; the strip for the next row: that row of the screen, or blank when
          inx                    ; the screen is going to scroll
          cpx WNDBTMZ
          bcs @blank
          txa
          jsr sload
          jmp @out
@blank:   jsr szero
@out:     ldx #3
:         lda zsave,x
          sta $06,x
          dex
          bpl :-
          rts

; sload: copy the 12 pixel rows of text row A from the screen into the strip
sload:    jsr ybase
          lda #<strip
          sta $06
          lda #>strip
          sta $07
          lda #12
          sta rc
@row:     lda ycur
          jsr rowaddr
          ldy #39
:         lda ($08),y
          sta ($06),y
          dey
          bpl :-
          jsr nextrow
          dec rc
          bne @row
          rts

; sreveal: copy the strip to the screen (text row CV), one pixel row at a time, waiting `delay` ms after each
sreveal:  lda CVZ
          jsr ybase
          lda #<strip
          sta $06
          lda #>strip
          sta $07
          lda #12
          sta rc
@row:     lda ycur
          jsr rowaddr
          ldy #39
:         lda ($06),y
          sta ($08),y
          dey
          bpl :-
          jsr nextrow
          lda KBDREG             ; Ctrl-C while waiting: no more waits (the key stays for the stop check)
          cmp #STOPKEY
          bne :+
          lda #0
          sta delay
:         ldx delay
          beq @nowait
@ms:      ldy #200               ; about 1000 cycles, a millisecond
:         dey
          bne :-
          dex
          bne @ms
@nowait:  dec rc
          bne @row
          rts

; szero: blank strip
szero:    ldy #0
          tya
:         sta strip,y
          sta strip+256,y
          iny
          bne :-
          rts

; ybase: ycur = pixel row of the first line of text row A (A * 12 plus the driver's vertical offset)
ybase:    sta ycur
          asl a
          asl a
          sta rc                 ; A * 4
          asl a                  ; A * 8
          clc
          adc rc
          clc
          adc YOFFSET
          sta ycur
          rts

; nextrow: next pixel row of the screen, next row of the strip
nextrow:  inc ycur
          lda $06
          clc
          adc #STRIDE
          sta $06
          bcc :+
          inc $07
:         rts

; rowaddr: A = pixel row 0 to 191; $08/$09 = address of its first byte on hi-res page 1:
; $2000 + (y and 7) * $400 + ((y / 8) and 7) * $80 + (y / 64) * 40
rowaddr:  sta ry
          and #$07
          asl a
          asl a
          sta rh
          lda ry
          lsr a
          lsr a
          lsr a
          lsr a
          and #$03
          clc
          adc rh
          adc #$20
          sta $09
          lda ry
          and #$08
          asl a
          asl a
          asl a
          asl a
          sta rl
          lda ry
          lsr a
          lsr a
          lsr a
          lsr a
          lsr a
          lsr a
          tax
          lda mul40,x
          clc
          adc rl
          sta $08
          rts
mul40:    .byte 0,40,80

; variables
delay:    .byte 0                ; wait between pixel rows, in milliseconds
dirty:    .byte 0                ; something was printed on the current row
rc:       .byte 0
ycur:     .byte 0
ry:       .byte 0
rh:       .byte 0
rl:       .byte 0
zsave:    .res 4

          .segment "BSS"
strip:    .res 512               ; 12 pixel rows of 42 bytes (504) of the text row being drawn; 512 for szero
          .segment "CODE"
