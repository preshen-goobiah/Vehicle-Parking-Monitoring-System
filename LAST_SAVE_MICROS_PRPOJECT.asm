;
; Project.asm
;
; Created: 9/10/2017 3:13:47 PM
; Author : Preshen Goobiah & Marc Karp
;
.include "m328pdef.inc" // change for other devices

 
   .def temp    = r16 
   .def counter = r17 
   .def red = r18
  
   .def I = r21
   .def J = R22
   .equ a = 21 ;(16000000 / 256) / 440(frequency of A) - 1

   // change to change ports
   .equ SEG7_PORT= PORTC
   .equ SEG7_DDR = DDRC
 

.CSEG   
.ORG 0 
jmp reset


.ORG 0x002 ; interupt 0
jmp entrance_handler

.ORG 0X004 ; interupt 1
jmp exit_handler



segments: //digits 0-9
   .db 0b01000000, 0b01110011, 0b00001001, 0b00001100
   .db 0b0010110, 0b10100100, 0b00100000, 0b01011100
   .db 0b00000000, 0b00010100

RESET:

    LDI	temp,LOW(RAMEND) ; Set up stack - needed for sub-routines
OUT	SPL,temp
LDI	temp,HIGH(RAMEND)
OUT	SPH,temp
;	ldi Zl,low(segments * 2) ; * to convert cseg address to byte addressing 
 ;  ldi Zh,high(segments * 2)

 Ldi ZL, low(segments*2)
 LDI ZH, high(segments*2)
ser temp             ; 7-SEG Port as outputs (FFh)
   out SEG7_DDR, temp 
   ; lpm  temp, Z+

 
clr counter    
 
   
  
start_main:

ser r16
 out DDRB, R16 ; ALL OUTPUTS
sbi PORTB, 4 ; FOR MIDDLE SEG TO BE ON
 SBI PORTB, 2 ; ORANGE
 CBI PORTB, 3 ; RED OFF

// SET UP PWM FOR VARYING INTENSITY OF BEEP

ldi r16, (1<<ISC01)|(1<<ISC00)| (1<<ISC11) | (1<<ISC10); 
sts EICRA, r16 
ldi r16, (1<<int0)|(1<<int1)
out EIMSK, r16

wait:

nop
sei 
;CBI PORTB,5 ;INCLUDING THIS HERE, CAUSES THE COUNTER TO GO TO 9
sleep

sbrs red, 0
SBI PORTB, 2
jmp wait




exit_handler:
    call delay
cpi counter, 0
   breq empty
   nop
   rcall RED_OFF
   
   dec counter


     cbi PORTB, 4 ; MIDDLE 7\_SEG ALWAYS ON UNTIL 1 OR 7 OR 0
    
   
  
   sbiw z, 1
   lpm  temp, Z     ;read a byte from 'segments' and increment Z 
   out SEG7_PORT, temp ; DISPLAY NUMBER ON 7 SEG
 
   cpi counter, 0
   breq one_condition2

   cpi counter,1
   breq one_condition2
  
   cpi counter, 7
   breq one_condition2

   nop
    call BEEPER

   reti

   red_off:
   cbi PORTB, 3
   ret

  empty:
  reti
   
  one_condition2:
   sbi PORTB, 4 
   call BEEPER
   reti




entrance_handler:
// add a delay!!!


cbi PORTB, 4 ; PUT THE MIDDLE 7SEG LED ON ALWAYS
  
cpi counter, 9
brpl parking_full
nop

   inc counter
   adiw z, 1
   lpm  temp, Z     ;read a byte from 'segments' and increment Z 
   out SEG7_PORT, temp ; DISPLAY NUMBER ON 7 SEG
   

   cpi counter,1
   breq one_condition
   ;nop
   cpi counter, 7
   breq one_condition
   nop
   // GENERATE SOUND
  call BEEPER
  CBI PORTB, 2
   jmp do_nothing
   
   ; CHECK FOR  0,1,7
  
do_nothing: 
  sbi PORTB, 5
; Delay 10 000 000 cycles
; 500ms at 20 MHz
   call delay
cbi PORTB, 5
   reti


one_condition:
sbi PORTB, 4 ; MIDDLE 7 SEG
rcall delay_9ms
 
 sbi PORTB, 5 ; GREEN ON
 cbi PORTB, 2

     

   ; Delay 10 000 000 cycles
; 500ms at 20 MHz
    call delay
    cbi PORTB, 5 ; GREEN OFF 

    call BEEPER
	
   reti

   
  /* reset_counter:
   
   Ldi ZL, low(segments*2)
   LDI ZH, high(segments*2)
   lpm temp,Z+
   	OUT SEG7_PORT, temp 
sbi PORTB, 4 
    clr counter
    reti*/ ; FOR LOOPING 0-9

parking_full:

sbi PORTB, 3
cbi portb, 2
call pause
ldi red, 255
jmp wait ; RETI RETURNS TO RESET FOR SOME REASON. WANT IT TO SLEEP



delay:

    ldi  r18, 51
    ldi  r19, 187
    ldi  r20, 224
L1: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    rjmp PC+1

ret

; Delay 199 998 cycles
; 9ms 999us 900 ns at 20 MHz

delay_9ms: 
    ldi  r18, 2
    ldi  r19, 4
    ldi  r20, 186
L2: dec  r20
    brne L1
    dec  r19
    brne L1
    dec  r18
    brne L1
    rjmp PC+1
	ret



BEEPER:
  ldi r16, 0b00100011
  OUT tccr0a, r16
  ldi r16, 0b00001100
  OUT tccr0b, r16

 
  ldi temp, a
  out ocr0a, temp
  ;ocr0b = ocr0a/2 to obtain a duty cycle of 50%

  clr temp
  ldi temp, a
  sub temp, counter

   out ocr0b, temp ; DUTY CYLE

   BEEP: CLR I
   BLUPE:
                   ;TURN SPKR ON
     sbi ddrd, 5
   rcall pause
   cbi ddrd, 5
   rcall pause
     DEC I
      BRNE BLUPE
 ret


PAUSE:
     CLR J
   PLUPE:
     NOP   
     DEC J               
      BRNE PLUPE
       RET
  
