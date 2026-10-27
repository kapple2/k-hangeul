; TYPE - the Applesoft "&" command TYPE: print N-byte (keystroke) Hangul text.
; ca65 source. See TYPE.md for the manual.
;
;   BRUN TYPE                          load and install (once)
;   & TYPE,"FILENAME"                  print a DOS text file
;   & TYPE,"$8000"  or  "A$8000"       print text at a hex address
;   & TYPE,32768                       print text at a decimal address
; (the word may also be quoted: & "TYPE","FILENAME")
;
; N-byte text is what the keyboard would produce for Hangul: Ctrl-K ($0B),
; uppercase two-set letters, Ctrl-A ($01). Every byte goes through COUT, so the
; K-HANGEUL driver composes it. Text ends at a $00 byte; in a DOS text file the
; first $00 is the end of the data.
;
; A file is read by this code itself: it looks the name up in the disk catalog
; and reads the sectors with DOS's RWTS. It does not use DOS's OPEN and READ,
; so it also works typed at the ] prompt, and it cannot leave a file open.
;
; Load address $8E00. BRUN lowers HIMEM to $8E00 so BASIC strings cannot overwrite
; the code or its two sector buffers ($9200 and $9300).

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
:         lda FRETOP+1           ; room below the strings for the code and buffers?
          cmp #>(install+$0500)
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
          cmp #'T'
          beq bare               ; & TYPE,...
          cmp #'"'
          bne chain              ; not ours
          jsr FRMEVL             ; & "TYPE",...
          jsr FRESTR             ; A = length, (STRPTR) = address
          cmp #4
          bne notmine
          ldy #3
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
          cpx #4
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
          bcs file
memory:   lda LINNUM
          sta ptr
          lda LINNUM+1
          sta ptr+1
          jmp print
bad:      jmp SYNERR

        .include "core.inc"

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
          jsr COUT
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

word:     .byte "TYPE"
dosbytes: .byte $8D,$5C,$AA,$20,$E6,$BF,$AD     ; STA $AA5C / JSR $BFE6 / LDA $AAB6

old:      .byte 0,0,0
savetp:   .byte 0,0
ptr:      .byte 0,0
