
	.INCLUDE "INCLUDES/SYSTEM.INC"		; SYSTEM EQUATES
	.INCLUDE "INCLUDES/SPU_LIB.INC"		; SOUND EQUATES

;*******************************************************************
;** PROGRAM FLAGS                                                 **
;*******************************************************************

	DEVELOPMENT			EQU	  1 		; THIS IS HERE SO CD WILL BOOT VIA FLASH CARTRIDGE WHILE IN DEV MODE (turn this off for production)
	CD_UNIT 			  EQU	  0     ; RUNNING ON CD_UNIT? 0 = CART, 1 = CD
	AUDIO				    EQU   0     ; 0 = DISABLED , 1 = ENABLED

;*******************************************************************
;** GRAPHICS / MUSIC / SFX LOCATIONS IN CARTRIDGE                 **
;*******************************************************************

	SWANM_ROM			EQU   $802000+$60
	FONT_ROM			EQU	  $802000+$9D00
	TITLEBG_ROM		EQU	  $802000+$CBA0
	TLOGO_ROM			EQU	  $802000+$11C00
	TBEAM_ROM			EQU	  $802000+$13640

	PSELECT_ROM		EQU	  $802000+$15560
	BGBOX_ROM			EQU	  $802000+$15800
	PLAYERS_ROM		EQU	  $802000+$168A0
	CURSORS_ROM		EQU	  $802000+$18D80
	LEVEL1_ROM		EQU	  $802000+$193A0
	BBWALK_ROM		EQU   $802000+$32000

  NME1SPAWN_ROM EQU   $802000+$37A20
  NME1WALK_ROM  EQU   $802000+$3E640
  NME1DIE1_ROM  EQU   $802000+$42E60

;*******************************************************************
;** MEMORY MAPPING FOR PROGRAM                                    **
;*******************************************************************

	RAM_START			EQU	  $4000+262144				      ; 256KB GAME CODE AT BEGINGING OF RAM...
	MEM_FLASH			EQU		RAM_START					        ; SCREEN SHADE BITMAP AREA
	MEM_TEXT			EQU   MEM_FLASH+((160*120)*2)   ; TEXT BUFFER
	MEM_RAM				EQU 	MEM_TEXT+((320*240)*2)    ; WHERE USER RAM STARTS
	MEM_BUFFER		EQU   ENDRAM-10240				      ; 8K LZJAG STACK + 2K PROGRAM STACK = 10K

;******************************************************************************
	TOTAL_OBJS       	EQU    256
;******************************************************************************

	.68000
	.TEXT

;********************************************************************
;** START INITIALIZING SYSTEM FOR GAME SETUP
;********************************************************************

START::
	move    #$2700,sr
	lea     $1000.w,sp            ; Set stack pointer
	lea     $F00000,a0
	move.l  #$070007,d0           ; big endian
	move.l  d0,$210C(a0)
	move.l  d0,$F1A10C
	moveq   #0,d0
	move.l  d0,$2114(a0)          ; stop gpu
	move.l  d0,$f1a114            ; stop dsp
	move.l  d0,$2100(a0)          ; disable GPU-IRQs
	bra     continue2             ; disable DSP-IRQs
	move.l  #%10001111100000000,$f1a100
	move.l  #%111111<<8,$f10020   ; clear and disable IRQs
continue2:
	move.l  d0,0.w
	moveq   #4,d0
	move.l  d0,4.w
	moveq   #0,d0
	move.l  d0,$20(a0)           ; set OP to STOP-OBJECT
	move.w  d0,$26(a0)           ; clear OP-Flag
	move.l  d0,$2A(a0)           ; border black
	move.w  d0,$56(a0)           ; set CRY mode to color/not BW
	move.w  d0,$58(a0)           ; background black
	move.l  d0,$50(a0)           ; stop PIT
	move.l  d0,$f10000           ; stop JPIT1
	move.l  d0,$f10004           ; stop JPIT2
	move.l  #$1F00<<16,$E0(a0)   ; clear pending irqs
	move.w  #$7fff,$4e(a0)       ; no VI
	lea     dummy_irq(pc),a0
	move.l  a0,$0100.w
	bra.s   INIT1
dummy_irq:
	move.l  #$1f00<<16,$f000e0
	rte

INIT1:	moveq   #0,d0
	moveq   #0,d1
	moveq   #0,d2
	moveq   #0,d3
	moveq   #0,d4
	moveq   #0,d5
	moveq   #0,d6
	moveq   #0,d7
	move.l  d0,a0
	move.l  d0,a1
	move.l  d0,a2
	move.l  d0,a3
	move.l  d0,a4
	move.l  d0,a5
	move.l  d0,a6
	move.l  #INITSTACK,sp

;--------------------------------------------------------------

	move.w  #$100,JOYSTICK          ; Turn sound to mute
	move.l  #0,G_CTRL               ; stop GPU
	move.l  #0,D_CTRL               ; stop DSP
	move.l  #0,G_FLAGS              ; init GPU Flags
	move.l  #0,D_FLAGS              ; init DSP Flags
	move.l	#$00070007,G_END	      ; GPU Big Endian Mode
	move.l	#$00070007,D_END	      ; DSP Big Endian Mode
	move.w	#$35cc,MEMCON2		      ; Big Endian Mode

  jsr     COPY_GPU    		    	  ; COPY GPU PROGARM TO GPU RAM
	jsr     SetupLZJag				      ; SETUP LZJAG ON GPU

  bsr     InitAudio           	  ; Initialize the Audio

	bsr     InitVideo               ; init Video System
	bsr     IntInit                 ; init Interrupts

	lea     olist1_branch,a0
	move.l  #olist1_stop,d2
	bsr		  create_branch

	lea		  olist2_branch,a0	  	  ; load Address of branch object
	move.l	#olist2_stop,d2			    ; point to stop obj
	bsr		  create_branch

	move.l	#olist1,olist
	move.l	#olist2,olist_ram

	move.l	#olist1_stop,d0			    ; address of obj stop obj list
	swap	  d0						          ; swap contents in register around
	move.l	d0,OLP					        ; move to OLP

	move.w  #$4C7,VMODE             ; Video Init 320x240 16 Bit RGB

	moveq   #0,d0
	move.w  a_vdb,d0
	andi.w  #$FFFE,d0
	move.l  d0,gpu_a_vdb

	move.w	#16,anz_objects			    ; We want to display 16 Objects
  lea		  gpu_obj_data,a0
  lea		  title_list,a1 			    ; point to title obj list in a1
  move.l  a1,(a0)

	jsr		  start_gpu								; fire off gpu!
	stop    #$2000									; stop 68k

;*******************************************************************
;** SETUP TITLE SCREEN                                            **
;*******************************************************************

SETUP_TITLE:
	move.l	#TITLEBG_ROM,lzinbuf				   ; DECOMPRESS TITLE BACKGROUND
	move.l	#MEM_RAM,lzoutbuf		   	       ; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			 ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   			 ; DECOMPRESS!!
	bsr     WAITGPU								   			 ; WAIT FOR GPU TO BE DONE...

	move.l	#TLOGO_ROM,lzinbuf				  	 ; DECOMPRESS TITLE LOGO
	move.l	#MEM_RAM+((320*240)*2),lzoutbuf; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			 ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   			 ; DECOMPRESS!!
	bsr     WAITGPU								   			 ; WAIT FOR GPU TO BE DONE...

	move.l	#TBEAM_ROM,lzinbuf				  	 ; DECOMPRESS GREEN BEAM GRAPHICS
	move.l	#MEM_RAM+((320*240)*2)+((208*128)*2),lzoutbuf ; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			 ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   			 ; DECOMPRESS!!
	bsr     WAITGPU								   			 ; WAIT FOR GPU TO BE DONE...

	lea		gpu_text,a1
	lea		title_text,a2    				       	 ; MESSAGE TO PRINT INTO A2
	move.l	a2,(a1)

;*******************************************************************
;** TITLE SCREEN                                                  **
;*******************************************************************

TITLE_SCREEN:
	move.w	#1,BGACT							   ; TURN ON TITLE BACKGROUND (SCALED)

;	jsr		SETUP_SELECT

	move.w  #520,TLOGOY							   ; PUSH TITLE LOGO TO BOTTOM OFF SCREEN
	move.w  #1,LOGOACT							   ; TURN ON TITLE LOGO

; PULL UP LOGO FROM BOTTOM OF SCREEN

.MOVE_LOGO:
	cmp.w   #75,TLOGOY							   ; LOGO IN ITS PLACE?
	ble		.LOGO_DONE							   ; IF SO WE ARE DONE!
	sub.w   #4,TLOGOY							   ; OTHERWISE PULL IT UP
	jsr		wait_int							   ; WAIT A FRAME...
	bra.s	.MOVE_LOGO							   ; LOOP UNTIL ITS DONE
.LOGO_DONE:										   ; IF WE'RE DONE WE DROP OUT HERE...
	move.w  #1,TXTACT							   ; TURN ON TEXT SCREEN
	move.b  #1,TB1FLAG							   ; SET OBJECT AS SCALED..
;	move.w  #1,TB1ACT							   ; TURN ON BEAM AS SCALED OBJECT
	move.b  #0,TBSCALX						       ; SHORTEN BEAM TO 1 FOR SCALED WIDTH

	jsr		TITLE_JOYPAD					       ; GO TO TITLE SCREEN JOYPAD ROUTINE

;--------------------------------------
;-- TITLE SCREEN JOYPAD LOOP         --
;--------------------------------------

TITLE_JOYPAD:
	bsr     readpad
	move.l  joyedge,d0
	btst.l  #OPTION,d0
	beq     .NO_OPT
	jsr		CLEAR_TEXT				 ; CLEAR TEXT SCREEN
	jsr		SETUP_SELECT
.NO_OPT:
	bsr		OPEN_BEAM
	bsr		ANIMATE_BEAM
	jsr		wait_int
	bra.s	TITLE_JOYPAD

OPEN_BEAM:
	cmp.b   #32,TBSCALX							   ; SCALED OUT YET?
	beq		.BEAM_ODONE							   ; IF SO GOTO DONE
	add.b   #2,TBSCALX							   ; OTHERWISE SCALE IN...
	sub.w   #2,TBEAMX
	rts
.BEAM_ODONE:
	rts

CLOSE_BEAM:
	cmp.b   #0,TBSCALX							   ; SCALED in YET?
	beq		.BEAM_DONE							   ; IF SO GOTO DONE
	sub.b   #2,TBSCALX							   ; OTHERWISE SCALE IN...
	add.w   #2,TBEAMX
	rts
.BEAM_DONE:
	rts

ANIMATE_BEAM:
	add.w   #1,BEAM_ANMCOUNT			; INCREMENT COUNTER
	cmp.w   #3,BEAM_ANMCOUNT			; BEAM ANIMATION COUNT REACHED THRESHOLD?
	beq.s	.ANM8_BEAM_RESET
	cmp.w   #1,BEAM_ANMCOUNT
	beq.s	.BEAM_NEXTFRAME
	rts
.ANM8_BEAM_RESET:
	move.w	#0,BEAM_ANMCOUNT
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2),TBDTA				; FIRST FRAME...
	rts
.BEAM_NEXTFRAME:
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*240)*2),TBDTA	; SECOND FRAME...
	rts

;*******************************************************************
;** SETUP CHARACTER SELECT	                                      **
;*******************************************************************

SETUP_SELECT:
	move.w  #0,LOGOACT
	move.w  #0,TB1ACT
	jsr		CLEAR_TEXT

	move.l	#PSELECT_ROM,lzinbuf				   ; DECOMPRESS PLAYER SELECT TEXT GRAPHICS
	move.l	#MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2),lzoutbuf ; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			   ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   ; DECOMPRESS!!
	bsr     WAITGPU								   ; WAIT FOR GPU TO BE DONE...

	move.l	#BGBOX_ROM,lzinbuf				  	   ; DECOMPRESS BACKGROUND BOX GRAPHICS
	move.l	#MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2),lzoutbuf ; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			   ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   ; DECOMPRESS!!
	bsr     WAITGPU								   ; WAIT FOR GPU TO BE DONE...

	move.l	#PLAYERS_ROM,lzinbuf				   ; DECOMPRESS PLAYER PORTRATE GRAPHICS
	move.l	#MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2),lzoutbuf ; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			   ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   ; DECOMPRESS!!
	bsr     WAITGPU								   ; WAIT FOR GPU TO BE DONE...

	move.l	#CURSORS_ROM,lzinbuf				   ; DECOMPRESS PLAYER SELECT CURSOR GRAPHICS
	move.l	#MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*768)*2),lzoutbuf ; DESTINATION
	move.l	#MEM_BUFFER,lzworkbuf	   			   ; BUFFER LOCATION
	move.l	#delzss,G_PC
	move.l	#1,G_CTRL							   ; DECOMPRESS!!
	bsr     WAITGPU								   ; WAIT FOR GPU TO BE DONE...

	add.w   #400,TGFXY
	add.w	#400,BGBOXY

	move.w  #1,TGFXACT							   ; TURN ON PLAYER SELECT TEXT GRAPHIC

	move.b  #2,BGBSY							   ; MAKE SCALED SMALL ON Y AXIS
	move.b  #1,BGBFLAG							   ; SET BACKGROUND BOX AS A SCALED OBJECT.
;	move.w  #1,BGBOXACT							   ; TURN ON BACKGROUND BOX OBJECT                         !!!!!!!! ( THIS IS FUCKED FOR SOME REASON ) !!!!!!!!

.MOVE_SELECT_UP:
	cmp.w   #125,TGFXY							   ; "SELECT PLAYER" GRAPHIC IN ITS PLACE?
	ble		.MOVE_SELECT_DONE					   ; IF SO WE ARE DONE!
	sub.w   #16,TGFXY							   ; OTHERWISE PULL IT UP
	sub.w   #16,BGBOXY
	jsr		wait_int							   ; WAIT A FRAME...
	bra.s	.MOVE_SELECT_UP						   ; LOOP UNTIL ITS DONE
.MOVE_SELECT_DONE:								   ; IF WE'RE DONE WE DROP OUT HERE...

.SCALE_IN_YPOS:
	cmp.b   #32,BGBSY
	bge		.SCALE_IN_YPOS_DONE
	add.b	#2,BGBSY
	jsr		wait_int							   ; WAIT A FRAME...
	bra.s	.SCALE_IN_YPOS						   ; LOOP UNTIL ITS DONE
.SCALE_IN_YPOS_DONE:							   ; IF WE'RE DONE WE DROP OUT HERE...
	sub.w   #2,BGBOXY							   ; NOW GIVE BACKGROUN BOX A SLIGHT NUDGE INTO PLACE....

	move.w  #1,PSB1ACT							   ; TURN ON PLAYER 1 SELECT BOX
	move.w  #1,PSB2ACT							   ; TURN ON PLAYER 2 SELECT BOX
	move.w  #1,PSB3ACT							   ; TURN ON PLAYER 3 SELECT BOX
	move.w  #1,PSB4ACT							   ; TURN ON PLAYER 4 SELECT BOX
	move.w  #1,PSB5ACT							   ; TURN ON PLAYER 5 SELECT BOX
	move.w  #1,PSB6ACT							   ; TURN ON PLAYER 6 SELECT BOX
	move.w  #1,PSB7ACT							   ; TURN ON PLAYER 7 SELECT BOX
	move.w  #1,PSB8ACT							   ; TURN ON PLAYER 8 SELECT BOX

	move.w  #1,CUR1ACT							   ; TURN ON PLAYER 1 CURSOR SELECTOR

.SELECT_LOOP:
	jsr		CHECK_DONE_SELECTING				   ; SEE IF PLAYERS ARE DONE SELECTING...
	jsr		SELECT_JOYPAD1						   ; GET PLAYER INPUT AND ADJUST POSITIONS
	jsr		UPDATE_SELECT						   ; UPDATE SELECT SCREEN WITH NEW POSITIONS FROM JOYPAD ROUTINE
	jsr		wait_int							   ; WAIT A FRAME
	bra		.SELECT_LOOP						   ; LOOP FOREVER

CHECK_DONE_SELECTING:
	cmp.b   #1,P1_SELECTED_FLAG		 ; PLAYER MADE CHOICE?
	beq		.DONE_SELECTING
	rts

;--------------------------------------
; DONE SELECTING
;--------------------------------------

.DONE_SELECTING:

	rept	3
	jsr		WAIT2
	endr

	move.w  #0,PSB1ACT							   ; TURN OFF PLAYER 1 SELECT BOX
	move.w  #0,PSB2ACT							   ; TURN OFF PLAYER 2 SELECT BOX
	move.w  #0,PSB3ACT							   ; TURN OFF PLAYER 3 SELECT BOX
	move.w  #0,PSB4ACT							   ; TURN OFF PLAYER 4 SELECT BOX
	move.w  #0,PSB5ACT							   ; TURN OFF PLAYER 5 SELECT BOX
	move.w  #0,PSB6ACT							   ; TURN OFF PLAYER 6 SELECT BOX
	move.w  #0,PSB7ACT							   ; TURN OFF PLAYER 7 SELECT BOX
	move.w  #0,PSB8ACT							   ; TURN OFF PLAYER 8 SELECT BOX
	move.w  #0,CUR1ACT							   ; TURN OFF PLAYER 1 CURSOR SELECTOR
	move.w  #0,TGFXACT							   ; TURN OFF PLAYER SELECT TEXT GRAPHIC
	move.w  #0,BGBOXACT							   ; TURN OFF BACKGROUND BOX OBJECT

	jsr		SETUP_STAGE

;--------------------------------------
;-- PLAYER SELECT JOYPAD LOOP        --
;--------------------------------------
; SO FAR THIS ONLY COVERS JOYPAD PORT 1

SELECT_JOYPAD1:
	cmp.b   #1,P1_SELECTED_FLAG		 ; PLAYER MADE CHOICE?
	beq			.P1_CURSOR_CHK_DONE
	bsr     readpad
	move.l  joyedge,d0				 ; PRESSED
	btst.l  #JOY_UP,d0				 ; PRESSED UP?
	beq     .SEL_DN_CHK
	cmp.b   #2,P1_CURSOR_ROW		 ; ON LOWER ROW?
	beq.s		.UP_ROW					 ; yes so move up
	bra.s		.SEL_DN_CHK				 ; CHEC FOR MOVING DOWN...
.UP_ROW:
	sub.b		#1,P1_CURSOR_ROW		 ; ADJUST ROW WE ARE ON TO FIRST ROW.
.SEL_DN_CHK:
	btst.l  #JOY_DOWN,d0			 ; PRESSED DOWN?
	beq     .SEL_LF_CHK				 ; CHECK LEFT NEXT IF NOT PRESSED...
	cmp.b   #1,P1_CURSOR_ROW		 ; ON UPPER ROW?
	beq.s		.DN_ROW					 ; yes so move DOWN
	bra.s		.SEL_LF_CHK				 ; CHEC FOR MOVING LEFT...
.DN_ROW:
	add.b		#1,P1_CURSOR_ROW		 ; ADJUST ROW WE ARE ON 2ND ROW.
.SEL_LF_CHK:
	btst.l  #JOY_LEFT,d0			 ; PRESSED LEFT?
	beq.s   .SEL_RT_CHK				 ; CHECK RIGHT NEXT IF NOT PRESSED...
	cmp.b   #1,P1_CURSOR_POS		 ; ALREADY FAR LEFT?
	bne.s		.MOVE_CUR_LF			 ; IF NOT THEN ALOW THE MOVE..
	bra.s		.SEL_RT_CHK				 ; OTHERWISE DONT, MOVE TO NEXT CHECK..
.MOVE_CUR_LF:
	sub.b		#1,P1_CURSOR_POS		 ; ADJUST CURSOR POSITION
.SEL_RT_CHK:
	btst.l  #JOY_RIGHT,d0			 ; PRESSED RIGHT?
	beq.s   .SEL_B_CHK				 ; CHECK B PRESSED IF NOT PRESSED...
	cmp.b   #4,P1_CURSOR_POS		 ; ALREADY FAR LEFT?
	bne.s		.MOVE_CUR_RT			 ; IF NOT THEN ALOW THE MOVE..
	bra.s		.SEL_B_CHK				 ; OTHERWISE DONT, MOVE TO NEXT CHECK.
.MOVE_CUR_RT:
	add.b		#1,P1_CURSOR_POS		 ; ADJUST CURSOR POSITION
.SEL_B_CHK:
	btst.l  #FIRE_B,d0			 	 ; PRESSED B?
	beq.s   .P1_CURSOR_CHK_DONE		 ; CHECK B PRESSED IF NOT PRESSED...
	move.b  #1,P1_SELECTED_FLAG		 ; SET FLAG FOR PLAYER SELECTING A CHARACTER
	rts
.P1_CURSOR_CHK_DONE:
	rts

;-----------------------------------------------------
;-- UPDATE PLAYER POSITIONS ON SELECT SCREEN        --
;-----------------------------------------------------

UPDATE_SELECT:
	; RESET ROW 1 TO GREY IMAGES
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*18),PS1DTA
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*6),PS2DTA
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*12),PS3DTA
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*24),PS4DTA
    ; RESET ROW 2 TO GREY IMAGES
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*36),PS5DTA
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2),PS6DTA
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*42),PS7DTA
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*30),PS8DTA

	cmp.b	#1,P1_CURSOR_ROW		; ARE WE ON ROW 1?
	beq.s	.ROW1					; IF SO THEN GOTO ROW 1 SUBROUTINE
	bra		.ROW2					; OTHERWISE ITS GOTTA BE ROW 2...
	rts

; -----------------------------------------------------------------------------------------------------------------------------
.ROW1:
	cmp.b   #1,P1_CURSOR_POS		; PLAYER ON SLOT 1 (JEFF)
	beq.s	.S1R1					; SLOT 1 ROW 1
	cmp.b   #2,P1_CURSOR_POS		; PLAYER ON SLOT 1 (EMILY)
	beq.s	.S2R1					; SLOT 1 ROW 1
	cmp.b   #3,P1_CURSOR_POS		; PLAYER ON SLOT 1 (EVELYN)
	beq.s	.S3R1					; SLOT 1 ROW 1
	cmp.b   #4,P1_CURSOR_POS		; PLAYER ON SLOT 1 (JOHN)
	beq 	.S4R1					; SLOT 1 ROW 1
	rts
; -----------------------------------------------------------------------------------------------------------------------------
.S1R1:
	move.w	#93,CUR1X				; SET X POS TO CURSOR OVER CELL
	move.w  #204,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	cmp.b   #1,P1_SELECTED_FLAG		; P1 SELECTED FLAG SET?
	bne.s	.S1R1_NO
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*22),PS1DTA ; selected image
	rts
.S1R1_NO:
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*20),PS1DTA ; highlighted image
	rts
; -----------------------------------------------------------------------------------------------------------------------------
.S2R1:
	move.w	#93+46,CUR1X			; SET X POS TO CURSOR OVER CELL
	move.w  #204,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	cmp.b   #1,P1_SELECTED_FLAG		; P1 SELECTED FLAG SET?
	beq.s	.S2R1_NO
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*8),PS2DTA ; highlighted image
	rts
.S2R1_NO:
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*10),PS2DTA ; selected image
	rts
; -----------------------------------------------------------------------------------------------------------------------------
.S3R1:
	move.w	#93+46+46,CUR1X			; SET X POS TO CURSOR OVER CELL
	move.w  #204,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	cmp.b   #1,P1_SELECTED_FLAG		; P1 SELECTED FLAG SET?
	bne.s	.S3R1_NO
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*16),PS3DTA ; highlighted image
	rts
.S3R1_NO:
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*14),PS3DTA ; highlighted image
	rts
; -----------------------------------------------------------------------------------------------------------------------------
.S4R1:
	move.w	#93+46+46+46,CUR1X		; SET X POS TO CURSOR OVER CELL
	move.w  #204,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	cmp.b   #1,P1_SELECTED_FLAG		; P1 SELECTED FLAG SET?
	beq.s	.S4R1_NO
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*26),PS4DTA ; highlighted image
	rts
.S4R1_NO:
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*28),PS4DTA ; highlighted image
	rts
;------------------------------------------------------------------------------------------------------------------------------
.ROW2:
	cmp.b   #1,P1_CURSOR_POS		; PLAYER ON SLOT 1 (SHAWN)
	beq.s	.S1R2					; SLOT 1 ROW 1
	cmp.b   #2,P1_CURSOR_POS		; PLAYER ON SLOT 1 (COREY)
	beq.s	.S2R2					; SLOT 1 ROW 1
	cmp.b   #3,P1_CURSOR_POS		; PLAYER ON SLOT 1 (TYLER)
	beq.s	.S3R2					; SLOT 1 ROW 1
	cmp.b   #4,P1_CURSOR_POS		; PLAYER ON SLOT 1 (LUCAS)
	beq.s	.S4R2					; SLOT 1 ROW 1
.S1R2:
	move.w	#93,CUR1X				; SET X POS TO CURSOR OVER CELL
	move.w  #282,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*38),PS5DTA ; highlighted image
	rts
.S2R2:
	move.w	#93+46,CUR1X			; SET X POS TO CURSOR OVER CELL
	move.w  #282,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*2),PS6DTA ; highlighted image
	rts
.S3R2:
	move.w	#93+46+46,CUR1X			; SET X POS TO CURSOR OVER CELL
	move.w  #282,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*44),PS7DTA ; highlighted image
	rts
.S4R2:
	move.w	#93+46+46+46,CUR1X		; SET X POS TO CURSOR OVER CELL
	move.w  #282,CUR1Y				; SET Y POS TO CURSOR OVER CELL
	move.l  #MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*32),PS8DTA ; highlighted image
	rts

;************************************************************************************************

	.QPHRASE

copyright_text:
dc.l	COPYRIGHT_TXT		;0-4	MESSAGE
dc.l	MEM_TEXT				;12-16  DESTINATION
dc.w	$ffff           ;4-6	TEXTCOLOR
dc.w	0               ;6-8	TEXTX
dc.w 	12             	;8-10   TEXTY
dc.w	0               ;10-12  DUMMY_TXT

dc.l	0								;0-4	MESSAGE
dc.l	0								;12-16  DESTINATION
dc.w	0           		;4-6	TEXTCOLOR
dc.w	0               ;6-8	TEXTX
dc.w 	0               ;8-10   TEXTY
dc.w	0               ;10-12  DUMMY_TXT

title_text:
dc.l	SWTEXT					;0-4	MESSAGE
dc.l	MEM_TEXT				;12-16  DESTINATION
dc.w	$ffff           ;4-6	TEXTCOLOR
dc.w	0               ;6-8	TEXTX
dc.w 	18             	;8-10   TEXTY
dc.w	0               ;10-12  DUMMY_TXT

dc.l	0								;0-4	MESSAGE
dc.l	0								;12-16  DESTINATION
dc.w	0           		;4-6	TEXTCOLOR
dc.w	0               ;6-8	TEXTX
dc.w 	0               ;8-10   TEXTY
dc.w	0               ;10-12  DUMMY_TXT

	.QPHRASE

COPYRIGHT_TXT:	dc.b    'TEST123',0
SWTEXT:		dc.b    '',1,'',1,'',1,'              PRESS OPTION             ',0

;******************************************************************************

    .QPHRASE
    include "INCLUDES/GPU.GPU"
    .QPHRASE
	  include "INCLUDES/LZSS.S"
	  .QPHRASE
    include "INCLUDES/SOUND.S"
    .QPHRASE
    include "INCLUDES/VIDEO.S"
		.QPHRASE
		include	"INCLUDES/MISC.S"
		.QPHRASE
		include "INCLUDES/ANIM.S"
		.QPHRASE
		INCLUDE "GAME.S"

;*******************************************************************
;** OBJECT LIST STRUCTURE                                         **
;*******************************************************************

	.QPHRASE

olist1_branch:
    rept    4
    dc.l    0
    endr
olist1:
    rept    ((8*TOTAL_OBJS)+2)
    dc.l 0
    endr
olist1_stop:
		dc.l    0
    dc.l    4

	.QPHRASE

olist2_branch:
	rept    4
	dc.l    0
	endr
olist2:
	rept    ((8*TOTAL_OBJS)+2)
	dc.l    0
	endr
olist2_stop:
	dc.l    0
	dc.l    4

	.QPHRASE

;******************************************************************************
;******************************************************************************
; OBJECT LIST
;******************************************************************************
;******************************************************************************
title_list:
;********************************************************************
; 320X240 BACKGROUND OBJECT                                         *
;********************************************************************
BGX:  	dc.w    15       	; (O_XPOS)      X-Pos of Object on screen
BGY:  	dc.w    40          ; (O_YPOS)      Y-Pos of Object on screen
BGDTA: 	dc.l    MEM_RAM	    ; (O_DATA)		Data / Graphic pointer
BGH:   	dc.w    240         ; (O_HEIGHT)    Height of Object in Pixels
BGIW:  	dc.w    320/4 		; (O_IWIDTH)    Width of Objects in Phrases
BGDW:  	dc.w    320/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
BGFLAG:	dc.b    0       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
     	  dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20    		; (O_SCALE)     Remainder
BGSCALX:dc.b    32      	; (Y_SCALE)
BGSCALY:dc.b    32      	; (X_SCALE)
BGACT:	dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; TITLE LOGO                                                        *
;********************************************************************
TLOGOX:	dc.w    76        	; (O_XPOS)      X-Pos of Object on screen
TLOGOY:	dc.w    125    		; (O_YPOS)      Y-Pos of Object on screen
    		dc.l    MEM_RAM+((320*240)*2)	    ; (O_DATA)		Data / Graphic pointer
    		dc.w    128         ; (O_HEIGHT)    Height of Object in Pixels
    		dc.w    208/4 		; (O_IWIDTH)    Width of Objects in Phrases
    		dc.w    208/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
    		dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
    		dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
LOGOACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; TITLE BEAM                                                        *
;********************************************************************
TBEAMX:	dc.w    100        	; (O_XPOS)      X-Pos of Object on screen
TBEAMY:	dc.w    40    		; (O_YPOS)      Y-Pos of Object on screen
TBDTA: 	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)
    		dc.w    240         ; (O_HEIGHT)    Height of Object in Pixels
    		dc.w    64/4 		; (O_IWIDTH)    Width of Objects in Phrases
    		dc.w    64/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
				dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
    		dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
TB1FLAG:dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20     	; (O_SCALE)     Remainder
TBSCALY:dc.b    32      	; (Y_SCALE)
TBSCALX:dc.b    32      	; (X_SCALE)
TB1ACT:	dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; TEXT GRAPHIC (PLAYER/LEVEL SELECT TEXT)                           *
;********************************************************************
TGFXX:	dc.w    98        	; (O_XPOS)      X-Pos of Object on screen
TGFXY:	dc.w    125    		; (O_YPOS)      Y-Pos of Object on screen
    		dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)
    		dc.w    14          ; (O_HEIGHT)    Height of Object in Pixels
    		dc.w    164/4 		; (O_IWIDTH)    Width of Objects in Phrases
    		dc.w    164/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
    		dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
    		dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
TGFXACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; BACKGROUND BOX GRAPHIC (LEVEL SELECT AND PLAYER SELECT)     *
;********************************************************************
BGBOXX:	dc.w    80        	; (O_XPOS)      X-Pos of Object on screen
BGBOXY:	dc.w    200    		; (O_YPOS)      Y-Pos of Object on screen
    		dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)
    		dc.w    82          ; (O_HEIGHT)    Height of Object in Pixels
    		dc.w    200/4 		; (O_IWIDTH)    Width of Objects in Phrases
    		dc.w    200/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
    		dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
    		dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
BGBFLAG:dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20     	; (O_SCALE)     Remainder
BGBSY:	dc.b    2	      	; (Y_SCALE)
BGBSX:	dc.b    32      	; (X_SCALE)
BGBOXACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 1
;********************************************************************
PSB1X:	dc.w    95       	; (O_XPOS)      X-Pos of Object on screen
PSB1Y:	dc.w    212    		; (O_YPOS)      Y-Pos of Object on screen
PS1DTA:	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*18)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB1ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 2
;********************************************************************
PSB2X:	dc.w    95+46      	; (O_XPOS)      X-Pos of Object on screen
PSB2Y:	dc.w    212    		; (O_YPOS)      Y-Pos of Object on screen
PS2DTA:	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*6)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB2ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 3
;********************************************************************
PSB3X:	dc.w    95+46+46   	; (O_XPOS)      X-Pos of Object on screen
PSB3Y:	dc.w    212    		; (O_YPOS)      Y-Pos of Object on screen
PS3DTA:	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*12)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
    		dc.b    4       	; (O_DEPTH)     Count of colors of the Object
    		dc.b    1       	; (O_PITCH)		Pitch
    		dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
    		dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB3ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 4
;********************************************************************
PSB4X:	dc.w    95+46+46+46	; (O_XPOS)      X-Pos of Object on screen
PSB4Y:	dc.w    212    		; (O_YPOS)      Y-Pos of Object on screen
PS4DTA:	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*24)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB4ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 5
;********************************************************************
PSB5X:	dc.w    95       	; (O_XPOS)      X-Pos of Object on screen
PSB5Y:	dc.w    290			; (O_YPOS)      Y-Pos of Object on screen
PS5DTA: dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*36)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB5ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 6
;********************************************************************
PSB6X:	dc.w    95+46      	; (O_XPOS)      X-Pos of Object on screen
PSB6Y:	dc.w    290			; (O_YPOS)      Y-Pos of Object on screen
PS6DTA: dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB6ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 7
;********************************************************************
PSB7X:	dc.w    95+46+46	; (O_XPOS)      X-Pos of Object on screen
PSB7Y:	dc.w    290			; (O_YPOS)      Y-Pos of Object on screen
PS7DTA:	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*42)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB7ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER SELECT BOX 8
;********************************************************************
PSB8X:	dc.w    95+46+46+46	; (O_XPOS)      X-Pos of Object on screen
PSB8Y:	dc.w    290			; (O_YPOS)      Y-Pos of Object on screen
PS8DTA: dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*32)*30)
	    	dc.w    32          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    32/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    32/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
PSB8ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; PLAYER 1 CURSOR OBJECT
;********************************************************************
CUR1X:	dc.w    93			; (O_XPOS)      X-Pos of Object on screen
CUR1Y:	dc.w    204  		; (O_YPOS)      Y-Pos of Object on screen
	    	dc.l    MEM_RAM+((320*240)*2)+((208*128)*2)+((64*480)*2)+((164*14)*2)+((200*82)*2)+((32*768)*2)
	    	dc.w    38          ; (O_HEIGHT)    Height of Object in Pixels
	    	dc.w    36/4 		; (O_IWIDTH)    Width of Objects in Phrases
	    	dc.w    36/4 		; (O_DWIDTH)    Offset to next line of Objects in Phrases
	    	dc.b    4       	; (O_FLAGS)     0=NORMAL, HFLIP =1, RMW=2, TRANS=4 RELEASE =8
	    	dc.b    0       	; (O_FIRSTPIX)  override how many bits at the beginning of a Object
				dc.b   	0       	; (O_TYPE)      Object Flags (-1=OFF 0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
	    	dc.b    4       	; (O_DEPTH)     Count of colors of the Object
	    	dc.b    1       	; (O_PITCH)		Pitch
	    	dc.b    0       	; (O_INDEX)     Index in CLUT for Objects with Color Palette
	    	dc.w    $20     	; (O_SCALE)     Remainder
				dc.b    32      	; (Y_SCALE)
				dc.b    32      	; (X_SCALE)
CUR1ACT:dc.w	0
				dc.b	0
				dc.b	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.w	0
				dc.b	0
				dc.b	0
				dc.l	0
        dc.l	0
;********************************************************************
; 320X240 TEXT SCREEN OBJECT                                        *
;********************************************************************
		dc.w    21      ; (O_XPOS)      X-Pos Object auf dem Bildschirm
		dc.w    42      ; (O_YPOS)      Y-Pos Object auf dem Bildschirm
		dc.l    MEM_TEXT; (O_DATA)      Adresse der Object Daten
		dc.w    240     ; (O_HEIGHT)    Hoehe des Objects in Pixel
		dc.w    320/4   ; (O_IWIDTH)    Breite des Objects in Phrases
		dc.w    320/4   ; (O_DWIDTH)    Offset zur n�chsten Linie des Objects in Phrases
		dc.b    4       ; (O_FLAGS)     Flags wie Object gezeichnet werden soll
		dc.b    0       ; (O_FIRSTPIX)  wieviele Bits am Anfang der Object Daten uebergehen
		dc.b    0       ; (O_TYPE)      Object Flags (0=Bitmap, 1=Scale, 2=GPU, 3=Branch, 4=Stop)
		dc.b    4       ; (O_DEPTH)     Anzahl Farben des Objects
		dc.b    1       ; (O_PITCH)     Pitch
		dc.b    0       ; (O_INDEX)     Index in CLUT fuer Objecte mit Farbpalette
		dc.w    $20     ; (O_SCALE)     Remainder
		dc.b    30      ;               Y-Scaling Faktor
		dc.b    30      ;               X-Skaling Faktor
TXTACT: dc.w	0		; ACTIVE
		dc.b	0		; KIND
		dc.b	0		; HITS
		dc.w	0		; REAL_WIDTH
		dc.w	0		; REAL_HEIGHT
		dc.w	0		; D_X
		dc.w	0		; D_Y
		dc.w	0		; FREE1
		dc.w	0		; FREE2
		dc.w	0		; FREE3
		dc.w	0		; FREE4
		dc.w	0		; FREE5
		dc.b	0		; FREE6
		dc.b	0		; SCALE_COUNTER
		dc.l	0		; ANIMATION
		dc.l	0		; SCALING

        .QPHRASE

;*******************************************************************
;** VARIABLES                                                     **
;*******************************************************************

BEAM_ANMCOUNT:		dc.w	0

; COLLISION VARIABLES

OBJ1X:      	dc.w    0
OBJ2X:      	dc.w    0
OBJ1Y:      	dc.w    0
OBJ2Y:      	dc.w    0
OBJ1H:      	dc.w    0
OBJ1W:      	dc.w    0
OBJ2H:      	dc.w    0
OBJ2W:      	dc.w    0

; GENERAL PURPOSE COUNTER

COUNTER:    dc.w    0

; PLAYER SCORES

P1SCORE:    dc.l    0
P2SCORE:		dc.l    0
P3SCORE:		dc.l    0
P4SCORE:		dc.l    0

; PLAYER CURSOR POSITIONS

P1_CURSOR_POS:	dc.b	1			  ; from left to right which pos..
P1_CURSOR_ROW:	dc.b	1			  ; row we are on (1=top, 2= bottom row)
P1_SELECTED_FLAG: dc.b	0			; IF THIS IS SET THEN PLAYER 1 DID SELECT A CHARACTER

P2_CURSOR_POS:	dc.b	2
P2_CURSOR_ROW:	dc.b	1

P3_CURSOR_POS:	dc.b	3
P3_CURSOR_ROW:	dc.b	1

P4_CURSOR_POS:	dc.b	4
P4_CURSOR_ROW:	dc.b	1

;***********************************************************************
;FILE INCLUDES
;***********************************************************************

	.qphrase

SHOTDTA:		incbin  "gfx/shot.rgb"

;***********************************************************************

	.QPHRASE
gpu_text:				dc.l	0
	.QPHRASE
anz_objects:    dc.w    0
	.QPHRASE
gpu_obj_data:		dc.l	title_list
	.QPHRASE
gpu_a_vdb:			dc.l	0
	.QPHRASE

	.END
