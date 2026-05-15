***************
* Scroller
* A tiny Atari Lynx demo for Outline 2026
* Visual: "OUTLINE2026" scrolls right-to-left in a 4-pixel
*         tall font, following a sine-wave path vertically.
* Assembler: lyxass
***************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
ptr	ds 2		; screen address pointer
scroll	ds 1		; scroll position (0..MAXSCRL-1)
base	ds 1		; draw page high byte ($20/$40)
char_x	ds 1		; current char screen X
wave	ds 1		; wave phase accumulator
cidx	ds 1		; character loop index
row	ds 1		; row counter (4..1)
save_x	ds 1		; temp for X register
save_y	ds 1		; temp for Y register
 END_ZP

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

NUMCHARS equ 11
CHARW	equ 5		; 4 pixel width + 1 pixel gap
MAXSCRL	equ 215		; 160 + 54 + 1

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF

;;; ----------------------------------------
Start::
;;; Zero Suzy math high bytes
	stz	MATHE_C+1
	stz	MATHE_E

	lda	#$20
	sta	base
	stz	scroll

;;; Palette: index 0 = black, index 15 = white
	ldx	#15
.pal
	stz	GREEN0,x
	stz	BLUERED0,x
	dex
	bpl	.pal
	lda	#$0f
	sta	GREEN0+15
	lda	#$ff
	sta	BLUERED0+15

;;;------------------------------
main:
;;;------------------------------
;;; Wait for vertical blank
.vbl
	lda	$fd0a
	bne	.vbl

;;; Swap display / draw pages
	lda	base
	sta	DISPADRH
	eor	#$60
	sta	base

;;; Clear draw page (32 * 256 bytes)
	lda	base
	sta	ptr+1
	stz	ptr
	lda	#0
	ldy	#0
	ldx	#32
.clr
	sta	(ptr),y
	iny
	bne	.clr
	inc	ptr+1
	dex
	bne	.clr

;;; Starting screen X for char 0 = 160 - scroll
	lda	#160
	sec
	sbc	scroll
	sta	char_x

;;; Wave phase starts at scroll value
	lda	scroll
	sta	wave

	stz	cidx

;;; --- Character loop ---
.charloop
;;; Skip if char X off screen (unsigned >= 157 catches both
;;; right-of-screen and wrapped-negative values)
	lda	char_x
	cmp	#157
	bcs	.nextchar

;;; Look up wave Y position from sine table
	lda	wave
	and	#31
	tay
	lda	sine_tbl,y

;;; Row base address = base*256 + Y*80 (Suzy multiply)
	sta	MATHE_C		; Y position
	lda	#80
	sta	MATHE_E+1	; writing E high triggers multiply
	dc.b	$5c,0,0		; WDM: 3-byte NOP for math delay

	lda	MATHE_A+1
	sta	ptr
	lda	MATHE_A+2
	clc
	adc	base
	sta	ptr+1

;;; Font data offset = cidx * 4
	lda	cidx
	asl
	asl
	tax

;;; Draw 4 rows of this character
	lda	#4
	sta	row
.rowloop
	lda	font_data,x
	inx
	stx	save_x		; save font data index
	asl
	asl
	asl
	asl			; pattern now in upper nibble
	ldy	char_x
	ldx	#4		; 4 pixels per row
.bitloop
	asl
	bcc	.nobit
	pha
	jsr	plot
	pla
.nobit
	iny
	dex
	bne	.bitloop

	ldx	save_x		; restore font data index

;;; Advance ptr to next scanline (+80 bytes)
	lda	ptr
	clc
	adc	#80
	sta	ptr
	bcc	.noc
	inc	ptr+1
.noc
	dec	row
	bne	.rowloop

.nextchar
;;; Advance to next character
	lda	char_x
	clc
	adc	#CHARW
	sta	char_x

	lda	wave
	clc
	adc	#3		; phase offset per character
	sta	wave

	inc	cidx
	lda	cidx
	cmp	#NUMCHARS
	bne	.charloop

;;; Advance scroll; reset when text fully off-screen left
	inc	scroll
	lda	scroll
	cmp	#MAXSCRL
	bcc	.noreset
	stz	scroll
.noreset
	jmp	main

;;; ----------------------------------------
;;; Plot one pixel at column Y in current row (ptr).
;;; Colour = palette index $F (white).
;;; Preserves Y; destroys A.
plot:
	tya
	lsr			; byte offset = col/2, C = odd pixel
	sty	save_y
	tay
	lda	#$f0		; even pixel: high nibble
	bcc	.ev
	lda	#$0f		; odd pixel: low nibble
.ev
	ora	(ptr),y
	sta	(ptr),y
	ldy	save_y
	rts

;;; ----------------------------------------
;;; 4x4 pixel font for "OUTLINE2026"
;;; Bits 3..0 = pixels left to right
font_data:
	dc.b %0110,%1001,%1001,%0110	; O
	dc.b %1001,%1001,%1001,%0110	; U
	dc.b %1110,%0100,%0100,%0100	; T
	dc.b %1000,%1000,%1000,%1110	; L
	dc.b %0100,%0100,%0100,%0100	; I
	dc.b %1001,%1101,%1011,%1001	; N
	dc.b %1110,%1000,%1100,%1110	; E
	dc.b %1110,%0010,%0100,%1110	; 2
	dc.b %0110,%1001,%1001,%0110	; 0
	dc.b %1110,%0010,%0100,%1110	; 2
	dc.b %0110,%1000,%1110,%0110	; 6

;;; 32-entry sine table  (Y positions, amplitude +/-32, centre 49)
sine_tbl:
	dc.b 49,55,61,66,71,75,78,80
	dc.b 81,80,78,75,71,66,61,55
	dc.b 49,43,37,32,27,23,20,18
	dc.b 17,18,20,23,27,32,37,43

End:

;;; ----------------------------------------
 IFND LNX
	dc.b 0
 ENDIF

 IFND LNX
	include "bll_init.inc"
 ENDIF
	echo "Size: %d (End-Start)"
