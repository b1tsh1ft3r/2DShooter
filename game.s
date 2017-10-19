	.TEXT
	.68000

;*******************************************************************
;** SETUP STAGE
;*******************************************************************

SETUP_STAGE::
	move.w	#55,num_objects			; We want to display 55 Objects
  lea		  gpu_obj_data,a0
  lea		  game_list,a1 			; Move the Addess of "start_data" (our OBJ List) into gpu_obj_data.
  move.l  a1,(a0)

	jsr		  start_gpu
	stop    #$2000

; -----------------------------------------------------------------

		move.l	#LEVEL1_ROM,lzinbuf		; DECOMPRESS LEVEL 1 BACKGROUND
		move.l	#MEM_RAM,lzoutbuf		; DESTINATION
		move.l	#MEM_BUFFER,lzworkbuf	; BUFFER LOCATION
		move.l	#delzss,G_PC
		move.l	#1,G_CTRL			    ; DECOMPRESS!!
		bsr     WAITGPU				    ; WAIT FOR GPU TO BE DONE...

    lea     BACKGROUND,a0
    move.w  #0,XPOS(a0)
    move.w  #32,YPOS(a0)            ; SET Y POSITION OF GRAPHIC ON SCREEN
    move.w  #440/4,O_IWIDTH(a0)
    move.w  #440/4,O_DWIDTH(a0)
	  move.l  #MEM_RAM,DATA(a0)		; POINT TO GRAPHICS LOCATION
	  move.w  #1,ACTIVE(a0)   		; TURN ON BACKGROUND OBJECT

    lea     PLAYER1,a0
    move.w  #(440/2)-12,XPOS(a0)    ; SET XPOS
    move.w  #(480/2)-48,YPOS(a0)    ; SET YPOS
    move.b  #1,DIRECTION(a0)        ; SET DIRECTION
    move.w  #0,STATE(a0)            ; SET STATE STANDING
    move.w  #8,BULLETSPEED(a0)      ; SPEED THE BULLETS TRAVEL AT
    move.w  #2,SPEED(a0)            ; SET PLAYER MOVE SPEED (2 IS LOWEST IT CAN BE)
    move.w  #4,ROF(a0)              ; DELAY BETWEEN EACH SPAWNED BULLET FROM GUN
    move.w  #1,ACTIVE(a0)           ; TURN ON PLAYER 1 OBJECT

    lea     GAME_TEXT,a0
  	move.w  #1,ACTIVE(a0)   				   ; TURN ON TEXT SCREEN

    jsr     WAIT2
    jsr     WAIT2

    ; make 4 test enemy objects

    move.b  #1,d0                   ; SET ENEMY TYPE (1 = GREEN ALIEN)
    move.w  #24,d1                  ; SET XPOS
    move.w  #50,d2                  ; SET YPOS
    move.b  #2,d3                   ; SET DIRECTION (RIGHT / EAST)
    move.w  #100,d4                 ; SET HEALTH
    jsr     SPAWN_ENEMY             ; SPAWN AN ENEMY

    move.b  #1,d0                   ; SET ENEMY TYPE (1 = GREEN ALIEN)
    move.w  #24*2,d1                ; SET XPOS
    move.w  #50,d2                  ; SET YPOS
    move.b  #2,d3                   ; SET DIRECTION (RIGHT / EAST)
    move.w  #100,d4                 ; SET HEALTH
    jsr     SPAWN_ENEMY             ; SPAWN AN ENEMY

    move.b  #1,d0                   ; SET ENEMY TYPE (1 = GREEN ALIEN)
    move.w  #24*4,d1                ; SET XPOS
    move.w  #50,d2                  ; SET YPOS
    move.b  #2,d3                   ; SET DIRECTION (RIGHT / EAST)
    move.w  #100,d4                 ; SET HEALTH
    jsr     SPAWN_ENEMY             ; SPAWN AN ENEMY

    move.b  #1,d0                   ; SET ENEMY TYPE (1 = GREEN ALIEN)
    move.w  #24*6,d1                ; SET XPOS
    move.w  #50,d2                  ; SET YPOS
    move.b  #2,d3                   ; SET DIRECTION (RIGHT / EAST)
    move.w  #100,d4                 ; SET HEALTH
    jsr     SPAWN_ENEMY             ; SPAWN AN ENEMY

;*******************************************************************
;** GAME LOOP													  **
;*******************************************************************

GAME_LOOP:
    lea     PLAYER1,a0              ; POINT TO PLAYER 1 OBJ TO MANIPULATE
   	jsr		  JOYPAD_INPUT			      ; GET PLAYER INPUT
    jsr     ANIMATE_PLAYER          ; UPDATE PLAYER ANIMATIONS AFTER ALL MOVEMENT
    jsr     ANIMATE_ENEMY           ; ANIMATE ENEMIES
    jsr     MOVE_ENEMY              ; MOVE ENEMIES
	  jsr		  MOVE_SHOTS				      ; MOVE SHOT OBJECTS AROUND ON SCREEN IF ANY
	  jsr	  	wait_int				        ; WAIT A FRAME
	  bra	  	GAME_LOOP				        ; LOOP FOREVER

;*******************************************************************
;** JOYSTICK INPUT
;*******************************************************************

JOYPAD_INPUT:
	jsr     readpad			; SCAN JOYPAD PORT FOR INPUT
	move.l  joycur,d0		; READ CURRENTLY PRESSED BUTTONS

.JOYPAD_FIRE:
  btst.l  #FIRE_B,d0
  beq.s   .DPAD_UP
  move.w  ROF(a0),d0          ; load players rate of fire to d0
  cmp.w   SHOTCOUNT(a0),d0    ; see if our counter is greater or euqal to rate of fire
  beq.s   .OK2FIRE            ; MAKE SHOT IF EQUAL
  add.w   #1,SHOTCOUNT(a0)    ; IF NOT, THEN INCREASE SHOT COUNTER
  bra.s   .DPAD_UP            ; CHECK REST OF DPAD
.OK2FIRE:
  move.w  #0,SHOTCOUNT(a0)    ; CLEAR SHOT COUNTER.
	move.w  XPOS(a0),d1			; LOAD IN PLAYER X POSITION
	move.w  YPOS(a0),d2			; LOAD IN PLAYER Y POSITION
	move.b  DIRECTION(a0),d3 	; LOAD DIRECTION
	move.w  BULLETSPEED(a0),d4  ; LOAD RATE OF FIRE
	bsr		  MAKE_SHOT		    ; MAKE THE SHOT!!

.DPAD_UP:
	btst.l  #JOY_UP,d0
	beq.s	  .DPAD_DOWN

	cmp.w   #40,YPOS(a0)	; AT TOP OF SCREEN?
	ble.s	  .DPAD_DOWN		; CHECK NEXT DPAD DIRECTION IF SO
	move.w  #1,STATE(a0)	; SET STATE TO WALKING
  move.b  #1,DIRECTION(a0); set direction
  move.w  SPEED(a0),d1
	sub.w   d1,YPOS(a0)     ; MOVE PLAYER UP

.DPAD_DOWN:
	btst.l  #JOY_DOWN,d0
	beq.s	  .DPAD_LEFT

	cmp.w   #(240*2)-28,YPOS(a0); AT BOTTOM OF SCREEN?
	bge.s	.DPAD_LEFT			; CHECK NEXT DPAD DIRECTION IF SO
 	move.w  #1,STATE(a0)		; SET STATE TO WALKING
  move.b  #2,DIRECTION(a0); set direction
  move.w  SPEED(a0),d1
	add.w   d1,YPOS(a0)

.DPAD_LEFT:
	btst.l  #JOY_LEFT,d0
	beq.s	.DPAD_RIGHT

	cmp.w   #6,XPOS(a0)	    ; AT LEFT EDGE OF SCREEN?
	ble.s	.DPAD_RIGHT		; CHECK NEXT DPAD DIRECTION IF SO
	move.w  #1,STATE(a0)	; SET STATE TO WALKING
  move.b  #3,DIRECTION(a0); set direction
  move.w  SPEED(a0),d1
  sub.w   #1,d1           ; offset for x axis
	sub.w   d1,XPOS(a0)

.DPAD_RIGHT:
	btst.l  #JOY_RIGHT,d0
	beq.s	.JOYPAD_DONE

	cmp.w   #440-28,XPOS(a0)	; AT RIGHT EDGE OF SCREEN?
	bge.s	.JOYPAD_DONE		; CHECK NEXT BUTTON IF SO
 	move.w  #1,STATE(a0)	; SET STATE TO WALKING
  move.b  #4,DIRECTION(a0); set direction
  move.w  SPEED(a0),d1
  sub.w   #1,d1           ; offset for x axis
	add.w   d1,XPOS(a0)

.JOYPAD_DONE:
  tst.l	d0                ; all joypad buttons released?
  bne.s   .JOYPAD_EXIT    ; if not, just exit

  ;if we got here all buttons on joypad released...

  move.l  #00000000,ANIMATION(a0)     ; CLEAR ANIMATION POINTER
  move.w  #0,STATE(a0)				; SET STATE = STANDING
  clr.b   ANIMFLAG(a0)                ; CLEAR ANIMATION BYTE FLAG ENTIRELY

.JOYPAD_EXIT:
  rts

;*******************************************************************
;** SPAWN ENEMY
;*******************************************************************

SPAWN_ENEMY:
    lea     ENEMY_TABLE,a6      ; POINT TO LIST OF USEABLE SHOT OBJECTS
.FIND_ENEMY:
    move.l  (a6)+,a1            ; LOAD OBJECT TO A1 (WHILE INCREMENTING A0 TO POINT TO NEXT ONE)
    cmp.l   #-1,a1              ; SEE IF END OF LIST OF OBJECTS REACHED.
    beq.s   .NO_FREE_ENEMY      ; IF WE LOAD A NEGATIVE (-1 FOR INSTANCE AT END OF LIST) THEN EXIT..
    cmp.w   #0,ACTIVE(a1)       ; SEE IF OBJECT IS OFF?
    bne.s   .FIND_ENEMY         ; OBJECT WE CHECKED ISNT FREE, FIND ANOTHER...
.DETERMINE_ENEMY_TYPE:          ; OTHERWISE USE THIS OBJECT!!
    cmp.b   #1,d0               ; IS ENEMY WE WERE TOLD TO CREATE IN D1 REGISTER A GREEN ALIEN?
    beq     .MAKE_GREEN_ALIEN   ; SETUP GREEN ALIEN
    rts

.MAKE_GREEN_ALIEN:
    move.b  d0,TYPE(a1)         ; STORE TYPE OF ENEMY WITH THIS OBJECT
    move.w  d1,XPOS(a1)         ; SET XPOS OF ENEMY
    move.w  d2,YPOS(a1)         ; SET YPOS OF ENEMY
    move.b  d3,DIRECTION(a1)    ; SET STATE OF ENEMY OBJECT
    move.w  d5,HEALTH(a1)       ; SET HEALTH OF ENEMY

    move.w  #1,SPEED(a1)        ; SET GREEN ALIEN SPEED
	  move.w  #24,HEIGHT(a1)		; SET HEIGHT
	  move.w  #24/4,O_IWIDTH(a1)	; WIDTH
	  move.w  #24/4,O_DWIDTH(a1)	; WIDTH AGAIN...

    jsr     SET_TARGET          ; TARGET A LIVE PLAYER (1 - 4)
    cmp.b   #1,d0               ; DID WE FIND A PLAYER?
    bne.s   .NO_FREE_ENEMY      ; DONT SPAWN THE ENEMY THEN, WE COULDNT TARGET A PLAYER TO HAVE HIM CHASE AFTER

    move.l  a0,TARGET(a1)       ; STORE PLAYER THIS ENEMY IS TARGETING
    move.w  #-1,STATE(a1)       ; SET STATE TO -1 TO TELL ANIMATION ROUTINE TO GOTO SPAWNING STATE.
	  move.w  #1,ACTIVE(a1)		    ; TURN ON ENEMY!
    rts

.NO_FREE_ENEMY:
	rts

;*******************************************************************
;** ANIMATE ENEMY
;*******************************************************************

ANIMATE_ENEMY:
    lea     ENEMY_TABLE,a6      ; POINT TO LIST OF ENEMIES
CHECK_ENEMY:
    move.l  (a6)+,a1            ; LOAD ENEMY OBJECT TO A1 (WHILE INCREMENTING A0 TO POINT TO NEXT ONE)
    cmp.l   #-1,a1              ; SEE IF END OF LIST OF OBJECTS REACHED.
    beq     NO_ENEMY_ANIMATE    ; IF WE LOAD A NEGATIVE (-1 FOR INSTANCE AT END OF LIST) THEN EXIT..
    cmp.w   #1,ACTIVE(a1)       ; SEE IF OBJECT IS ON?
    bne.s   CHECK_ENEMY         ; OBJECT WE CHECKED ISNT FREE, FIND ANOTHER...
ANIMATE_ENEMY_TYPES:            ; OTHERWISE ANIMATE THIS ENEMY
    cmp.b   #1,TYPE(a1)         ; ENEMY TYPE = GREEN ALIEN?
    beq     ANIMATE_GREEN_ALIEN
    bra     CHECK_ENEMY         ; DO THIS FOR ALL ENEMY OBJECTS UNTIL DONE...

ANIMATE_GREEN_ALIEN:
    cmp.w   #-1,STATE(a1)       ; IS THIS A NEWLY CREATED ENEMY? IF SO LETS DUMP IT INTO STATE 0 (SPAWNING)
    beq     GREEN_ALIEN_CREATED ; DO STUFF FOR ENEMY JUST BEING CREATED
    cmp.w   #0,STATE(a1)        ; IS ENEMY IN SPAWN STATE?
    beq.s   GREEN_ALIEN_SPAWN   ; DO STUFF FOR ENEMY SPAWNING STATE
    cmp.w   #1,STATE(a1)        ; IS ENEMY WALKING STATE?
    beq     GREEN_ALIEN_WALKING ; DO STUFF FOR ENEMY WALKING STATE
    bra     CHECK_ENEMY
;------------------------------------------------------------------------
GREEN_ALIEN_CREATED:
	cmp.b	#1,DIRECTION(a1)
	beq		.GREEN_CREATEUP
	cmp.b	#2,DIRECTION(a1)
	beq		.GREEN_CREATEDN
	cmp.b	#3,DIRECTION(a1)
	beq		.GREEN_CREATELF
	cmp.b	#4,DIRECTION(a1)
	beq		.GREEN_CREATERT
	bra     CHECK_ENEMY
.GREEN_CREATEUP:
	move.l  #NME1_SPANW_UP,ANIMATION(A1)    ; LOAD IN SPAWNING ANIMATION
  move.w  #0,STATE(a1)                    ; SET STATE TO SPAWNING...
	bra     CHECK_ENEMY
.GREEN_CREATEDN:
	move.l  #NME1_SPANW_DN,ANIMATION(A1)    ; LOAD IN SPAWNING ANIMATION
  move.w  #0,STATE(a1)                    ; SET STATE TO SPAWNING...
	bra     CHECK_ENEMY
.GREEN_CREATELF:
	move.l  #NME1_SPANW_LF,ANIMATION(A1)    ; LOAD IN SPAWNING ANIMATION
  move.w  #0,STATE(a1)                    ; SET STATE TO SPAWNING...
	bra     CHECK_ENEMY
.GREEN_CREATERT:
	move.l  #NME1_SPANW_RT,ANIMATION(A1)    ; LOAD IN SPAWNING ANIMATION
  move.w  #0,STATE(a1)                    ; SET STATE TO SPAWNING...
.GREEN_ALIEN_EXIT_CREATE:
  bra     CHECK_ENEMY
;-------------------------------------------------------------------------
GREEN_ALIEN_SPAWN:
	cmp.b	#1,DIRECTION(a1)
	beq		.GREEN_SPAWNUP
	cmp.b	#2,DIRECTION(a1)
	beq		.GREEN_SPAWNDN
	cmp.b	#3,DIRECTION(a1)
	beq		.GREEN_SPAWNLF
	cmp.b	#4,DIRECTION(a1)
	beq		.GREEN_SPAWNRT
	bra     CHECK_ENEMY
.GREEN_SPAWNUP:
  cmp.l   #NME1SPAWN_ROM+((24*24)*6),DATA(a1)     ; ENEMY SHOWING LAST FRAME OF SPAWN UP ANIMATION?
  bne.s   .GREEN_ALIEN_EXIT_SPAWN
  move.w  #1,STATE(a1)                            ; SET STATE TO WALKING (SEEKING PLAYER)
	bra     CHECK_ENEMY
.GREEN_SPAWNDN:
  cmp.l   #NME1SPAWN_ROM+((24*24)*34),DATA(a1)    ; ENEMY SHOWING LAST FRAME OF SPAWN DN ANIMATION?
  bne.s   .GREEN_ALIEN_EXIT_SPAWN
  move.w  #1,STATE(a1)                            ; SET STATE TO WALKING (SEEKING PLAYER)
	bra     CHECK_ENEMY
.GREEN_SPAWNLF:
  cmp.l   #NME1SPAWN_ROM+((24*24)*46),DATA(a1)    ; ENEMY SHOWING LAST FRAME OF SPAWN LF ANIMATION?
  bne.s   .GREEN_ALIEN_EXIT_SPAWN
  move.w  #1,STATE(a1)                            ; SET STATE TO WALKING (SEEKING PLAYER)
	bra     CHECK_ENEMY
.GREEN_SPAWNRT:
  cmp.l   #NME1SPAWN_ROM+((24*24)*22),DATA(a1)    ; ENEMY SHOWING LAST FRAME OF SPAWN RT ANIMATION?
  bne.s   .GREEN_ALIEN_EXIT_SPAWN
  move.w  #1,STATE(a1)                            ; SET STATE TO WALKING (SEEKING PLAYER)
.GREEN_ALIEN_EXIT_SPAWN:
	bra     CHECK_ENEMY
;-------------------------------------------------------------------------
GREEN_ALIEN_WALKING:
  cmp.b   #24,ANIMFLAG(a1)                        ; this adjusts delay between spwan animation and jumping into walk animation
  bge.s   OK_GREEN_ALIEN_WALKING
  add.b   #1,ANIMFLAG(a1)
	bra     CHECK_ENEMY
OK_GREEN_ALIEN_WALKING:
	cmp.b	#1,DIRECTION(a1)
	beq		.GREEN_WALKUP
	cmp.b	#2,DIRECTION(a1)
	beq		.GREEN_WALKDN
	cmp.b	#3,DIRECTION(a1)
	beq		.GREEN_WALKLF
	cmp.b	#4,DIRECTION(a1)
	beq		.GREEN_WALKRT
	bra     CHECK_ENEMY
.GREEN_WALKUP:
  move.l  #NME1_WALK_UP,ANIMATION(a1)
  move.w #2,STATE(a1)                            ; SET STATE TO SEEKING
  move.b  #0,ANIMFLAG(a1)                        ; CLEAR ANIMATION SPAWN DELAY FLAG
	bra     CHECK_ENEMY
.GREEN_WALKDN:
  move.l  #NME1_WALK_DOWN,ANIMATION(a1)
  move.w #2,STATE(a1)                            ; SET STATE TO SEEKING
  move.b  #0,ANIMFLAG(a1)                        ; CLEAR ANIMATION SPAWN DELAY FLAG
	bra     CHECK_ENEMY
.GREEN_WALKLF:
  move.l  #NME1_WALK_LEFT,ANIMATION(a1)
  move.w  #2,STATE(a1)                            ; SET STATE TO SEEKING
  move.b  #0,ANIMFLAG(a1)                        ; CLEAR ANIMATION SPAWN DELAY FLAG
	bra     CHECK_ENEMY
.GREEN_WALKRT:
  move.l  #NME1_WALK_RIGHT,ANIMATION(a1)
  move.w #2,STATE(a1)                            ; SET STATE TO SEEKING
  move.b  #0,ANIMFLAG(a1)                        ; CLEAR ANIMATION SPAWN DELAY FLAG
.GREEN_ALIEN_EXIT_WALK:
	bra     CHECK_ENEMY
;-------------------------------------------------------------------------
NO_ENEMY_ANIMATE:
	rts

;*******************************************************************
;** MOVE ENEMIES
;*******************************************************************

MOVE_ENEMY:
    lea     ENEMY_TABLE,a6      ; POINT TO LIST OF RANDOM SORTER ORDER FOR ALL 4 PLAYERS
.FIND_ENEMY:
    move.l  (a6)+,a1            ; LOAD OBJECT TO A1 (WHILE INCREMENTING A0 TO POINT TO NEXT ONE)
    cmp.l   #-1,a1              ; SEE IF END OF LIST OF OBJECTS REACHED.
    beq     .MOVE_ENEMY_EXIT    ; IF WE LOAD A NEGATIVE (-1 FOR INSTANCE AT END OF LIST) THEN EXIT..
    cmp.w   #0,ACTIVE(a1)       ; SEE IF OBJECT IS ON?
    beq.s   .FIND_ENEMY         ; OBJECT WE CHECKED ISNT FREE, FIND ANOTHER...
.MOVE_ENEMY:                    ; OTHERWISE USE THIS OBJECT!!
    cmp.w   #2,SHOTCOUNT(a1)    ; WE USE SHOTCOUNT VARIABLE ON OBJ BECAUSE ALIENS ARENT SHOOTING...
    bge     .OK2MOVE            ; SEE IF WE HAVE REACHED THE DELAY SO WE CAN MOVE THE ENEMY.
    add.w   #1,SHOTCOUNT(a1)
    bra     .FIND_ENEMY         ; FIND OTHER ENEMIES NOW UNTIL NO MORE...
.OK2MOVE:

 ;   a1 = pointing to the enemy

	move.w  #0,SHOTCOUNT(a1)    ; ZERO THE COUNTER AGAIN
  move.l  TARGET(a1),a2       ; point to player target that this object is following

	move.w  XPOS(a1),d0			    ; MOVE ENEMY X TO D0
	move.w  YPOS(a1),d1		    	; MOVE ENEMY Y TO D1
	move.w  XPOS(a2),d2		      ; MOVE TARGET X TO D2
	move.w  YPOS(a2),d3		      ; MOVE TARGET Y TO D3
.finalchkx:
	cmp.w   d0,d2				        ; SEE IF TESTX IS EQUAL TO WAYPOINT X
	beq.s	.finalchky			      ; IF SO, THEN CHECK Y TO MAKE SURE ITS DONE...
	bra.s	.CHKX				          ; if not lets update player x pos until it is...
.finalchky:
	cmp.w   d1,d3				        ; SEE IF TESTY IS EQUAL TO WAYPOINT Y
	bne.s	.CHKX				          ; IF NOT THEN LETS UPDATE THE POSITIONS
	bra		.WAYDONE			        ; exit..
.CHKX:
	cmp.w   d2,d0				        ; COMPARE PLAYER X TO waypoint X
	blt.s	.addx				          ; if player x less than waypoint x, then add to player x
	cmp.w   d2,d0				        ; COMPARE PLAYER X TO waypoint X
	bgt.s	.subx				          ; if player x more than waypoint x, then subtract from player x
	bra.s	.CHKY				          ; IF WE GOT HERE, WE ARE ON WAYPOINT X, SO CHECK WAYPOINT Y...
.addx:
  add.w   SPEED(a1),d0        ; ADD ENEMY SPEED TO X AXIS
  move.b  #4,DIRECTION(a1)    ; SET DIRECTION LEFT
  move.w  #1,STATE(a1)        ; SET STATE WALKING SO ANIMATION PICKS UP THE CHANGES
	bra.s	.CHKY				          ; NOW check Y waypoint...
.subx:
  sub.w   SPEED(a1),d0        ; SUBTRACT ENEMY SPEED FROM X AXIS
  move.b  #3,DIRECTION(a1)    ; SET DIRECTION LEFT
  move.w  #1,STATE(a1)        ; SET STATE WALKING SO ANIMATION PICKS UP THE CHANGES
.CHKY:
	cmp.w   d3,d1				        ; COMPARE PLAYER Y TO ENEMY Y
	blt.s	.addy				          ; if player y less than ENEMY y, then add
	cmp.w   d3,d1				        ; COMPARE PLAYER Y TO ENEMY Y
	bgt.s	.suby				          ; if player y more than waypoint y, then subtract
	bra.s	.way_update			      ; we are done checking x and y if we got here. So go and store values into player x/y
.addy:
  add.w   SPEED(a1),d1        ; ADD ENEMY SPEED TO ENEMY Y AXIS
  move.b  #2,DIRECTION(a1)    ; SET DIRECTION DOWN
  move.w  #1,STATE(a1)        ; SET STATE WALKING SO ANIMATION PICKS UP THE CHANGES
	bra.s   .way_update
.suby:
	sub.w   SPEED(a1),d1		    ; SUBTRACT ENEMEY SPEED FROM Y AXIS
  move.b  #1,DIRECTION(a1)    ; SET DIRECTION UP
  move.w  #1,STATE(a1)        ; SET STATE WALKING SO ANIMATION PICKS UP THE CHANGES
.way_update:
	move.w  d0,XPOS(a1)			    ; STORE CORRECTED X POSITION INTO SELECTED PLAYER X POS
	move.w  d1,YPOS(a1)         ; STORE CORRECTED Y POSITION INTO SLEECTED PLAYER Y POS
.WAYDONE:
	bra     .FIND_ENEMY         ; FIND OTHER ENEMIES NOW UNTIL NO MORE...

.MOVE_ENEMY_EXIT:
    rts

;*******************************************************************
;** UPDATE PLAYER ANIMATIONS
;*******************************************************************
; Based on value in STATE, WE UPDATE ANIMATIONS

ANIMATE_PLAYER:
  cmp.w   #1,ACTIVE(a0)
  bne.s   .NO_ANIMATE_PLAYER

	cmp.w	#0,STATE(a0)				; SEE IF STATE = STANDING
	beq		.STANDING_ANIM

	cmp.w	#1,STATE(a0)				; SEE IF STATE = WALKING
	beq		.WALKING_ANIM

.NO_ANIMATE_PLAYER:
	rts

;-------------------------------------------------------------------

.STANDING_ANIM:
	cmp.b	#1,DIRECTION(a0)
	beq		.STANDUP
	cmp.b	#2,DIRECTION(a0)
	beq		.STANDDN
	cmp.b	#3,DIRECTION(a0)
	beq		.STANDLF
	cmp.b	#4,DIRECTION(a0)
	beq		.STANDRT
	rts

.STANDUP:
	move.l #BBWALK_ROM+((24*24)*4),DATA(a0)
	rts
.STANDDN:
	move.l #BBWALK_ROM+((24*24)*24),DATA(a0)
	rts
.STANDLF:
	move.l #BBWALK_ROM+((24*24)*34),DATA(a0)
	rts
.STANDRT:
	move.l #BBWALK_ROM+((24*24)*14),DATA(a0)
	rts

;-------------------------------------------------------------------

.WALKING_ANIM:
  cmp.b	#1,DIRECTION(a0)
	beq		.WALKUP
	cmp.b	#2,DIRECTION(a0)
	beq		.WALKDN
	cmp.b	#3,DIRECTION(a0)
	beq		.WALKLF
	cmp.b	#4,DIRECTION(a0)
	beq		.WALKRT
  rts

.WALKUP:
  cmp.b   #%01000000,ANIMFLAG(a0)
  beq.s   .WALK_DONE
	move.l 	#BBWALK_UP,ANIMATION(a0)
  clr.b   ANIMFLAG(a0)                   ; CLEAR BITS IN FLAG FOR ANIMATION (0,0,0,0)
  move.b  #%01000000,ANIMFLAG(a0)         ; (1,0,0,0)
  rts
.WALKDN:
  cmp.b   #%00010000,ANIMFLAG(a0)
  beq.s   .WALK_DONE
	move.l 	#BBWALK_DOWN,ANIMATION(a0)
  clr.b   ANIMFLAG(a0)                   ; CLEAR BITS IN FLAG FOR ANIMATION (0,0,0,0)
  move.b  #%00010000,ANIMFLAG(a0)         ; (0,1,0,0)
	rts
.WALKLF:
  cmp.b   #%00000100,ANIMFLAG(a0)
  beq.s   .WALK_DONE
	move.l 	#BBWALK_LEFT,ANIMATION(a0)
  clr.b   ANIMFLAG(a0)                   ; CLEAR BITS IN FLAG FOR ANIMATION (0,0,0,0)
  move.b  #%00000100,ANIMFLAG(a0)         ; (0,0,1,0)
	rts
.WALKRT:
  cmp.b   #%00000001,ANIMFLAG(a0)
  beq.s   .WALK_DONE
	move.l 	#BBWALK_RIGHT,ANIMATION(a0)
  clr.b   ANIMFLAG(a0)                   ; CLEAR BITS IN FLAG FOR ANIMATION (0,0,0,0)
  move.b  #%00000001,ANIMFLAG(a0)         ; (0,0,0,1)
	rts
.WALK_DONE:
  rts

;*******************************************************************
;** MAKE SHOT
;*******************************************************************
; ROUTINE ASSUMES PRE-LOADED WITH THE FOLLOWING DATA TO RUN..
; d0 (b) =  PLAYER SPECIFIC OK2SHOOT FLAG
; d1 (b) =  PLAYER X POSITION
; d2 (b) =  PLAYER Y POSITION
; d3 (b) =  PLAYER DIRECTION THEY ARE FACING/TRAVELING
; d4 (w) =  PLAYER SHOT SPEED (FOR WEAPON VARIATION STUFF)
; a0 = used
; a1 = used

MAKE_SHOT:
; NOW ADD OFFSET TO SHOT OBJECTS COORDINATES BASED ON DIRECTION PLAYER IS FACING
; ------------------------------------------------------------------------------

.SHOT_OFFSET:
	cmp.b   #1,d3				; DIRECTION FACING UP?
	beq		.UP_OFFSET
	cmp.b   #2,d3				; DIRECTION FACING DOWN?
	beq		.DN_OFFSET
	cmp.b   #3,d3				; DIRECTION FACING LEFT?
	beq.s	.LF_OFFSET
	bra.s	.RT_OFFSET			; IF WE GOT HERE ITS RIGHT...

.UP_OFFSET:						; POSITION SHOT IN FRONT OF PLAYER
	add.w    #9,d1
	sub.w    #8,d2
	bra.s	 .CREATE_SHOT
.DN_OFFSET:						; POSITION SHOT BELOW PLAYER
	add.w    #8,d1
	add.w    #40,d2
	bra.s	 .CREATE_SHOT
.LF_OFFSET:						; POSITION SHOT TO LEFT OF PLAYER
	sub.w    #4,d1
	add.w    #18,d2
	bra.s	 .CREATE_SHOT
.RT_OFFSET:						; POSITION SHOT TO RIGHT OF PLAYER
	add.w    #20,d1
	add.w    #18,d2

; FIND AN AVAILABLE SHOT OBJECT AND USE IT!!
; ------------------------------------------

.CREATE_SHOT:
    lea     SHOT_TABLE,a6       ; POINT TO LIST OF USEABLE SHOT OBJECTS
.FIND_SHOT:
    move.l  (a6)+,a1            ; LOAD OBJECT TO A1 (WHILE INCREMENTING A0 TO POINT TO NEXT ONE)
    cmp.l   #-1,a1              ; SEE IF END OF LIST OF OBJECTS REACHED.
    beq.s   .NO_FREE_SHOTS      ; IF WE LOAD A NEGATIVE (-1 FOR INSTANCE AT END OF LIST) THEN EXIT..
    cmp.w   #0,ACTIVE(a1)       ; SEE IF OBJECT IS OFF?
    bne.s   .FIND_SHOT          ; OBJECT WE CHECKED ISNT FREE, FIND ANOTHER...
.USE_OBJECT:                    ; OTHERWISE USE THIS OBJECT!!
	move.w  d4,SPEED(a1)   		; STORE SHOT 1 SPEED
	move.b  d3,DIRECTION(a1)	; SET SHOT DIRECTION
	move.w  d1,XPOS(a1)         ; SET SHOT X-POSITION
	move.w  d2,YPOS(a1)	    	; SET SHOT Y-POSTION
	move.w  #8,HEIGHT(a1)		; SET HEIGHT OF SHOT
	move.w  #8/4,O_IWIDTH(a1)	; WIDTH
	move.w  #8/4,O_DWIDTH(a1)	; WIDTH AGAIN...
	move.l  #SHOTDTA,DATA(a1)	; POINT TO SHOT GRAPHICS
	move.w  #1,ACTIVE(a1)		; TURN ON SHOT OBJECT
.NO_FREE_SHOTS:
	rts

;*******************************************************************
;** MOVE SHOTS
;*******************************************************************

MOVE_SHOTS:
    lea     SHOT_TABLE,a0        ; POINT TO LIST OF USEABLE SHOT OBJECTS
.MOVE_CHECK_ACTIVE:
    move.l  (a0)+,a1            ; LOAD OBJECT TO A1 (WHILE INCREMENTING A0 TO POINT TO NEXT ONE)
    cmp.l   #-1,a1              ; SEE IF END OF LIST OF OBJECTS REACHED.
    beq     .MOVE_SHOTS_EXIT    ; IF WE LOAD A NEGATIVE (-1 FOR INSTANCE AT END OF LIST) THEN EXIT..
    cmp.w   #1,ACTIVE(a1)       ; SEE IF OBJECT IS OFF?
    bne.s   .MOVE_CHECK_ACTIVE  ; OBJECT WE CHECKED ISNT ACTIVE, CHECK OTHERS...
.MOVE_SHOT:
    cmp.b   #1,DIRECTION(a1)    ; IS DIRECTION UP?
    beq     .MOVE_SHOT_UP
    cmp.b   #2,DIRECTION(a1)    ; IS DIRECTION DOWN?
    beq     .MOVE_SHOT_DN
    cmp.b   #3,DIRECTION(a1)    ; IS DIRECTION LEFT?
    beq     .MOVE_SHOT_LF
    bra     .MOVE_SHOT_RT       ; MUST BE RIGHT (ONLY OTHER DIRECTION AT THIS POINT)
.MOVE_SHOT_UP:
	cmp.w   #-8,YPOS(a1)		; OFF TOP OF SCREEN?
	ble		.TURNOFF_SHOT		; KILL IT!
  move.w  SPEED(a1),d0
  sub.w   d0,YPOS(a1)      	; OTHERWISE MOVE IT
  bra     .MOVE_CHECK_ACTIVE  ; DO MORE SHOTS UNTIL DONE...
.MOVE_SHOT_DN:
	cmp.w   #488,YPOS(a1)		; OFF BOTTOM OF SCREEN?
	bge		.TURNOFF_SHOT		; KILL IT!
  move.w  SPEED(a1),d0
	add.w   d0,YPOS(a1)			; OTHERWISE MOVE IT
	bra		.MOVE_CHECK_ACTIVE	; CHECK NEXT SHOT...
.MOVE_SHOT_LF:
	cmp.w   #-8,XPOS(a1)    	; OFF LEFT OF SCREEN?
	ble		.TURNOFF_SHOT   	; KILL IT!
  move.w  SPEED(a1),d0
	sub.w   d0,XPOS(a1)			; OTHERWISE MOVE IT
	add.w   #2,XPOS(a1)			; to normalize speed of shots on horizontal axis
	bra		.MOVE_CHECK_ACTIVE  ; CHECK NEXT SHOT...
.MOVE_SHOT_RT:
	cmp.w   #440+8,XPOS(a1)		; OFF RIGHT OF SCREEN?  (THGIS IS SETUP FOR 440X240)
	bge		.TURNOFF_SHOT		; KILL IT!
  move.w  SPEED(a1),d0
	add.w   d0,XPOS(a1)			; OTHERWISE MOVE IT
	sub.w   #2,XPOS(a1)			; to normalize speed of shots on horizontal axis
	bra		.MOVE_CHECK_ACTIVE	; CHECK NEXT SHOT...
.TURNOFF_SHOT:
  move.w  #0,ACTIVE(a1)       ; TURN OFF SHOT
  move.w  #0,SPEED(a1)        ; CLEAR OUT SPEED OF SHOT
  bra     .MOVE_CHECK_ACTIVE
.MOVE_SHOTS_EXIT:
  rts

;*******************************************************************
;** SET TARGET (ENEMY FIND PLAYER FROM RANDOM LIST)               **
;*******************************************************************

SET_TARGET:
    lea     PLAYER_TABLE,a6     ; POINT TO LIST OF PLAYERS
CHECK_PLAYERS:
    move.l  (a6)+,a0            ; LOAD ENEMY OBJECT TO A1 (WHILE INCREMENTING A0 TO POINT TO NEXT ONE)
    cmp.l   #-1,a0              ; SEE IF END OF LIST OF OBJECTS REACHED.
    beq.s   .TARGETING_FAILED   ; IF WE LOAD A NEGATIVE (-1 FOR INSTANCE AT END OF LIST) THEN EXIT..
    cmp.w   #1,ACTIVE(a0)       ; SEE IF OBJECT IS ON?
    bne.s   CHECK_PLAYERS       ; OBJECT WE CHECKED ISNT FREE, FIND ANOTHER...
.DONE_TARGETING_PLAYERS:
    move.b  #1,d0               ; 1= success!!  a0 has contents of a valid live player
    rts
.TARGETING_FAILED:
    move.b  #0,d0               ; 0 = failure, dont use contents of a0
    rts

    .QPHRASE

;*******************************************************************
;** OBJECT LIST
;*******************************************************************
;game_list:

; relocated to game_objlist.s

        .QPHRASE

;*******************************************************************
;** VARIABLES													  **
;*******************************************************************

; list of all shot objects that can be used.

PLAYER_TABLE:   dc.l    PLAYER1,PLAYER2,PLAYER3,PLAYER4,PLAYER4,PLAYER3,PLAYER2,PLAYER1,PLAYER2,PLAYER4,PLAYER1,PLAYER3,PLAYER3,PLAYER1,PLAYER4,PLAYER2,-1

ENEMY_TABLE:    dc.l    ENEMY01,ENEMY02,ENEMY03,ENEMY04,ENEMY05,ENEMY06,ENEMY07,ENEMY08,ENEMY09,ENEMY10,ENEMY11,ENEMY12,ENEMY13,ENEMY14,ENEMY15,ENEMY16,-1

SHOT_TABLE:     dc.l    SHOT01,SHOT02,SHOT03,SHOT04,SHOT05,SHOT06,SHOT07,SHOT08,SHOT09,SHOT10,SHOT11,SHOT12,SHOT13,SHOT14,SHOT15,SHOT16
                dc.l    SHOT17,SHOT18,SHOT19,SHOT20,SHOT21,SHOT22,SHOT23,SHOT24,SHOT25,SHOT26,SHOT27,SHOT28,SHOT29,SHOT30,SHOT31,SHOT32,-1

;*******************************************************************

	.END
