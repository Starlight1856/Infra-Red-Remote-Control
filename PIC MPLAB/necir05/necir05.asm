
;
;
;
;  NEC Protocol IR Remote Control for sound bar 
;  version 5 - internal pull-ups used
;  Paul Byrne  22nd Feb 2024
;
;#include <p16F690.inc>
#include  "C:\Program Files (x86)\Microchip\MPASM Suite\p16F690.inc"
     __config (_INTRC_OSC_NOCLKOUT & _WDT_OFF & _PWRTE_OFF & _MCLRE_OFF & _CP_OFF & _BOR_OFF & _IESO_OFF & _FCMEN_OFF)

     cblock     0x20
     Delay1              ; Assign an address to label Delay1
     Delay2
     IRAddress
     IRMessage             ; define a variable to hold the diplay
     MsgByte
     BitCount
     W_Save
     STATUS_Save
     endc

     org 0
     goto Start
     
;;--------------- ISR -------------------------
ISR:  org 0x04
      bcf      INTCON, GIE
      bcf      INTCON, RABIF
      bsf       PORTC,0             ; Turn off LED C0

      btfss     PORTA,5             ; is the switch pressed
      movlw     0x45                ; 45hex On/Off

      btfss     PORTA,4             ; is the switch pressed (0)
      movlw     0x47                ; 47hex mute

      btfss     PORTA,0             ; is the switch pressed (0)
      movlw     0x19                ; 19hex volume up

      btfss     PORTA,1             ; is the switch pressed (0)
      movlw     0x1C                ; 19hex volume down

      btfss     PORTA,2             ; is the switch pressed (0)
      movlw     0x42                ; 42hex set sound flat

      btfss     PORTB,4             ; is the switch pressed (0)
      movlw     0x44                ; 44hex set sound movie

      btfss     PORTB,5             ; is the switch pressed (0)
      movlw     0x4A                ; 4Ahex set sound music


      movwf     IRMessage
      call      SendMsg

      clrf     PORTA
      clrf     PORTB
      bcf      INTCON, RABIF

      bsf      INTCON, GIE
      retie

Start: org   0x040

     ; RP1     RP0
     ;  0       0  -> Bank 0
     ;  0       1  -> Bank 1
     ;  1       0  -> Bank 2
     ;  1       1  -> Bank 3

     bcf       STATUS,RP0          ; address Register Page 2
     bsf       STATUS,RP1   
  
     clrf      ANSEL               ; port a all digital
     clrf      ANSELH              ; port b all digital

     bsf       STATUS,RP0          ; select Register Page 1
     bcf       STATUS,RP1     

     movlw     0xFF
     movwf     TRISA               ; Make PortA all input
     movwf     TRISB               ; Make PortB all input

     movlw     B'11111100'         ; PORT C bits 0,1 outputs
     movwf     TRISC               ; Make PortC 0,1 output
   
     movlw     B'01111111'         ; bit 7 set to 0; pull ups
     movwf     OPTION_REG          ; ports A,B enabled RABPU flg

     movlw     B'11111111'         ; port A  0,1,2, 4,5 pull-ups enabled
     movwf     WPUA                ; ports A,B enabled

     movlw     B'00110111'         ; set inputs 0,1,2,4,5 portA to
     movwf     IOCA                ; interrupt-on-change

     bcf       STATUS,RP0          ; address Register Page 2
     bsf       STATUS,RP1  

     movlw     B'11111111'         ; port B  0,1,2, 4,5 pull-ups enabled
     movwf     WPUB                ; ports A,B enabled

     movlw     B'01110000'         ; set inputs 4,5 portB to
     movwf     IOCB                ; interrupt-on-change

     bcf       STATUS,RP0          ; address Register Page 0
     bcf       STATUS,RP1
  
     clrf      PORTC               ; turn off LED C0

     movlw     B'10001000'         ; set all inputs portA/B to
     movwf     INTCON              ; global iterrupt flag set
 
     clrf      BitCount            ; Looking for a 0 on the button
     movlw     0x00                ; Address is fixed
     movwf     IRAddress   
     
     movlw     0x45                ; 45hex default message
     movwf     IRMessage

  
MainLoop:
  
    sleep
   
    goto      MainLoop




;; ------------ subroutines -------------------
  
   
SendMsg: 
  
    call      SetStartPulse

    movf     IRAddress,0              ; 
    movwf     MsgByte
    call      SendByte
    comf      MsgByte,1
    call      SendByte

    movf      IRMessage,0               ; 
    movwf     MsgByte
    call      SendByte
    comf      MsgByte,1
    call      SendByte

    call      SetLogic1               ; used for final 562.5uS eom


    call      OndelayLoop
    call      OndelayLoop
    call      OndelayLoop
    bcf       PORTC,1
    return

SendByte:
     movlw     8               ; 
     movwf     BitCount   
    bcf       STATUS,C   ; clear carry flag 
NextBit:
     call      SendBit
     decfsz    BitCount,1
     goto      NextBit
     rrf       MsgByte,1
     return

SendBit:
   ;  bcf       STATUS,C   ; clear carry flag 
     rrf       MsgByte,1

     btfsc     STATUS,C
     call      SetLogic1     ; carry is clear so send logic 1

     btfss     STATUS,C
     call      SetLogic0
     return
     
  
     ; 344 pulses at 38.36 kHz
SetStartPulse:
     movlw     0xFF               ; 9mS of 38kHz 255 pulses
     movwf     Delay1
     call      nextt
     movlw     0x59               ; 89 pulese
     movwf     Delay1
     call      nextt

     movlw     0x00               ; 4.5mS space
     movwf     Delay1
     call      nextt3
     movlw     0xE9               ; 
     movwf     Delay1
     call      nextt3

     return
   
nextt:
  call      Pulse38kHz
  decfsz    Delay1,0x01
   goto      nextt   
   return

nextt2:
   call      Space38kHz
   decfsz    Delay1,0x01  
   goto      nextt2   
   return

; reconmended duty cycle 1/3 > 1/4
Pulse38kHz:
     movlw     0x02              ; 
     movwf     Delay2
     bsf       PORTC,1             ; turn on LED C0

Logic0Mark:
     decfsz    Delay2,0x01  
     goto      Logic0Mark

     movlw     0x03            ; 
     movwf     Delay2
     bcf       PORTC,1             ; Turn off LED C0
Logic0Space:
     decfsz    Delay2,0x01  
     goto      Logic0Space
     return

nextt3:
   nop
   nop
   nop
   nop
   nop
   nop
   decfsz    Delay1,0x01  
   goto      nextt3
   return

; space
Space38kHz:
     movlw     0x03              ; 
     movwf     Delay2
     bcf       PORTA,0             ; turn off LED C0

Zero0Mark:
     decfsz    Delay2,0x01  
     goto      Zero0Mark

     movlw     0x01            ; 
     movwf     Delay2
     bcf       PORTA,0             ; Turn off LED C0
Zero0Space:
     decfsz    Delay2,0x01  
     goto      Zero0Space
     return
  

SetLogic0:
     movlw     0x18              ; 562.5 uS
     movwf     Delay1
     call      nextt
  
     movlw     0x14              ; 562.5 uS space
     movwf     Delay1
     call      nextt2
     return

SetLogic1:
     movlw     0x18              ; 562.5 uS
     movwf     Delay1
     call      nextt
     movlw     0x45              ; 1687.5 uS space
     movwf     Delay1
     call      nextt2 
     return

OndelayLoop:
 
     decfsz    Delay1,f            ; Waste time.  
     goto      OndelayLoop         ; The Inner loop takes 3 instructions per loop * 256 loopss = 768 instructions

     decfsz    Delay2,f            ; The outer loop takes and additional 3 instructions per lap * 256 loops
     goto      OndelayLoop         ; (768+3) * 256 = 197376 instructions / 1M instructions per second = 0.197 sec.
                                   ; call it a two-te
     return

  end