; STYPE - the Applesoft "&" command STYPE: like TYPE, but each row of text appears smoothly,
; one pixel row at a time from top to bottom. ca65 source. See STYPE.md.
;
;   BRUN STYPE                         load and install (once)
;   & STYPE,"FILENAME"                 print a DOS text file
;   & STYPE,"FILENAME",5               the same, waiting 5 ms between pixel rows (0 to 255; default 0)
;   & STYPE,"$8000"  or  "A$8000"      print text at a hex address
;   & STYPE,32768                      print text at a decimal address
; (the word may also be quoted: & "STYPE","FILENAME")
;
; The text is N-byte (keystroke) Hangul text as for TYPE. Every row is drawn off screen by the K-HANGEUL
; driver (strip mode) and then copied to the screen one pixel row at a time; see score.inc.
;
; Load address $8A00. BRUN lowers HIMEM to $8A00 so BASIC strings cannot overwrite the code, the strip
; buffer or the two sector buffers ($9200 and $9300). STYPE and TYPE cannot both be loaded.

OUTC      = soutc                ; core.inc prints through this

; Applesoft
CHRGET    = $B1
CHRGOT    = $B7
TXTPTR    = $B8
VALTYP    = $11
FRMEVL    = $DD7B
SYNCHR    = $DEC0
SYNERR    = $DEC9
FRESTR    = $E5FD
GETADR    = $E752
GETBYT    = $E6F8                ; evaluate a byte expression into X
LINNUM    = $50
STRPTR    = $5E
AMPV      = $03F5
HIMEMLO   = $73
FRETOP    = $6F
ERROR     = $D412
OUTOFMEM  = $4D                  ; error offset for ?OUT OF MEMORY

        .segment "CODE"

install:                         ; BRUN starts here
          ldx #6                 ; DOS 3.3 as expected? else leave & alone
:         lda dosbytes,x
          cmp DOSERR,x
          bne installed
          dex
          bpl :-
          lda AMPV+1
          cmp #<amper
          bne :+
          lda AMPV+2
          cmp #>amper
          beq installed          ; already ours
:         lda FRETOP+1           ; the strings must not reach far below HIMEM:
          cmp #$93               ; as TYPE: at most the top 256 bytes of strings may be lost (BRUN early)
          bcc nomem
          lda #<install          ; protect it: HIMEM and the string top move down
          sta HIMEMLO
          sta FRETOP
          lda #>install
          sta HIMEMLO+1
          sta FRETOP+1
          ldx #2
:         lda AMPV,x             ; keep the previous & routine to chain to
          sta old,x
          dex
          bpl :-
          lda #$4C
          sta AMPV
          lda #<amper
          sta AMPV+1
          lda #>amper
          sta AMPV+2
installed:
          rts
nomem:    ldx #OUTOFMEM
          jmp ERROR

; & handler. TXTPTR is just after the &.
amper:
          lda TXTPTR
          sta savetp
          lda TXTPTR+1
          sta savetp+1
          jsr CHRGOT
          cmp #'S'
          beq bare               ; & STYPE,...
          cmp #'"'
          bne chain              ; not ours
          jsr FRMEVL             ; & "TYPE",...
          jsr FRESTR             ; A = length, (STRPTR) = address
          cmp #5
          bne notmine
          ldy #4
:         lda (STRPTR),y
          and #$7F
          cmp word,y
          bne notmine
          dey
          bpl :-
mine:     lda #','
          jsr SYNCHR
          jsr FRMEVL
          bit VALTYP
          bmi string
          jsr GETADR             ; a number: an address
          jmp memory
notmine:  lda savetp             ; not ours: give the line back untouched
          sta TXTPTR
          lda savetp+1
          sta TXTPTR+1
chain:    jmp old                ; the previous & routine

bare:     ldx #0                 ; the word typed as plain letters
:         jsr CHRGOT             ; (spaces are skipped)
          cmp word,x
          bne notmine
          jsr CHRGET
          inx
          cpx #5
          bcc :-
          bcs mine

string:   jsr FRESTR
          beq bad                ; empty name
          cmp #NAMEMAX+1
          bcs bad
          tax                    ; copy the name
          ldy #0
:         lda (STRPTR),y
          and #$7F
          cmp #'a'               ; DOS names are upper case
          bcc :+
          cmp #'z'+1
          bcs :+
          and #$DF
:         ora #$80               ; as the catalog stores it
          sta name,y
          iny
          dex
          bne :--
          sty len
          lda #$A0               ; pad with spaces to 30 characters
:         cpy #NAMEMAX
          bcs :+
          sta name,y
          iny
          bne :-
:         jsr gethex             ; "$8000" or "A$8000" is an address
          bcc memory
          lda #0
          sta inmem
; the optional wait after the name or address: , milliseconds between pixel rows
getwait:  lda #0
          sta delay
          jsr CHRGOT
          cmp #','
          bne run
          jsr CHRGET
          jsr GETBYT
          stx delay
run:      jsr ssetup
          lda inmem
          beq :+
          jsr print
          jmp :++
:         jsr file
:         jmp sfinish
memory:   lda LINNUM
          sta ptr
          lda LINNUM+1
          sta ptr+1
          lda #1
          sta inmem
          jmp getwait
bad:      jmp SYNERR

        .include "core.inc"
        .include "score.inc"

; print the text at ptr up to a $00 byte
print:    jsr clear
next:     lda ptr
          sta $06
          lda ptr+1
          sta $07
          ldy #0
          lda ($06),y
          beq pdone
          inc ptr
          bne :+
          inc ptr+1
:         cmp #$0D
          bne pput
          lda #$8D
pput:     pha
          lda KBDREG             ; Ctrl-C: stop
          cmp #STOPKEY
          bne :+
          bit KBDCLR
          pla
          rts
:         pla
          jsr soutc
          jmp next
pdone:    rts

; name = "$hhhh" or "A$hhhh" (1 to 4 hex digits): value in LINNUM, carry clear
gethex:   ldx #1
          lda name
          and #$7F
          cmp #'$'
          beq gh0
          cmp #'A'
          bne nohex
          lda name+1
          and #$7F
          cmp #'$'
          bne nohex
          inx
gh0:      lda #0
          sta LINNUM
          sta LINNUM+1
          ldy #0
gh1:      lda name,x
          cmp #$A0               ; the padding: the number is over
          beq gh9
          and #$7F
          sec
          sbc #'0'
          bcc nohex
          cmp #10
          bcc gh2
          sbc #7
          cmp #10
          bcc nohex
          cmp #16
          bcs nohex
gh2:      pha
          asl LINNUM
          rol LINNUM+1
          asl LINNUM
          rol LINNUM+1
          asl LINNUM
          rol LINNUM+1
          asl LINNUM
          rol LINNUM+1
          pla
          ora LINNUM
          sta LINNUM
          inx
          iny
          cpx #NAMEMAX
          bcc gh1
gh9:      cpy #1
          bcc nohex
          cpy #5
          bcs nohex
          clc
          rts
nohex:    sec
          rts

word:     .byte "STYPE"
dosbytes: .byte $8D,$5C,$AA,$20,$E6,$BF,$AD     ; STA $AA5C / JSR $BFE6 / LDA $AAB6

old:      .byte 0,0,0
inmem:    .byte 0                ; 1: the text is in memory, 0: in a file
savetp:   .byte 0,0
ptr:      .byte 0,0
