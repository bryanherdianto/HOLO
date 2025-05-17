;------------------------
; HOLO (Horizon-Oriented Laser Output)
;------------------------
#define __SFR_OFFSET 0x00
#include "avr/io.h"
;------------------------
.global main
;===============================================================
main:
;------------
.equ  SCK, 5
.equ  MOSI, 3
.equ  SS, 2
;--------------------------------------------------------------
    LDI   R17, (1<<MOSI)|(1<<SCK)|(1<<SS)
    OUT   DDRB, R17       ;set MOSI, SCK, SS as o/p
    ;--------------------------------------------------------
    LDI   R17, (1<<SPE)|(1<<MSTR)|(1<<SPR0)
    OUT   SPCR, R17       ;enable SPI as master, fsck=fosc/16
    ;--------------------------------------------------------
    LDI   R17, 0x0A       ;set segment intensity (0 to 15)
    LDI   R18, 8          ;intensity level = 8
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x09       ;set decoding mode command
    LDI   R18, 0b00000111 ;decoding byte
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x0B       ;set scan limit command
    LDI   R18, 0x07       ;8 digits connected to MAX7219
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x0C       ;set turn ON/OFF command
    LDI   R18, 0x01       ;turn ON MAX7219
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI R16, 3
    CLR R25
    RCALL I2C_init
    RJMP  MAX7219_disp_azi
;---------------------------------------------------------------
send_bytes:
    CBI   PORTB, SS       ;enable slave device MAX7219
    OUT   SPDR, R17       ;transmit command
    ;--------------------------------------------------------
l2: IN    R19, SPSR
    SBRS  R19, SPIF       ;wait for byte transmission
    RJMP  l2              ;to complete
    ;--------------------------------------------------------
    OUT   SPDR, R18       ;transmit data
    ;--------------------------------------------------------
l3: IN    R19, SPSR
    SBRS  R19, SPIF       ;wait for byte transmission
    RJMP  l3              ;to complete
    ;--------------------------------------------------------
    SBI   PORTB, SS       ;disable slave device MAX7219
    RET
;---------------------------------------------------------------
I2C_init:
    LDI   R21, 0
    STS   TWSR, R21       ;prescaler = 0
    LDI   R21, 12         ;division factor = 12
    STS   TWBR, R21       ;SCK freq = 400kHz
    LDI   R21, (1<<TWEN)
    STS   TWCR, R21       ;enable TWI
    RET
;==============================================================
MAX7219_disp_azi:
;-----------------
    LDI   R17, 0x08       ;select digit 7
    LDI   R18, 0x77       ;data = A
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x07       ;select digit 6
    LDI   R18, 0x6D       ;data = Z
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x06       ;select digit 5
    LDI   R18, 0x06       ;data = I
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x05       ;select digit 4
    LDI   R18, 0x00       ;data = space
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x04       ;select digit 3
    LDI   R18, 0x00       ;data = space
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    RJMP  keypad
MAX7219_disp_alt:
;-----------------
    LDI   R17, 0x08       ;select digit 7
    LDI   R18, 0x77       ;data = A
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x07       ;select digit 6
    LDI   R18, 0x0E       ;data = L
    RCALL send_bytes      ;send command & data to MAX7219
    ;--------------------------------------------------------
    LDI   R17, 0x06       ;select digit 5
    LDI   R18, 0x0F       ;data = t
    RCALL send_bytes      ;send command & data to MAX7219
;===============================================================
keypad:
    LDI   R20, 0xF0       ;low nibble port D i/p (column lines)
    OUT   DDRD, R20       ;high nibble port D o/p (row lines)
    ;-----------------------------------------------------------
gnd_rows:
    LDI   R20, 0x0F       ;send 0 to high nibble port D
    OUT   PORTD, R20      ;to ground all rows
    ;-----------------------------------------------------------
wait_release:
    NOP
    IN    R21, PIND       ;read key pins
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no keypress
    BRNE  wait_release    ;do again until keys released
    ;-----------------------------------------------------------
wait_keypress:
    NOP
    IN    R21, PIND       ;read key pins
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no keypress
    BREQ  wait_keypress   ;keypress? no, go back & check
    ;-----------------------------------------------------------
    RCALL my_delay        ;delay to cancel switch bounce
    ;-----------------------------------------------------------
    IN    R21, PIND       ;2nd check for keypress
    ANDI  R21, 0x07       ;which ensures that 1st keypress
    CPI   R21, 0x07       ;was not erroneous due to spike noise
    BREQ  wait_keypress 
    ;-----------------------------------------------------------
    LDI   R21, 0b01111111 ;ground row 1
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row1_col        ;row 1, find column
    ;-----------------------------------------------------------
    LDI   R21, 0b10111111 ;ground row 2
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row2_col        ;row 2, find column
    ;-----------------------------------------------------------
    LDI   R21, 0b11011111 ;ground row 3
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row3_col        ;row 3, find column
    ;-----------------------------------------------------------
    LDI   R21, 0b11101111 ;ground row 4
    OUT   PORTD, R21
    NOP
    IN    R21, PIND       ;read all columns
    ANDI  R21, 0x07       ;mask unsed bits
    CPI   R21, 0x07       ;equal if no key
    BRNE  row4_col        ;row 4, find column
;---------------------------------------------------------------
row1_col:
    LDI   R30, lo8(row1_digits)
    LDI   R31, hi8(row1_digits)
    RJMP  find
row2_col:
    LDI   R30, lo8(row2_digits)
    LDI   R31, hi8(row2_digits)
    RJMP  find
row3_col:
    LDI   R30, lo8(row3_digits)
    LDI   R31, hi8(row3_digits)
    RJMP  find
row4_col:
    LDI   R30, lo8(row4_digits)
    LDI   R31, hi8(row4_digits)
    RJMP  find
;---------------------------------------------------------------
find:
    LSR   R21           ;logical shift right
    BRCC  match
    LPM   R20, Z+
    RJMP  find
match:
    LPM   R20, Z

    ; Check if the key value is 11 (decimal)
    CPI   R20, 11
    BRNE  store        ; If not 11, store

    RCALL I2C_start       ;transmit START condition
    LDI   R27, 0b10010000 ;SLA(1001000) + W(0)
    RCALL I2C_write       ;write slave address SLA+W
    MOV   R27, R24        ;data byte to be transmitted
    RCALL I2C_write       ;write data byte
    RCALL I2C_stop        ;transmit STOP condition

    CLR   R24          ; Clear low byte
    LDI   R16, 3
    
    LDI   R18, 0       ; Value to display (0)
    LDI   R17, 1       ; Digit 1
    RCALL send_bytes
    LDI   R17, 2       ; Digit 2
    RCALL send_bytes
    LDI   R17, 3       ; Digit 3
    RCALL send_bytes
    
    TST R25
    BRNE jump_to_azi
    LDI R25, 1
    RJMP MAX7219_disp_alt
jump_to_azi:
    CLR R25
    RJMP MAX7219_disp_azi
store:
    LSL  R24           ; Multiply by 2
    MOV  R30, R24      ; Save intermediate result
    LSL  R24           ; Multiply by 4 (2 * 2 = 4)
    LSL  R24           ; Multiply by 8 (2 * 2 * 2 = 8)
    ADD  R24, R30      ; Add original x2 and x8 to x10
    ADD  R24, R20      ; Add previous number

    MOV  R17, R16
    DEC  R16
    MOV   R18, R20
    RCALL send_bytes      ;send command & data to MAX7219
    RJMP  gnd_rows
;==============================================================
I2C_start:
    LDI   R21, (1<<TWINT)|(1<<TWSTA)|(1<<TWEN)
    STS   TWCR, R21       ;transmit START condition
    ;----------------------------------------------------------
wt1:LDS   R21, TWCR
    SBRS  R21, TWINT      ;TWI interrupt = 1?
    RJMP  wt1             ;no, wait for end of transmission
    ;----------------------------------------------------------
    RET
;==============================================================
I2C_write:
    STS   TWDR, R27       ;copy SLA+W into data register
    LDI   R21, (1<<TWINT)|(1<<TWEN)
    STS   TWCR, R21       ;transmit SLA+W
    ;----------------------------------------------------------
wt2:LDS   R21, TWCR
    SBRS  R21, TWINT
    RJMP  wt2             ;wait for end of transmission
    ;----------------------------------------------------------
    RET
;==============================================================
I2C_stop:
    LDI   R21, (1<<TWINT)|(1<<TWSTO)|(1<<TWEN)
    STS   TWCR, R21       ;transmit STOP condition
    RET
;---------------------------------------------------------------
row1_digits: .byte  1,2,3
row2_digits: .byte  4,5,6
row3_digits: .byte  7,8,9
row4_digits: .byte  11,0,11
;===============================================================
my_delay:
    LDI   R21, 255
l6: LDI   R22, 255
l7: LDI   R23, 10
l8: DEC   R23
    BRNE  l8
    DEC   R22
    BRNE  l7
    DEC   R21
    BRNE  l6
    RET