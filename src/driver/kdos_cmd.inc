; Korean DOS command names and Hangul-first file names.
; Included twice by driver.s: in the 16K card build (KX = KEXIT, KPUTC = COUT, KGUARD = 1) and, for a Saturn card, in the
; BANK6 segment (scope K6: KX = SatLeave1, KPUTC = the K6PUT stub, KGUARD = 0). See docs/DOS_KOREAN_REPORT.md section 9.
; Korean DOS command names (report section 6). DOS sends every line it does not know to $A000 (a typed line goes on to
; Applesoft, a program line gets DOS's own SYNTAX ERROR). INIT patches $A000 into a jump to KALS (main RAM), which comes here
; with the card on. The line is in $0200; a line from a program has Ctrl-D ($84) at $0200 and the text from $0201. If the text
; is a Hangul run whose first word is one of the names below, that word is replaced in place by DOS's English word, and DOS
; parses the line again from $9FCD. Anything else goes the way the original $A000 code went (KORIG).
; A name is recognised by a 16-bit hash of its keystrokes (everything after the Ctrl-K up to a space, comma, Ctrl-A or Return):
; each key does  h = rotate-left-16(h) xor key. The 28 slots follow DOS's command table at $A884 (INIT, LOAD, SAVE ...), the
; slot number is the number of the command whose English word is read from that table, so the English words cost nothing here.
; An AS IS command (PR#, IN#, FP) has the hash $FFFF. The hashes were checked to be different from each other.
KHLO = $F8                          ; the hash, then (low) the start of the rest of the line when it is moved
KHHI = $F9                          ; the hash, then 2 when "A0 8B" must follow the English word
KBASE = $FA                         ; index in $0200 of the Ctrl-K that starts the Korean word
KWEND = $FB                         ; index of the first byte after the word
KELEN = $FC                         ; length of the English word
KEST = $FD                          ; where the English word starts, as an offset from $A884
KDST = $FE                          ; index where the rest of the line goes
KNSLOT = 28
KAL:
        ldx  #0
        lda  $0200
        cmp  $AAB2                  ; Ctrl-D: the line is from a program
        bne  @1
        inx
@1:     lda  $0200,x
        cmp  #$8B
        beq  @2
        jmp  KORIG
@2:     stx  KBASE
        lda  #0
        sta  KHLO
        sta  KHHI
@h:     inx
        lda  $0200,x
        cmp  #$AC                   ; a comma
        beq  @e
        cmp  #$A1                   ; a space ($A0), Ctrl-A, Return: the word ends
        bcc  @e
        tay
        asl  KHLO                   ; h = rotate-left-16(h) xor key
        rol  KHHI
        bcc  @n
        inc  KHLO
@n:     tya
        eor  KHLO
        sta  KHLO
        jmp  @h
@e:     stx  KWEND
        ldy  #0
@m:     lda  KHASH,y
        cmp  KHLO
        bne  @s
        lda  KHASH+1,y
        cmp  KHHI
        beq  @f
@s:     iny
        iny
        cpy  #KNSLOT*2
        bcc  @m
        jmp  KORIG
@f:     tya                         ; the slot number
        lsr  a
        tax
        ldy  #0
        cpx  #0
        beq  @g
@w:     lda  $A884,y                ; skip the words of DOS's command table before it (a word ends with bit 7 set)
        iny
        asl  a
        bcc  @w
        dex
        bne  @w
@g:     sty  KEST
        lda  #0
        sta  KELEN
@c:     lda  $A884,y                ; the length of the English word
        iny
        inc  KELEN
        asl  a
        bcc  @c
        ldx  KWEND                  ; what follows the Korean word
        lda  #0
        sta  KHHI                   ; (the hash is not needed now) 0 = nothing is added after the English word
        lda  $0200,x
        cmp  #$A0
        bne  @cv
        lda  $0201,x                ; space, then a Hangul key (a jamo letter or a tense key - = * < > ; +): the run goes on
        cmp  #$BB                   ; into a Hangul file name. The English word replaces the Korean one and the space, and
        bcs  @ex                    ; "space, Ctrl-K" follows it so the name keeps its Ctrl-K
        cmp  #$AA
        beq  @ex
        cmp  #$AB
        beq  @ex
        cmp  #$AD
        bne  @cv
@ex:    lda  #2
        sta  KHHI
        bne  @mv
@cv:    lda  $0200,x                ; otherwise the run's closing Ctrl-A is somewhere after the word (the line editor puts it
        cmp  #$8D                   ; before the next letter, or at Return); DOS would stop on it, so make the first one a space
        beq  @mv
        cmp  #$8B
        beq  @mv
        cmp  #$81
        beq  @v1
        inx
        bne  @cv
@v1:    lda  #$A0
        sta  $0200,x
@mv:    ldx  KWEND
        lda  KHHI
        beq  @x1
        inx                         ; the space is replaced too
@x1:    lda  KBASE                  ; where the rest of the line goes: after the English word (and the 2 bytes if any)
        clc
        adc  KELEN
        adc  KHHI
        sta  KDST
        cpx  KDST
        beq  @put
        bcs  @dn
        stx  KHLO                   ; the rest of the line moves up: copy it from the end, back to KHLO
@e1:    lda  $0200,x
        cmp  #$8D
        beq  @e2
        inx
        bne  @e1
@e2:    txa
        sec
        sbc  KHLO
        clc
        adc  KDST
        tay
@u:     lda  $0200,x
        sta  $0200,y
        dex
        dey
        cpx  KHLO
        bcs  @u
        bcc  @put
@dn:    ldy  KDST                   ; the rest of the line moves down: copy it from the front
@d:     lda  $0200,x
        sta  $0200,y
        inx
        iny
        cmp  #$8D
        bne  @d
@put:   ldy  KEST                   ; write the English word as typed keys (bit 7 set)
        ldx  KBASE
@p:     lda  $A884,y
        iny
        ora  #$80
        sta  $0200,x
        inx
        dec  KELEN
        bne  @p
        lda  KHHI
        beq  @ok
        lda  #$A0
        sta  $0200,x
        inx
        lda  #$8B
        sta  $0200,x
@ok:    lda  KBASE                  ; a typed line: DOS gives Applesoft the saved X ($AA5A) as the line length, and Applesoft
        bne  @q                     ; ends the line there; the length changed, so it is the index of the Return now
        tax
@sc:    lda  $0200,x
        cmp  #$8D
        beq  @st
        inx
        bne  @sc
@st:    stx  $AA5A
@q:     lda  #$9F                   ; parse the line again: go on at $9FCD
        ldx  #$CC
        bne  KGO
; the original $A000 code:  lda $0200 / cmp $AAB2 / beq $A00B / jmp $9FA4  (a program line goes to $A00B, a typed one to Applesoft)
KORIG:  lda  $0200
        cmp  $AAB2
        beq  @o
        lda  #$9F
        ldx  #$A3
        bne  KGO
@o:     lda  #$A0
        ldx  #$0A
KGO:    pha                         ; go on at (A,X)+1 with the card off: the address is pushed, KEXIT does the rts
        txa
        pha
        jmp  KX
; DOS's file name check at $A04D (KFN in main RAM) comes here with the card on and A = the first character shifted left.
; Ctrl-K ($8B, a Hangul name) goes on to $A050 (which rotates the carry back in); anything else is a syntax error as before,
; which is the $A000 code above.
KFNC:   cmp  #$16
        beq  @k
        jmp  KAL
@k:     lda  #$A0                   ; go on at $A050: push $A04F, and A must be $16 again (the carry is set by the cmp)
        pha
        lda  #$4F
        pha
        lda  #$16
        jmp  KX
KHASH:
        .word $096E                  ;  0 INIT 포맷
        .word $9788                  ;  1 LOAD 불러오기
        .word $092E                  ;  2 SAVE 저장
        .word $1236                  ;  3 RUN 실행
        .word $116C                  ;  4 CHAIN 연결
        .word $1250                  ;  5 DELETE 지우기
        .word $124B                  ;  6 LOCK 잠금
        .word $0960                  ;  7 UNLOCK 풀기
        .word $0874                  ;  8 CLOSE 닫기
        .word $1050                  ;  9 READ 읽기
        .word $2000                  ; 10 EXEC 일괄
        .word $07BC                  ; 11 WRITE 쓰기
        .word $04D4                  ; 12 POSITION 자리
        .word $0898                  ; 13 OPEN 열기
        .word $429C                  ; 14 APPEND 이어쓰기
        .word $04C0                  ; 15 RENAME 이름바꿈
        .word $106A                  ; 16 CATALOG 목록
        .word $0918                  ; 17 MON 감시
        .word $4B36                  ; 18 NOMON 감시끝
        .word $FFFF                  ; 19 PR# (AS IS)
        .word $FFFF                  ; 20 IN# (AS IS)
        .word $09D7                  ; 21 MAXFILES 최대파일
        .word $FFFF                  ; 22 FP (AS IS)
        .word $10DC                  ; 23 HAN 한글
        .word $0FCF                  ; 24 BSAVE 이진저장
        .word $F998                  ; 25 BLOAD 이진불러오기
        .word $0FD9                  ; 26 BRUN 이진가동
        .word $0917                  ; 27 VERIFY 검사
