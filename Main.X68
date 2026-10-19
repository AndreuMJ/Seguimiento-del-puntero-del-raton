; ==============================================================================
; TITLE       : PRAC2B
; DESCRIPTION : LAB ASSIGNMENT 2B (MAIN FILE)
; AUTHOR      : ANTONI BURGUERA
; HISTORY     : 13-OCTOBER-2025 - CREATION
; ==============================================================================

; ------------------------------------------------------------------------------
; CONSTANTS
; ------------------------------------------------------------------------------

; SCREEN
SCRWIDTH    EQU     640                     ; SCREEN WIDTH
SCRHEIGH    EQU     480                     ; SCREEN HEIGHT

; INTERRUPTS
INTRDMOU    EQU     7                       ; INTERRUPT NUMBER TO READ MOUSE

; TRAP
TRNUPDBF    EQU     1                       ; TRAP NUM. TO UPDATE DOUBLE BUFFER
TRNPLGFX    EQU     2                       ; TRAP NUM. TO PLOT GRAPHICS

; GRAPHICS
CLRGREEN    EQU     $0000FF00               ; GREEN BGR CODE
CLRRED      EQU     $000000FF               ; RED BGR CODE
RADCIRC     EQU     32                      ; CIRCLE RADIUS


            ORG     $1000

; ------------------------------------------------------------------------------
; CODE INCLUDES
; ------------------------------------------------------------------------------

            INCLUDE "SUBRTN.X68"

; ------------------------------------------------------------------------------
; MAIN PROGRAM
; ------------------------------------------------------------------------------

START       ; INIT HARDWARE DEVICES
            JSR     HWDINIT

.LOOP       ; GET MOUSE COORDINATES
            MOVE.L  (HWDMOUPY),D7

            ; GET MOUSE BUTTON STATE
            MOVE.B  (HWDMOUBT),D6

            ; PLOT
            TRAP    #TRNPLGFX

            ; UPDATE DOUBLE BUFFER
            TRAP    #TRNUPDBF
            BRA     .LOOP

            SIMHALT

; ------------------------------------------------------------------------------
; VARIABLES
; ------------------------------------------------------------------------------

HWDMOUPY    DS.W    1                       ; MOUSE Y COORDINATE
HWDMOUPX    DS.W    1                       ; MOUSE X COORDINATE
HWDMOUBT    DS.B    1                       ; MOUSE BUTTON STATUS
            DS.W    0

            END     START







*~Font name~Fixedsys~
*~Font size~18~
*~Tab type~0~
*~Tab size~4~
