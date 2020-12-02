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
