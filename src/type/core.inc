; core.inc: read a DOS 3.3 text file by its catalog entry and print it. Shared by TYPE
; (the & command) and TYPEC (the command-line program).
;
; To use it: put the file name in `name` (30 characters, upper case, high bit set, padded
; with $A0), then `jsr file`. The text goes through COUT, so the K-HANGEUL driver composes
; the Hangul. Errors are raised through DOS's own error routine.

COUT      = $FDED
                                 ; the routine that prints one byte (A, high bit set): COUT, unless the program
.ifndef OUTC                     ; that includes this file defines its own OUTC first (STYPE, STYPEC)
OUTC      = COUT
.endif

; DOS 3.3
RWTS      = $03D9                ; JSR with Y = low, A = high of the parameter list
LOCRPL    = $03E3                ; returns the RWTS parameter list address in Y/A
DOSERR    = $A6D2                ; DOS's error routine, A = code
E_FNF     = 6                    ; FILE NOT FOUND
E_IO      = 8                    ; I/O ERROR
E_TYPE    = 13                   ; FILE TYPE MISMATCH

; driver compose state, cleared before each text. The driver keeps it in
; main RAM at $9400 (its row $06A8 of the old text page is $949D); see defs.inc in src/driver.
STATE6A8  = $949D                ; was $06A8
HMODE     = STATE6A8+$0F         ; was $06B7

NAMEMAX   = 30
KBDREG    = $C000                ; the keyboard latch: a waiting key has bit 7 set
KBDCLR    = $C010                ; clears it
STOPKEY   = $83                  ; Ctrl-C stops the text
BUF1      = $9200                ; catalog and track/sector list sector
BUF2      = $9300                ; data sector

  
; ---- a DOS text file, read through RWTS ----------------------------------
file:     jsr clear
          jsr LOCRPL             ; DOS's own RWTS parameter list: slot and drive
          sty iob                ; are those of the last disk access
          sta iob+1
          lda #17                ; VTOC: the first catalog sector
          sta trk
          lda #0
          sta sct
          jsr readsec
          lda BUF1+1
          sta trk
          lda BUF1+2
          sta sct
catsec:   jsr readsec
          ldx #$0B               ; seven entries of 35 bytes from offset $0B
entry:    lda BUF1,x
          beq notfound           ; never used: the end of the catalog
          cmp #$FF
          beq nextentry          ; deleted
          clc
          txa
          adc #<BUF1+3
          sta $06
          lda #>BUF1
          adc #0
          sta $07
          ldy #NAMEMAX-1
:         lda ($06),y
          cmp name,y
          bne nextentry
          dey
          bpl :-
          bmi found
nextentry:
          txa
          clc
          adc #35
          tax
          bcc entry
          lda BUF1+1             ; next catalog sector
          beq notfound
          sta trk
          lda BUF1+2
          sta sct
          jmp catsec
notfound: lda #E_FNF
          jmp dosfail
badtype:  lda #E_TYPE
          jmp dosfail

found:    lda BUF1+2,x           ; file type: only text ($00)
          and #$7F
          bne badtype
          lda BUF1,x             ; first track/sector list sector
          sta trk
          lda BUF1+1,x
          sta sct
nextlist: jsr readsec
          lda #$0C
          sta li
dataloop: ldx li
          lda BUF1,x
          beq done               ; no more data sectors
          sta trk
          lda BUF1+1,x
          sta sct
          lda #>BUF2
          sta bufhi
          jsr readsec
          lda #>BUF1
          sta bufhi
          ldy #0
nextbyte: lda BUF2,y
          beq done               ; the first $00 is the end of a text file
          and #$7F               ; the driver wants the plain form: $0B, not $8B
          cmp #$0D
          bne put
          lda #$8D
put:      sty py                 ; COUT may use Y
          pha
          lda KBDREG             ; Ctrl-C: stop. file returns to its caller with nothing else on the stack
          cmp #STOPKEY
          bne :+
          bit KBDCLR
          pla
          rts
:         pla
          jsr OUTC
          ldy py
          iny
          bne nextbyte
          inc li
          inc li
          lda li
          bne dataloop
          lda BUF1+1             ; this list is used up: the next one
          beq done
          sta trk
          lda BUF1+2
          sta sct
          jmp nextlist
done:     rts

; read the sector trk/sct into the page bufhi (RWTS parameter list at iob)
readsec:  lda iob
          sta $06
          lda iob+1
          sta $07
          ldy #3
          lda #0
          sta ($06),y            ; volume: any
          ldy #4
          lda trk
          sta ($06),y
          iny
          lda sct
          sta ($06),y
          ldy #8
          lda #0
          sta ($06),y
          iny
          lda bufhi
          sta ($06),y
          ldy #$0C
          lda #1                 ; read
          sta ($06),y
          ldy iob
          lda iob+1
          jsr RWTS
          bcs rwerr
          rts
rwerr:    lda #E_IO
          jmp dosfail

; Raise DOS error A. DOS's error routine expects to run inside DOS's own I/O
; hook, where the real input and output routines are in $36-$39 (DOS keeps
; them in $AA53-$AA56). Put them there, or its message goes through the hook
; again and overwrites the error number it is printing.
dosfail:  ldx #3
:         ldy $AA53,x
          sty $36,x
          dex
          bpl :-
          jmp DOSERR

clear:    lda #0
          sta HMODE
          sta STATE6A8+$0A
          sta STATE6A8+$11
          sta STATE6A8+$0B
          sta STATE6A8+$0C
          sta STATE6A8+$0D
          sta STATE6A8+$0E
          lda #>BUF1
          sta bufhi
          rts


; variables
iob:      .byte 0,0
trk:      .byte 0
sct:      .byte 0
bufhi:    .byte >BUF1
li:       .byte 0
py:       .byte 0
len:      .byte 0
name:     .res NAMEMAX+1
