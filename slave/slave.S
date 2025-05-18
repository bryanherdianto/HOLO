;------------------------
; HOLO (Horizon-Oriented Laser Output)
;------------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
#include "avr/interrupt.h"
;------------------------
.global main
.global __vector_1
;===============================================================
main:
;-----------
    SBI   DDRB, 4         ;pin PB4 o/p for servo control
    SBI   DDRB, 0         ;pin PB0 o/p for servo control

    SBI   DDRB, 2           ; PB2 = output
    CBI   DDRD, 2           ; PD2 = input

    LDI   R16, (1 << ISC01) ; Falling edge
    STS   EICRA, r16

    LDI   R16, (1 << INT0)  ; Enable INT0
    OUT   EIMSK, r16

    LDI   R31, 0

    SEI                     ; Enable global interrupts
;---------------------------------------------------------------
agn:CLR   R27
    RCALL I2C_init          ;initialize TWI module
    RCALL I2C_listen        ;listen to bus to be addressed
    
    ; First, check if this is a valid message for us
    LDS   R21, TWSR        ;get TWI status
    ANDI  R21, 0xF8        ;mask prescaler bits
    CPI   R21, 0x60        ;SLA+W received, ACK sent?
    BRNE  agn              ;if not, restart
    
    ; Now read the angle byte
    RCALL I2C_read          ;read angle byte
    MOV   R26, R27
    
    ; Read the second byte (servo selection)
    RCALL I2C_read          ;read servo selection byte
    MOV   R31, R27          ;store in R31 (0=servo1, 1=servo2)
    
    ; Wait for STOP condition
    LDI   R21, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    STS   TWCR, R21
    
    RCALL angle_to_timer

    CPI   R31, 0
    BRNE  rotate_servo2
    RJMP  rotate_servo1
;==============================================================
rotate_servo2:
;------------
    LDI   R20, 10         ;count to give enough cycles of PWM
l2: SBI   PORTB, 0
    RCALL delay_timer0
    CBI   PORTB, 0        ;send msec pulse to rotate servo
    RCALL delay_20ms      ;wait 20ms before re-sending pulse
    DEC   R20
    BRNE  l2              ;go back & repeat PWM signal
    CLR   R26
    RJMP  agn
rotate_servo1:
;------------
    LDI   R20, 10         ;count to give enough cycles of PWM
l1: SBI   PORTB, 4
    RCALL delay_timer0
    CBI   PORTB, 4        ;send msec pulse to rotate servo
    RCALL delay_20ms      ;wait 20ms before re-sending pulse
    DEC   R20
    BRNE  l1              ;go back & repeat PWM signal
    CLR   R26
    RJMP  agn
/*
; FOR PROTEUS CIRCUIT
angle_to_timer:
    ; Check specific angle cases first
    CPI   R26, 0
    BRNE  not_0
    LDI   R26, 61
    RET
not_0:
    CPI   R26, 45
    BRNE  not_45
    LDI   R26, 77
    RET
not_45:
    CPI   R26, 90
    BRNE  not_90
    LDI   R26, 93
    RET
not_90:
    CPI   R26, 135
    BRNE  not_135
    LDI   R26, 108
    RET
not_135:
    CPI   R26, 180
    BRNE  interpolate
    LDI   R26, 127
    RET
;-----------------------------------------------------------
interpolate:
    ; Determine the angle range
    CPI   R26, 45
    BRLT  range_0_45

    CPI   R26, 90
    BRLT  range_45_90

    CPI   R26, 135
    BRLO  range_90_135

    CPI   R26, 180
    BRLO  range_135_180

    LDI   R26, 127
    RET
;------------------- 0° to 45° : 61 to 77
range_0_45:
    ; PWM = 61 + angle * 16 / 45
    MOV   R20, R26        ; angle
    LDI   R21, 16
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 61
    ADD   R26, R18
    RET

;------------------- 45° to 90° : 77 to 93
range_45_90:
    SUBI  R26, 45         ; angle - 45
    ; PWM = 77 + (angle * 16 / 45)
    MOV   R20, R26
    LDI   R21, 16
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 77
    ADD   R26, R18
    RET

;------------------- 90° to 135° : 93 to 108
range_90_135:
    SUBI  R26, 90
    ; PWM = 93 + (angle * 15 / 45)
    MOV   R20, R26
    LDI   R21, 15
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 93
    ADD   R26, R18
    RET
;------------------- 135° to 180° : 108 to 127
range_135_180:
    SUBI  R26, 135
    ; PWM = 108 + (angle * 19 / 45)
    MOV   R20, R26
    LDI   R21, 19
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 108
    ADD   R26, R18
    RET
*/
; FOR PHYSICAL CIRCUIT
angle_to_timer:
    ; Direct matches first
    CPI   R26, 0
    BRNE  not_0
    LDI   R26, 35
    RET
not_0:
    CPI   R26, 45
    BRNE  not_45
    LDI   R26, 65
    RET
not_45:
    CPI   R26, 90
    BRNE  not_90
    LDI   R26, 95
    RET
not_90:
    CPI   R26, 135
    BRNE  not_135
    LDI   R26, 130
    RET
not_135:
    CPI   R26, 180
    BRNE  interpolate
    LDI   R26, 158
    RET
; -----------------------------------------------------------
interpolate:
    CPI   R26, 45
    BRLT  range_0_45
    CPI   R26, 90
    BRLT  range_45_90
    CPI   R26, 135
    BRLO  range_90_135
    CPI   R26, 180
    BRLO  range_135_180
    LDI   R26, 158
    RET
; 0°-45°: 35-65
range_0_45:
    MOV   R20, R26        ; R20 = angle
    LDI   R21, 30         ; slope numerator
    MUL   R20, R21
    LDI   R22, 45         ; slope denominator
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 35
    ADD   R26, R18
    RET
; 45°-90°: 65-95
range_45_90:
    SUBI  R26, 45
    MOV   R20, R26
    LDI   R21, 30
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 65
    ADD   R26, R18
    RET
; 90°-135°: 95-130
range_90_135:
    SUBI  R26, 90
    MOV   R20, R26
    LDI   R21, 35
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 95
    ADD   R26, R18
    RET
; 135°-180°: 130-158
range_135_180:
    SUBI  R26, 135
    MOV   R20, R26
    LDI   R21, 28
    MUL   R20, R21
    LDI   R22, 45
    MOV   R18, R0
    MOV   R19, R1
    RCALL simple_div
    LDI   R26, 130
    ADD   R26, R18
    RET
; Input: R19:R18 = 16-bit dividend, R22 = 8-bit divisor
; Output: R18 = quotient
simple_div:
    CLR   R17          ; Clear remainder
    LDI   R16, 16      ; 16 bits to process
div_loop:
    LSL   R18          ; Shift low byte left, bit 7 to carry
    ROL   R19          ; Shift high byte left with carry
    ROL   R17          ; Shift remainder left with carry
    
    CP    R17, R22     ; Compare remainder with divisor
    BRLO  skip_sub     ; If remainder < divisor, skip subtraction
    
    SUB   R17, R22     ; Subtract divisor from remainder
    INC   R18          ; Set result bit to 1
skip_sub:
    DEC   R16          ; Decrement bit counter
    BRNE  div_loop     ; If not done, continue loop
    RET
I2C_init:
    LDI   R21, 0b10010000
    STS   TWAR, R21         ;store slave address 0b10010000
    LDI   R21, (1<<TWEN)
    STS   TWCR, R21         ;enable TWI
    LDI   R21, (1<<TWINT)|(1<<TWEN)|(1<<TWEA)
    STS   TWCR, R21         ;enable TWI & ACK
    RET
;==============================================================
I2C_listen:
    LDS   R21, TWCR
    SBRS  R21, TWINT
    RJMP  I2C_listen        ;wait for slave to be addressed
    RET
;==============================================================
I2C_read:
    LDI   R21, (1<<TWINT)|(1<<TWEA)|(1<<TWEN)
    STS   TWCR, R21         ;enable TWI & ACK
    ;----------------------------------------------------------
wt: LDS   R21, TWCR
    SBRS  R21, TWINT
    RJMP  wt                ;wait for data byte to be read
    ;----------------------------------------------------------
    LDS   R27, TWDR         ;store received byte
    RET
;===============================================================
__vector_1:
    sbi PINB, 2
    reti
;===============================================================
;delay subroutines
;===============================================================
delay_timer0:             ;delay via Timer0
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCNT0, R21      ;initialize timer0 with count=0
    MOV   R21, R26
    OUT   OCR0A, R21
    LDI   R21, 0b00001100
    OUT   TCCR0B, R21     ;timer0: CTC mode, prescaler 256
    ;-----------------------------------------------------------
l3: IN    R21, TIFR0      ;get TIFR0 byte & check
    SBRS  R21, OCF0A      ;if OCF0=1, skip next instruction
    RJMP  l3              ;else, loop back & check OCF0 flag
    ;-----------------------------------------------------------
    CLR   R21
    OUT   TCCR0B, R21     ;stop timer0
    ;-----------------------------------------------------------
    LDI   R21, (1<<OCF0A)
    OUT   TIFR0, R21      ;clear OCF0 flag
    RET
;===============================================================
delay_20ms:               ;delay 20ms
    LDI   R21, 255
l4: LDI   R22, 210
l5: LDI   R23, 2
l6: DEC   R23
    BRNE  l6
    DEC   R22
    BRNE  l5
    DEC   R21
    BRNE  l4
    RET