***************
* Rainbow
* A tiny Atari Lynx demo for Outline 2026
* Visual: a vertical gradient drawn once into video RAM,
*         then the 16-colour palette is rotated every VBL,
*         producing a hypnotic stream of rainbow bars
*         rolling endlessly down the screen.
* Author: GitHub Copilot (in the spirit of 42Bastian)
* Assembler: lyxass
***************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
ptr	ds 2		; screen write pointer
idx	ds 1		; palette rotation phase
tmp	ds 1		; scratch
 END_ZP

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF

;;; ----------------------------------------
Start::
;;; --- Paint the screen with a vertical gradient.
;;; Each row r in 0..101 is filled with the byte (r&15)*$11
;;; so that both 4bpp pixels in a byte share the same colour
;;; index. Screen base = $2000, 80 bytes per row, 102 rows.
	lda	#$20
	sta	ptr+1
	stz	ptr
	ldx	#0		; row counter
.row
	txa
	and	#15
	sta	tmp		; save low nibble
	asl
	asl
	asl
	asl
	ora	tmp		; A = (row & 15) * $11
	ldy	#79		; 80 bytes per scanline
.col
	sta	(ptr),y
	dey
	bpl	.col
;;; advance ptr by 80
	lda	ptr
	clc
	adc	#80
	sta	ptr
	bcc	.nohi
	inc	ptr+1
.nohi
	inx
	cpx	#102
	bne	.row

;;; --- Initialise the rainbow lookup (already in ROM table,
;;; nothing else needed). Just zero the phase.
	stz	idx

;;;------------------------------
main:
;;;------------------------------
;;; Wait for vertical blank (line counter reads 0 in VBL)
.vbl
	ldx	$fd0a
	bne	.vbl

;;; Rotate the 16-entry palette by writing a window of the
;;; 32-entry rainbow table, offset by `idx'.
	ldx	#15
.pal
	txa
	clc
	adc	idx
	and	#31
	tay
	lda	pal_green,y
	sta	GREEN0,x
	lda	pal_bluered,y
	sta	BLUERED0,x
	dex
	bpl	.pal

	inc	idx
	bra	main

;;; ----------------------------------------
;;; 32-entry smooth hue ramp (two identical halves so the
;;; rotation wraps seamlessly).
pal_green:
	dc.b $0,$1,$3,$5,$7,$9,$b,$d,$f,$d,$b,$9,$7,$5,$3,$1
	dc.b $0,$1,$3,$5,$7,$9,$b,$d,$f,$d,$b,$9,$7,$5,$3,$1
pal_bluered:
	dc.b $0f,$1e,$2d,$3c,$4b,$5a,$69,$78,$87,$96,$a5,$b4,$c3,$d2,$e1,$f0
	dc.b $0f,$1e,$2d,$3c,$4b,$5a,$69,$78,$87,$96,$a5,$b4,$c3,$d2,$e1,$f0

End:

;;; ----------------------------------------
 IFND LNX
	;; ROM clears to zero after the BLL loader anyway.
	dc.b 0
 ENDIF

;;; ----------------------------------------
 IFND LNX
	include "bll_init.inc"
 ENDIF
	echo "Size: %d (End-Start)"
