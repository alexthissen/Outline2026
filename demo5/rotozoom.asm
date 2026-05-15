***************
* Author: GitHub Copilot (in the spirit of 42Bastian)
* Assembler: lyxass
***************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
frame 	ds 1
 END_ZP

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

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

;;; Set up rainbow palette for colorful cycling
	ldx	#15
.pal
	lda	pal_green,x
	sta	GREEN0,x
	lda	pal_bluered,x
	sta	BLUERED0,x
	dex
	bpl	.pal

	stz	frame

;;;------------------------------
main:

;;;------------------------------
;;; Wait for vertical blank
.vbl
	lda	$fd0a
	bne	.vbl



	inc	BLUERED0
	jmp	main

;;; ----------------------------------------
;;; 16-entry hue ramp palette
pal_green:
	dc.b $0,$2,$5,$8,$b,$f,$f,$f,$f,$f,$b,$8,$5,$2,$0,$0
pal_bluered:
	dc.b $00,$1d,$2b,$39,$47,$55,$63,$71,$17,$35,$53,$71,$9f,$bd,$db,$f8

End:
Size equ End-Start

;;; ----------------------------------------
 IFND LNX
	dc.b 0
 ENDIF

;;; ----------------------------------------
 IFND LNX
	include "bll_init.inc"
 ENDIF
	echo "Size: %dSize"
