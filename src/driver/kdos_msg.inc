; Korean DOS error messages: the routine and the texts.
; Included twice by driver.s: in the 16K card build (KX = KEXIT, KPUTC = COUT, KGUARD = 1) and, for a Saturn card, in the
; BANK6 segment (scope K6: KX = SatLeave1, KPUTC = the K6PUT stub, KGUARD = 0). See docs/DOS_KOREAN_REPORT.md section 9.
KMSGC:                          ; entered from KSTUB with the card on; X = message number; the stack top is the caller's return
.if KGUARD
        jsr  KBACKC                 ; INIT failed (the INIT guard): the patches again
.endif
        lda  CSWH
        cmp  #$94                   ; DOS's output is not the driver's (PR#n): leave the English text
        beq  @k
        lda  #$A7                   ; go on at $A705, the  tax  that DOS's routine runs after  lda $AA3F,x
        pha
        lda  #$04
        pha
        lda  $AA3F,x
        jmp  KX
@k:
.if KGUARD
        lda  KOFF,x                 ; the text is in KSTR1 (johab pairs): KPUTS prints it
        clc
        adc  #<KSTR1
        sta  KPL
        lda  #>KSTR1
        adc  #0
        sta  KPL+1
        jsr  KPUTS
        jmp  KX                     ; leave (card off), then rts to the caller
.else
        ldy  KOFF,x
        cpx  #KMSGK2
        bcs  @b
@a:     lda  KSTR1,y
        beq  @e
        jsr  KPUTC                   ; keeps A, X and Y
        iny
        bne  @a
@e:     jmp  KX                  ; leave (card off), then rts to the caller
@b:     lda  KSTR2,y
        beq  @e
        jsr  KPUTC
        iny
        bne  @b
        beq  @e
.endif

.if !KGUARD
.include "kdos6_text.inc"
.else
.include "kdos_johab.inc"
.endif
