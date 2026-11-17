; NPRINT - print N-byte (keystroke) Hangul text from memory.  ca65 source.
;
; N-byte text is what the keyboard would produce: Ctrl-K ($0B) starts a Hangul
; run, uppercase two-set letters spell the syllables, Ctrl-A ($01) ends the
; run. ASCII, digits and punctuation sit outside the run. The text ends at a
; $00 byte. Each byte goes through COUT, so the NEWHANGEUL driver composes it
; exactly as it composes typed keys. Without the driver the bytes are printed
; as plain characters.
;
; Load address $0300 (the free user area, $0300-$03CF; DOS keeps $03D0-$03FF).
;
;   $0300  CALL 768     print the text at the address in $02FE (low) / $02FF (high)
;   $0303  USR entry    X = USR(address): print the text at address
;
; BASIC:
;   BLOAD NPRINT
;   BLOAD MYTEXT,A$8000            : REM binary file, $00 at the end
;   POKE 766,0 : POKE 767,128 : CALL 768
;
;   POKE 10,76 : POKE 11,3 : POKE 12,3   : REM once: USR jumps to $0303
;   X = USR(32768)
;
; Cursor, window and inverse/flash state are whatever BASIC has set. Registers
; are not preserved. On return the pointer in $02FE/$02FF is at the $00 byte.
;
; Zero page: $06/$07 are used as a scratch pointer. The driver also uses them
; while drawing, so the real pointer lives at $02FE/$02FF and is reloaded
; for every byte. $50/$51 are used by the USR entry (ROM GETADR).

PTR       = $02FE
SCRATCH   = $06
COUT      = $FDED
GETADR    = $E752
LINNUM    = $50

; Driver compose state (see MEMORY_LAYOUT.md / progress.md): Hangul mode, the
; pending syllable and its jamo slots. Cleared so text starts clean.
HMODE     = $06B7
STATE0    = $06B2
STATE1    = $06B9
JAMO      = $06B3         ; $06B3-$06B6

          .segment "CODE"

entry_call:
          jmp print       ; $0300
entry_usr:
          jmp usr         ; $0303

usr:
          jsr GETADR      ; FAC -> $50/$51
          lda LINNUM
          sta PTR
          lda LINNUM+1
          sta PTR+1
          ; fall into print

print:
          lda #0
          sta HMODE
          sta STATE0
          sta STATE1
          sta JAMO
          sta JAMO+1
          sta JAMO+2
          sta JAMO+3
next:
          lda PTR
          sta SCRATCH
          lda PTR+1
          sta SCRATCH+1
          ldy #0
          lda (SCRATCH),y
          beq done
          inc PTR
          bne :+
          inc PTR+1
:         cmp #$0D        ; DOS and Applesoft expect CR with the high bit set
          bne put
          lda #$8D
put:      jsr COUT
          jmp next
done:     rts
