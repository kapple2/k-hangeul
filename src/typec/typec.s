; TYPEC - the command-line TYPE. Prints a DOS text file of N-byte Hangul text.
;
;   BRUN TYPEC            asks  FILE NAME  and prints the file you name; an empty line ends it
;
; It is the same reader as the &TYPE command (core.inc) in a program of its own, so it
; needs nothing installed and leaves nothing behind. Load address $8E00; the two sector
; buffers are at $9200 and $9300. See TYPEC.md.

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
          beq quit               ; empty line: finished
          stx len
          ldy #0
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
@go:      jsr file
          jmp start              ; the next name
quit:     jmp DOSWARM            ; leave through DOS's warm start: it reconnects DOS and
                                 ; prints the ] prompt; we were called from inside DOS's hook

ask:      .byte $0D, "FILE NAME", $0D, 0

          .include "core.inc"
