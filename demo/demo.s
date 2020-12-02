; ----- Conversion: labels -----
LABEL   ; Symbol as label
1       ; Numeric local label

; scope is unsupported
2routA
routB ROUT ; delete ROUT
3routB

; branch to numeric local label
    B   %b1
    BLT %bt2      ; search level is unsupported
    BGT %ba3
    BGT %ft4routC ; scope is unsupported
4

; ----- Conversion: functions -----
myproc1 PROC
    ; function body
ENDP

; ----- Conversion: sections -----
    AREA |.text|,  CODE, READONLY, ALIGN=3  ; code
    AREA |1_data|, DATA, READWRITE, MERGE=2, GROUP=foo

; ----- Conversion: numeric literals -----
    MOV     r1, #0x4, LSL#16   ; 0x40000
    MOV     r1, #0x4, ASR #16
    LDR     r1, =&10AF
    LDR     r1, = 2_11001010
    ADD     r1, #-2_1101
    ADD     r1, #8_27

; ----- Conversion: conditional directives -----
    IF :DEF:__MICROLIB
    ENDIF
    IF :LNOT::DEF:__MICROLIB
    ELSEIF __STDLIB
        IF __DEBUG
        ENDIF
    ENDIF

; ----- Conversion: operators -----
    MOV     r1, #(7:SHL:2)
    MOV     r1, #(:NOT:2)
    ; MOV     r1, #(7:ROR:2)   ; unsupported

; ----- Conversion: misc directives -----
    THUMB
    REQUIRE8
    PRESERVE8
    GLOBAL  main
    EXPORT  myproc, [weak]  ; weak declaration
    INCLUDE "myinc.h"
    DCB     "string"
    DCW     0xae2e, 0x3c42
    DCWU    0xae2e, 0x3c42
    DCD     0x4000
    DCDU    0x4000
    DCQ     0x12345678, 0x56781234
    DCQU    0x12345678, 0x56781234
    DCFS    1.0,-.1,3.1E6
    DCFSU   1.0,-.1,3.1E6
    DCFD    1E308, -4E-100
    DCFDU   1E308, -4E-100
    ALIGN   8
    WHILE   1
        INFO 2, "Pass 2"
    WEND
myreg   RN  R0
myqreg  QN  q0.i32
mydreg  DN  d0.i32

; ----- Conversion: symbol definition -----
        LCLA    var1  ; local var is not supported
        LCLL    var2  ; local var is not supported
        GBLS    var3  ; global var
        GBLL    var4  ; global var
var1    SETA    (1+3)
var2    SETL    TRUE
var3    SETS    "newstring"