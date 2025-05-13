;------------------------
; Assembly Code
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
    SBI   DDRB, 3         ;pin PB3 o/p for servo control

    SBI   DDRB, 2           ; PB2 = output
    CBI   DDRD, 2           ; PD2 = input

    LDI   R16, (1 << ISC01) ; Falling edge
    STS   EICRA, r16

    LDI   R16, (1 << INT0)  ; Enable INT0
    OUT   EIMSK, r16

    SEI                     ; Enable global interrupts
;---------------------------------------------------------------
agn:RCALL I2C_init          ;initialize TWI module
    RCALL I2C_listen        ;listen to bus to be addressed
    RCALL I2C_read          ;read data byte
    MOV   R26, R27
    RCALL angle_to_timer
    RCALL  rotate_servo1
    RCALL I2C_init          ;initialize TWI module
    RCALL I2C_listen        ;listen to bus to be addressed
    RCALL I2C_read          ;read data byte
    MOV   R26, R27
    RCALL angle_to_timer
    RCALL  rotate_servo2
    RJMP agn
;==============================================================
angle_to_timer:
    CPI R26, 180
    BREQ angle_180

    CPI R26, 45
    BRLT ang_lt_45

    CPI R26, 90
    BRLT ang_lt_90

    CPI R26, 135
    BRLT ang_lt_135

    ; angle < 180
ang_lt_180:
    SUBI R26, 135          ; angle - 135
    MOV R20, R26
    LDI R21, 70
    MUL R20, R21           ; R1:R0 = (angle-135) * 70
    LDI R22, 45
    MOV R18, R0
    CLR R19
    RCALL divide_16u
    LDI R26, 110
    ADD R26, R18
    RET

angle_180:
    LDI R26, 180
    RET

ang_lt_135:
    SUBI R26, 90
    MOV R20, R26
    LDI R21, 20
    MUL R20, R21
    LDI R22, 45
    MOV R18, R0
    CLR R19
    RCALL divide_16u
    LDI R26, 90
    ADD R26, R18
    RET

ang_lt_90:
    SUBI R26, 45
    MOV R20, R26
    LDI R21, 20
    MUL R20, R21
    LDI R22, 45
    MOV R18, R0
    CLR R19
    RCALL divide_16u
    LDI R26, 70
    ADD R26, R18
    RET

ang_lt_45:
    MOV R20, R26
    LDI R21, 30
    MUL R20, R21
    LDI R22, 45
    MOV R18, R0
    CLR R19
    RCALL divide_16u
    LDI R26, 40
    ADD R26, R18
    RET
divide_16u:
    CLR R18
    CLR R17
    LDI R16, 16
div_loop:
    LSL R19
    ROL R18
    ROL R17
    CP  R17, R22
    BRLO skip_sub
    SUB R17, R22
    INC R18
skip_sub:
    DEC R16
    BRNE div_loop
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
rotate_servo1:
;------------
    LDI   R20, 10         ;count to give enough cycles of PWM
l1: SBI   PORTB, 4
    RCALL delay_timer0
    CBI   PORTB, 4        ;send msec pulse to rotate servo
    RCALL delay_20ms      ;wait 20ms before re-sending pulse
    DEC   R20
    BRNE  l1              ;go back & repeat PWM signal
    RCALL delay_ms        ;0.5s delay
    RET
rotate_servo2:
;------------
    LDI   R20, 10         ;count to give enough cycles of PWM
l2: SBI   PORTB, 3
    RCALL delay_timer0
    CBI   PORTB, 3        ;send msec pulse to rotate servo
    RCALL delay_20ms      ;wait 20ms before re-sending pulse
    DEC   R20
    BRNE  l2              ;go back & repeat PWM signal
    RCALL delay_ms        ;0.5s delay
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
;===============================================================
delay_ms:                 ;delay 0.5s
    LDI   R21, 255
l7 :LDI   R22, 255
l8 :LDI   R23, 41
l9 :DEC   R23
    BRNE  l9
    DEC   R22
    BRNE  l8
    DEC   R21
    BRNE  l7
    RET