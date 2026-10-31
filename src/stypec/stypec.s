; STYPEC - the command-line STYPE. Prints a DOS text file of N-byte Hangul text, each row appearing
; smoothly one pixel row at a time from top to bottom.
;
;   BRUN STYPEC           asks  FILE NAME  and prints the file you name; an empty line ends it
;   FILENAME,5            a wait of 5 ms between pixel rows may follow the name (0 to 255; default 0)
;
; It is TYPEC with the strip rendering of score.inc (see docs/STYPE.md), a program of its own: it needs
; nothing installed and leaves nothing behind. Load address $8A00; the two sector buffers are at $9200
; and $9300, so BRUN STYPEC overwrites the top 2.5 KB of BASIC memory: run it from an empty program.

OUTC      = soutc                ; core.inc prints through this

MON_GETLN = $FD6A
PROMPTCH  = $33
INBUF     = $0200
DOSWARM   = $03D0                ; DOS 3.3 warm start

          .segment "CODE"

; The driver's line editor takes the whole screen row as the typed line (it skips only the
; prompt character), so the question goes on a row of its own and the name on the next.
init:     ldx #3                 ; BRUN runs inside DOS's output hook, and a second call of the
:         lda $AA53,x            ; hook would break its saved stack pointer. Use the real input
          sta $36,x              ; and output routines instead (DOS keeps them in $AA53-$AA56).
          dex
          bpl :-
start:    ldx #0
:         lda ask,x
          beq @getline
          ora #$80               ; the characters of ask, then a carriage return
          jsr COUT
          inx
          bne :-
@getline: lda #$DD               ; "]", the prompt the driver draws
          sta PROMPTCH
          jsr MON_GETLN          ; X = length, the text is at $0200 with the high bit set
          txa
          bne @haveit
          jmp quit               ; empty line: finished
@haveit:
          stx len
          lda #0
          sta delay
          ldy #0                 ; "NAME,5": a comma ends the name, a number after it is the wait
@find:    cpy len
          bcs @named
          lda INBUF,y
          and #$7F
          cmp #','
          beq @comma
          iny
          bne @find
@comma:   sty cut
@dig:     iny
          cpy len
          bcs @digits
          lda INBUF,y
          and #$7F
          sec
          sbc #'0'
          cmp #10
          bcs @digits
          sta dig
          lda delay
          asl a
          sta t2
          asl a
          asl a
          clc
          adc t2
          bcs @max
          adc dig
          bcc @set
@max:     lda #255
@set:     sta delay
          jmp @dig
@digits:  ldy cut
          sty len
@named:   ldy #0
:         lda INBUF,y
          and #$7F
          cmp #'a'               ; DOS names are upper case
          bcc @store
          cmp #'z'+1
          bcs @store
          and #$DF
@store:   ora #$80               ; as the catalog stores it
          sta name,y
          iny
          cpy len
          bcs @pad
          cpy #NAMEMAX
          bcc :-
@pad:     lda #$A0               ; pad with spaces to 30 characters
:         cpy #NAMEMAX
          bcs @go
          sta name,y
          iny
          bne :-
@go:      jsr ssetup
          jsr file
          jsr sfinish
          jmp start              ; the next name
quit:     jmp DOSWARM            ; leave through DOS's warm start: it reconnects DOS and
                                 ; prints the ] prompt; we were called from inside DOS's hook

ask:      .byte $0D, "FILE NAME", $0D, 0

          .include "core.inc"
          .include "score.inc"
cut:      .byte 0
dig:      .byte 0
t2:       .byte 0
