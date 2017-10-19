; boot loader (move program code into ram and execute)

  .TEXT

START:
	move.w  #$2700,sr
	move.w  #$7fff,$f0004e

	; COPY TO RAM...

	move.l  #256000/4+1,d0		; Size of program in bytes divided 4,+1
	lea		  CODE,a0				    ; program code to copy...
	move.l	#$4000,a1   	    ; Destination to copy to...
RAM_COPY:
	move.l	(a0)+,(a1)+
	subq.l	#1,d0
	bne.s	  RAM_COPY
	jmp     $4000

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; INCLUDED FILES/GRAPHICS/SOUNDS ON CARTRIDGE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;--------------------------------------------
;-- GRAPHICS                               --
;--------------------------------------------

;--------------------------------------------
	.QPHRASE
DC.B			'SWLOGO'					 					 ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
SCORE:			INCBIN  "GFX/INTANM.LZJ"	 ; INTRO LOGO ANIMATION (COMPRESSED)
	.QPHRASE
;--------------------------------------------
	.QPHRASE
DC.B			'FONT'											 ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
FONT:			INCBIN  "GFX/FONT.RGB"	 	   ; FONT (UNCOMPRESSED)
	.QPHRASE
;--------------------------------------------
	.QPHRASE
DC.B			'TITLEBG'					           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
TITLEBG:		INCBIN  "GFX/TITLEBG.LZJ"	 ; TITLE BACKGROUND (COMPRESSED)
	.QPHRASE
;--------------------------------------------
	.QPHRASE
DC.B			'TLOGO'						           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
TLOGO:			INCBIN  "GFX/TLOGO.LZJ"	   ; TITLE LOGO (COMPRESSED)
	.QPHRASE
;--------------------------------------------
	.QPHRASE
DC.B			'TBEAM'						           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
TBEAM:			INCBIN  "GFX/TBEAM.LZJ"	   ; TITLE BEAM (COMPRESSED)
	.QPHRASE
;--------------------------------------------
DC.B			'PSELECT'					           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
PSELECT:		INCBIN  "GFX/PSELECT.LZJ"  ; PLAYER SELECT TEXT GRAPHIC (COMPRESSED)
	.QPHRASE
;--------------------------------------------
DC.B			'BGBOX'						           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
BGBOX:			INCBIN  "GFX/BGBOX.LZJ"    ; BACKGROUND BOX PANEL GRAPHIC (COMPRESSED)
	.QPHRASE
;--------------------------------------------
DC.B			'PLAYERS'					           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
PLAYERS:		INCBIN  "GFX/PLAYERS.LZJ"  ; BACKGROUND BOX PANEL GRAPHIC (COMPRESSED)
	.QPHRASE
;--------------------------------------------
DC.B			'CURSOR'					           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
CURSORS:		INCBIN  "GFX/CURSORS.LZJ"  ; PLAYER SELECT CURSORS (COMPRESSED)
	.QPHRASE
;--------------------------------------------
DC.B			'LEVEL1'					           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
LEVEL1:			INCBIN  "GFX/LEVEL1.LZJ"   ; LEVEL 1 (COMPRESSED)
	.QPHRASE
;--------------------------------------------
DC.B			'BBWALK'					           ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
BBWALK:			INCBIN  "GFX/BBWALK.RGB"   ; BLONDE BOY WALK (RAW)
	.QPHRASE
;--------------------------------------------
DC.B			'NME1SPAWN'					         ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
NME1SPAWN:		INCBIN  "GFX/NME1_SPAWN.RGB" ; ENEMY 1 WALK (RAW)
	.QPHRASE
;--------------------------------------------
DC.B			'NME1WALK'					         ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
NME1WALK:		INCBIN  "GFX/NME1_WALK.RGB"; ENEMY 1 WALK (RAW)
	.QPHRASE
;--------------------------------------------
DC.B			'NME1DIE1'					         ; IDENTIFY TAG (FOR HEX EDITOR)
	.QPHRASE
NME1DIE1:		INCBIN  "GFX/NME1_DIE1.RGB"; ENEMY 1 WALK (RAW)
	.QPHRASE
;--------------------------------------------
CODE:			INCBIN  "CODE.BIN"           ; GAME CODE
;--------------------------------------------

	.END
