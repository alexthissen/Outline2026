***************
* Oscillator
* A tiny Atari Lynx demo for Outline 2026
* Visual: 128 dots in a harmonic oscillator orbit.
*         Each frame: x += y/2, y -= x/2 (approximate
*         rotation). Dots swirl in a vortex pattern,
*         colors cycle with time for a pulsing look.
* Author: GitHub Copilot (in the spirit of 42Bastian)
* Assembler: lyxass
***************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
ptr	ds 2		; screen address pointer
frame	ds 1		; frame/time counter
base	ds 1		; draw page high byte ($20 or $40)
sx	ds 1		; screen X coordinate
idx	ds 1		; saved loop index
 END_ZP

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

NUMDOTS	equ 128
CENTERX	equ 80
CENTERY	equ 51

dot_x	equ $0400	; signed X offsets (128 bytes)
dot_y	equ $0500	; signed Y offsets (128 bytes)

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF

;;; ----------------------------------------
Start::
;;; Zero Suzy math high bytes for multiply
	stz	MATHE_C+1
	stz	MATHE_E

;;; Initialize 128 dots in a 16x8 grid
;;; x[i] = (i & 15) * 4 - 32   range: -32..28
;;; y[i] = (i >> 4) * 4 - 16   range: -16..12
	ldx	#NUMDOTS-1
.initdot
	txa
	and	#15
	asl
	asl
	sec
	sbc	#32
	sta	dot_x,x

	txa
	lsr
	lsr
	lsr
	lsr
	asl
	asl
	sec
	sbc	#16
	sta	dot_y,x

	dex
	bpl	.initdot

;;; Set up rainbow palette for colorful cycling
	ldx	#15
.pal
	lda	pal_green,x
	sta	GREEN0,x
	lda	pal_bluered,x
	sta	BLUERED0,x
	dex
	bpl	.pal

	lda	#$20
	sta	base
	stz	frame

;;;------------------------------
main:
;;;------------------------------
;;; Wait for vertical blank
.vbl
	lda	$fd0a
	bne	.vbl

;;; Swap display/draw pages
	lda	base
	sta	$fd95		; display the completed page
	eor	#$60		; toggle $20 <-> $40
	sta	base		; next frame draws to other page

;;; Clear the draw page (32 * 256 = 8192 bytes >= 8160 needed)
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

;;; Update and plot all dots
	ldx	#NUMDOTS-1
.dot
	stx	idx		; save loop counter

;;; ---- Oscillator update ----
;;; x' = x + y/2 (signed arithmetic shift right)
	lda	dot_y,x
	cmp	#$80		; carry = sign bit
	ror			; arithmetic shift right = signed /2
	clc
	adc	dot_x,x
	sta	dot_x,x		; x' = x + y/2

;;; y' = y - x'/2 (using updated x)
	cmp	#$80
	ror			; signed x'/2
	eor	#$ff		; negate
	sec
	adc	dot_y,x
	sta	dot_y,x		; y' = y - x'/2

;;; ---- Clip & compute screen coords ----
;;; screen_x = x' + 80 (unsigned compare catches < 0 and >= 160)
	lda	dot_x,x
	clc
	adc	#CENTERX
	cmp	#160
	bcs	.skip
	sta	sx

;;; screen_y = y' + 51 (unsigned compare catches < 0 and >= 102)
	lda	dot_y,x
	clc
	adc	#CENTERY
	cmp	#102
	bcs	.skip

;;; ---- Compute row address via Suzy multiply ----
;;; ptr = base*256 + screen_y * 80
	sta	MATHE_C		; screen_y (0..101)
	lda	#80
	sta	MATHE_E+1	; 80 in high byte triggers multiply
	dc.b	$5c,0,0		; WDM: 3-byte NOP, ~8 cycle delay

	lda	MATHE_A+1	; low byte of y*80
	sta	ptr
	lda	MATHE_A+2	; high byte of y*80
	clc
	adc	base
	sta	ptr+1

;;; ---- Plot pixel ----
;;; Compute byte offset and nibble position
	lda	sx
	lsr			; byte offset = sx / 2, carry = odd pixel
	tay
	php			; save carry (odd/even flag)

;;; Color = (dot_index + frame) & 15
	lda	idx
	clc
	adc	frame
	and	#$0f

	plp			; restore carry
	bcs	.odd
;;; Even pixel: color in high nibble
	asl
	asl
	asl
	asl
.odd
;;; Odd pixel: color already in low nibble
	ora	(ptr),y
	sta	(ptr),y

.skip
	ldx	idx
	dex
	bpl	.dot

	inc	frame
	jmp	main

;;; ----------------------------------------
;;; 16-entry hue ramp palette
pal_green:
	dc.b $0,$2,$5,$8,$b,$f,$f,$f,$f,$f,$b,$8,$5,$2,$0,$0
pal_bluered:
	dc.b $00,$1d,$2b,$39,$47,$55,$63,$71,$17,$35,$53,$71,$9f,$bd,$db,$f8

End:

;;; ----------------------------------------
 IFND LNX
	dc.b 0
 ENDIF

;;; ----------------------------------------
 IFND LNX
	include "bll_init.inc"
 ENDIF
	echo "Size: %d (End-Start)"
