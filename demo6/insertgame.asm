***************
* Author: LX
* Assembler: lyxass
***************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
temp	ds 1
ptr		ds 2
 END_ZP

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

CENTERX	equ 80
CENTERY	equ 51
VID_BASE_HI equ $20

 IFND LNX
	run	$200-3
	jmp	bll_init
 ELSE
	run	$200
 ENDIF

;;; ----------------------------------------
Start::

;;; Set up rainbow palette for colorful cycling
	ldx	#15
.pal
	lda	pal_green,x
	sta	GREEN0,x
	lda	pal_bluered,x
	sta	BLUERED0,x
	dex
	bpl	.pal

;;;------------------------------
main:

;;;------------------------------
;;; Wait for vertical blank
.vbl
	lda	$fd0a
	bne	.vbl

screen_loop:
	lda #VID_BASE_HI
	sta ptr+1
	stz ptr

; Start loop over all pixels
	ldy	#0
	ldx	#32
.loop

; Calculate color of pixel in A
	lda $FF54

	sta	(ptr),y 	; Store color in current pixel
	iny
	bne	.loop
	inc	ptr+1
	dex
	bne	.loop

	inc	BLUERED1

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
