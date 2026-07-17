; Adapted from https://gbdev.io/gb-asm-tutorial/part1/hello_world.html
INCLUDE "hardware.inc"

SECTION "Header", ROM0[$0100]

    nop                     ; Required first instruction
    jp Start                ; Jump to our program

    ds $0150 - @, 0         ; Fill remaining cartridge header space

SECTION "Main", ROM0


Start:

.waitVBlank:

    ld a, [$FF44]           ; LY register = current LCD line

    cp 144                  ; Have we reached VBlank?

    jr c, .waitVBlank       ; If LY < 144, keep waiting

    xor a                   ; A = 0

    ld [$FF40], a           ; LCDC = 0
                            ; Screen is now disabled


    ld hl, SmileyTile       ; Source address in ROM

    ld de, $8000            ; Destination address in VRAM

    ld bc, 16               ; Copy 16 bytes

.copyTile:

    ld a, [hl+]             ; Load byte from ROM
                            ; HL automatically increases

    ld [de], a              ; Store byte into VRAM

    inc de                  ; Move VRAM pointer forward

    dec bc                  ; One less byte copied

    ld a, b                 ; Check if BC == 0

    or c

    jr nz, .copyTile        ; Continue until all 16 bytes copied



;============================================================
; CREATE A BLANK TILE
;============================================================

; Tile 1 will be our empty background tile.
;
; We fill it with white pixels.
;
; Tile 0 = smiley
; Tile 1 = blank
;------------------------------------------------------------


    ld hl, $8010            ; Tile 1 starts after tile 0

    ld b, 16                ; Tile is 16 bytes


.clearTile:

    xor a                   ; A = 0

    ld [hl+], a             ; Write blank pixel data

    dec b

    jr nz, .clearTile



;============================================================
; CLEAR THE BACKGROUND MAP
;============================================================

; Background map:
;
; $9800-$9BFF
;
; 32 x 32 tile positions
;
; We fill every position with tile 1 (blank)
;
; This prevents the smiley from covering the whole screen.
;------------------------------------------------------------


    ld hl, $9800            ; Start of background map

    ld bc, 1024             ; 32*32 entries

    ld a, 1                 ; Use blank tile


.clearBackground:


    ld [hl+], a             ; Put blank tile

    dec bc                  ; One less position


    ld a, b

    or c

    ld a, 1                 ; Restore blank tile number

    jr nz, .clearBackground



;============================================================
; PLACE SMILEY IN CENTER
;============================================================

; Visible screen:
;
; 20 tiles wide
; 18 tiles tall
;
; Center:
;
; X = 10
; Y = 9
;
; Address:
;
; $9800 + (Y * 32) + X
;
; $9800 + 288 + 10
;
; $992A

;move up by subtracting 32, aka decimal 2 from the 3rd place digit 99(2)A
;move down by adding 32
;move right by adding 1
;move left by subtracting 1
;------------------------------------------------------------


    ld a, 0                 ; Tile number 0 = smiley

    ld [$992A], a           ; Put smiley in center



;============================================================
; SET COLOR PALETTE
;============================================================


    ld a, %11100100

    ld [$FF47], a            ; Background palette



;============================================================
; TURN LCD BACK ON
;============================================================

    ld a, %10010001

; Bit 7 = LCD ON
; Bit 4 = Tile data at $8000
; Bit 0 = Background enabled

    ld [$FF40], a



;============================================================
; INFINITE LOOP
;============================================================


;-----------------------------------------------
ld HL, $992A            ;store current position of the player
ld e, 0                 ;default paint

Forever:
    ;call chooseTile
    ld [HL], e           ; Put smiley in center
    ld a, %00100000      ;a = to read direction input
    ld [$FF00], a        ;ask to read input
    ld a, [$FF00]
    ld a, [$FF00]        ;retrieve input

    bit 0, a             ;if bit 0 = 0, means right key has been pressed
    call z, moveRight    ;moveRight if right key has been pressed
    bit 1, a             ;if bit 1 = 0, means left key has been pressed
    call z, moveLeft     ;moveLeft if left key has been pressed
    bit 2, a
    call z, moveUp
    bit 3, a
    call z, moveDown
    jr Forever

chooseTile:
  ld a, %00010000
  ld [$FF00], a
  ld a, [$FF00]
  ld a, [$FF00]
  bit 3, a        ;if enter is pressed
  call z, swapMode
  ret

swapMode:
  ld a, e
  xor 1
  ld e, a
  call waitForRelease
  ret


moveRight:
  inc HL
  call waitForRelease
  ret

moveLeft:
  dec HL
  call waitForRelease
  ret

moveUp:
  ld BC, -32   ;load -32 into BC
  add HL, BC   ;for some reason adding only works with 2 reg cant be normal num
  call waitForRelease
  ret

moveDown:
  ld BC, 32
  add HL, BC
  call waitForRelease
  ret


waitForRelease:         ;so number addition does not get spammed and numbers go wild
   ld a, %00100000      ;a = to read direction input
   ld [$FF00], a        ;ask to read input
   ld a, [$FF00]
   ld a, [$FF00]        ;retrieve input
   bit 0, a             ;if bit 0 = a, means right key has been pressed
   jr z, waitForRelease ;if right key is pressed, z is set, so loop again
   bit 1, a
   jr z, waitForRelease ;same Logic as above
   bit 2, a
   jr z, waitForRelease
   bit 3, a
   jr z, waitForRelease
   
   ld a, %00010000   ;check for action input
   ld [$FF00], a
   ld a, [$FF00]
   ld a, [$FF00]
   bit 3, a
   jr z, waitForRelease   ;,make sure shift is not pressed
   
   ret                ;passing all checks meaning all numbers are 1 means new buttons can be pressed
   
  
  ;00100000 = disable actions, so direction is on
  ;00010000 = disable directions, so actions is on
  
  ;when directions is on:
  ;if bit 0 is 0, move right
  ;if bit 1 is 0, move left
  ;if bit 2 is 0, move up
  ;if bit 3 is 0, move down

  ;when actions is on:
  ;if bit 0 is 0, S
  ;if bit 1 is 0, A
  ;if bit 2 is 0, Shift
  ;if bit 3 is 0, Enter



;============================================================
; TILE DATA
;============================================================

SmileyTile:

; Each row:
;
; Byte 1 = low color bit
; Byte 2 = high color bit
;
; 00 = white
; 11 = black
;
; Since both bytes are equal,
; pixels are either white or black.
;------------------------------------------------------------
db $FF, $FF
db $81, $81
db $A5, $A5
db $81, $81
db $A5, $A5
db $BD, $BD
db $81, $81
db $FF, $FF
