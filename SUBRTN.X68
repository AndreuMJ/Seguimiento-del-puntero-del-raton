
; ==============================================================================
; SUBROUTINES
; ==============================================================================

; ------------------------------------------------------------------------------
HWDINIT
; INITIALIZES HARDWARE DEVICES AS FOLLOWS:
; * DISABLES ALL MASKABLE INTERRUPTS
; * ENABLES EXCEPTION PROCESSING
; * SETS SCREEN RESOLUTION TO SCRWIDTH X SCRHEIGH (BOTH ARE GLOBAL CONSTANTS)
; * SETS WINDOWED MODE
; * ENABLES DOUBLE BUFFER
; * CLEARS THE HIDDEN BUFFER 
; * SWITCH BUFFERS (REPAINT SCREEN TASK)
; * INSTALLS TRAPS AS FOLLOWS:
;   -> ROUTINE HWDDBUF GOES TO TRAP NUMBER TRNUPDBF
;   -> ROUTINE HWDPLOT GOES TO TRAP NUMBER TRNPLGFX
; * INSTALLS HWDRMOU FOR INTERRUPT NUMBER INTRDMOU  
; * ENABLES MOUSE IRQ FOR MOUSE MOVE, BUTTON UP AND BUTTON DOWN
; * ENABLES INTERRUPTS FROM INTRDMOU TO 7 
; * SWITCHES TO USER MODE
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; ------------------------------------------------------------------------------

    ;Salvar registros que vamos a usar
    MOVEM.L D0-D1,-(A7)

    ;---Desactiva interrupciones---
    OR.W  #$0700, SR

    ;---Habilitar excepciones---
    MOVE.B  #32,D0
    MOVE.B  #05,D1
    TRAP    #15

    ;---Inicializar salida gráfica (SCRWIDTH x SCRHEIGH)---
    MOVE.B  #33,D0
    MOVE.L  #SCRWIDTH<<16|SCRHEIGH,D1
    TRAP    #15

    ;---Poner modo ventana---
    MOVE.L  #1,D1
    TRAP    #15
    
    ;---Activar doble buffer---
    MOVE.B  #92,D0
    MOVE.B  #17,D1
    TRAP    #15
    
    ;---Limpiar ventana---
    MOVE.B  #11,D0
    MOVE.W  #$FF00,D1
    TRAP    #15
    
    ;---Cambiar buffers---
    MOVE.B  #94,D0
    TRAP    #15
    
    ;---Poner HWDDBUF en TRNUPDBF---
    MOVE.L  #HWDDBUF,($80+TRNUPDBF*4)    ;Instalar en el TRAP#TRNUPDBF
    
    ;---Poner HWDPLOT en TRNPLGFX---
    MOVE.L  #HWDPLOT,($80+TRNPLGFX*4)    ;Instalar en el TRAP#TRNPLGFX
    
    ;---Instalar ISR HWDRMOU en INTRDMOU---
    MOVE.L  #HWDRMOU,($60+INTRDMOU*4)    ;Instalar ISR del mouse en TRAP#INTRDMOU
    
    ;---Activar IRQ ratón con nivel #INTRDMOU---
    MOVE.B  #60,D0
    MOVE.W  #INTRDMOU<<8|$07,D1          ;para boton arriba, boton abajo y mover
    TRAP    #15
    
    ;---Activar interrupciones de nivel #INTRDMOU---
    AND.W  #$F8FF, SR          ;limpia el nivel de interrupcion anterior
    OR.W   #(INTRDMOU<<8),SR   ;ponemos nivel INTRDMOU en las interrupciones


    ;Restaurar registros
    MOVEM.L (A7)+,D1-D0
    
    ;---Cambiar a modo usuario---
    MOVE.W  SR, -(A7)  ;Guardamos registro de estados en la pila
    AND.W #$DFFF,(A7)  ;Pasamos a modo usuario en la pila con el and 


    RTE                  ;Usamos RTE para cambiar el SR y volver
    
; ------------------------------------------------------------------------------
HWDPLOT
; TRAP SERVICE ROUTINE TO PLOT THE FOLLOWING. X, Y AND F ARE DEFINED IN "INPUT".
; * TWO GREEN LINES, ONE HORIZONTAL AND ONE VERTICAL CROSSING AT (X,Y) POINT.
;   THE HORIZONTAL LINE OCCUPIES ALL THE SCREEN HORIZONTALLY AND THE VERTICAL
;   LINE OCCUPIES ALL THE SCREEN VERTICALLY.
; * A CIRCLE CENTERED AT (X,Y). CIRCLE CONTOUR IS GREEN. CIRCLE FILL IS
;   GREEN IF F==0 OR RED IF F==1.
; THE FOLLOWING CONSTANTS (ALREADY DEFINED) HAVE TO BE USED:
; * CLRGREEN : COLOR CODE (BGR FORMAT) FOR GREEN
; * CLRRED   : COLOR CODE (BGR FORMAT) FOR RED
; * RADCIRD  : RADIUS OF THE CIRCLE CENTERED AT (X,Y)
; * SCRWIDTH : SCREEN WIDTH
; * SCRHEIGH : SCREEN HEIGHT
; INPUT    : D7.L - Y (16 MOST SIGNIFICANT BITS), X (16 LEAST SIGNIFICANT BITS)
;            D6 BIT 0 - F
; OUTPUT   : NONE
; MODIFIES : NONE
; ------------------------------------------------------------------------------

    ;Salvar registros.
    MOVEM.L D0-D7,-(A7)

    ;---Sacar X,Y---
    MOVE.L  D7,D0
    MOVE.W  D0,D5          ;D5 = X
    SWAP    D0             ;cambiamos word alto por el bajo
    MOVE.W  D0,D7          ;D7 = Y

    ;---Establecer pen color = verde---
    MOVE.B  #80,D0
    MOVE.L  #CLRGREEN,D1
    TRAP    #15

    ;---Dibujar línea horizontal en Y---
    MOVE.B  #84,D0
    MOVE.W  #0,D1          ;de X=0
    MOVE.W  D7,D2          ;Y=D7
    MOVE.W  #SCRWIDTH-1,D3 ;a X=final pantalla
    MOVE.W  D7,D4          ;Y=D7
    TRAP    #15

    ;---Dibujar línea vertical en X---
    MOVE.B  #84,D0
    MOVE.W  D5,D1          ;de X=D5
    MOVE.W  #0,D2          ;Y=0
    MOVE.W  D5,D3          ;a X=D5
    MOVE.W  #SCRHEIGH-1,D4 ;Y=final de pantalla
    TRAP    #15

    ;---Dibujar el cículo---
    MOVE.W  D5,D1            ;D1 = X
    SUB.W   #RADCIRC,D1      ;izquierda
    MOVE.W  D7,D2            ;D2 = Y
    SUB.W   #RADCIRC,D2      ;arriba
    MOVE.W  D5,D3            ;D3 = X
    ADD.W   #RADCIRC,D3      ;derecha
    MOVE.W  D7,D4            ;D4 = Y
    ADD.W   #RADCIRC,D4      ;abajo
    
    MOVEM.W D1-D4,-(A7)      ;guardar medidas del círculo

    ;---Contorno del círculo verde---
    MOVE.B  #91,D0
    TRAP    #15              

    ;---Relleno: elegir color según F---
    BTST    #0,D6
    BEQ.S   .fill_green

    ;---Relleno rojo---
    MOVE.B  #81,D0    
    MOVE.L  #CLRRED,D1       ;set fill rojo
    TRAP    #15
    BRA.S   .do_fill

.fill_green:
    MOVE.B  #81,D0          
    MOVE.L  #CLRGREEN,D1     ;set fill verde
    TRAP    #15

    ;---Rellenar el círculo---
.do_fill:
    MOVE.B  #88,D0
    
    MOVEM.W (A7)+,D1-D4      ;restaurar medidas del círculo
    
    TRAP    #15

    ;Restaurar registros
    MOVEM.L (A7)+,D0-D7

    ;Volver de TRAP
    RTE


; ------------------------------------------------------------------------------
HWDDBUF
; TRAP SERVICE ROUTINE TO UPDATE DOUBLE BUFFER AS FOLLOWS:
; * SWITCH BUFFERS (REPAINT SCREEN IN THE MANUAL)
; * CLEARS HIDDEN BUFFER. 
; INPUT    : NONE
; OUTPUT   : NONE
; MODIFIES : NONE
; ------------------------------------------------------------------------------

    ;Salvar registros que vamos a usar
    MOVEM.L D0/D1,-(A7)
    
    ;---Cambiar buffers---
    MOVE.B  #94,D0
    TRAP    #15
    
    ;---Limpiar ventana---
    MOVE.B  #11,D0
    MOVE.W  #$FF00,D1
    TRAP    #15

    ;Restaurar registros
    MOVEM.L (A7)+,D1/D0

    RTE
    
; ------------------------------------------------------------------------------
HWDRMOU
; ISR TO READ THE MOUSE
; INPUT    : NONE
; OUTPUT   : VARIABLE HWDMOUPX (WORD) - MOUSE X COORDINATE
;            VARIABLE HWDMOUPY (WORD) - MOUSE Y COORDINATE
;            VARIABLE HWDMOUBT (BYTE) - BIT0=LEFT MOUSE BUTTON PRESSED.
;                                       BIT1..7=UNDEFINED.
; MODIFIES : NONE
; ------------------------------------------------------------------------------

    ;Salvar registros que vamos a usar
    MOVEM.L D0/D1,-(A7)
    
    ;---Estado del ratón---
    MOVE.B  #61,D0
    CLR.B   D1
    TRAP    #15         ;con un trap sabemos si el boton está pulsado y las coordenadas
    ;---Boton pulsado---
    MOVE.B  D0,HWDMOUBT ;en D0 tenemos si el boton esta pulsado el btn izq del ratón en el bit0
    ;---Sacar las coordenadas---
    MOVE.W  D1,HWDMOUPX ;coordenada x
    SWAP D1             ;cambiamos word alto por word bajo
    MOVE.W  D1,HWDMOUPY ;coordenada y
        
    ;Restaurar registros
    MOVEM.L (A7)+,D1/D0

    RTE






*~Font name~Fixedsys~
*~Font size~18~
*~Tab type~0~
*~Tab size~4~
