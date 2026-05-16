***************
* Author: LX
* Assembler: lyxass
***************

	include <includes/hardware.inc>
	include <macros/help.mac>

 BEGIN_ZP
temp 	ds 1
color	ds 1
ptr		ds 2
 END_ZP

	if NEXT_ZP > 255
	fail "ZP overrun"
	endif

CENTERX	equ 80
CENTERY	equ 51
VID_BASE_HI equ $20
SPR_BASE equ $50

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

;	ldx	#15
;.scb
;	lda	$5082,x
;	sta	SPR_BASE,x
;	dex
;	bpl	.scb

;;;------------------------------
main:

;;;------------------------------
;;; Wait for vertical blank
.vbl
;	lda	$fd0a
;	bne	.vbl

	ldx #8
.7	lda $FFEF,x
	LDY $FFE6,x
	STA $FC00,y
	DEX
	;CMP #1
;	BNE .7
	BPL .7
	STZ CPUSLEEP		; Reset CPU bus request flip flop (draw INSERT GAME sprite)
	STZ SDONEACK		; Clear SDONEACK
.5
	lda SPRSYS
	lsr
	bcs .5

.8
	dec temp
	bne .9

	lda #$10
	sta temp
	inc color
	lda color
	and #$f0
	sta $5091

.9 	jmp	main

;;	lda #$20
;;	sta VIDBAS+1
;;	stz VIDBAS
;
;	lda #$01
;	sta SPRGO
;	stz SDONEACK		; Clear SDONEACK
;	stz CPUSLEEP
;.9	lda SPRSYS
;	lsr
;	bcs .9
;;	inc $5089


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
