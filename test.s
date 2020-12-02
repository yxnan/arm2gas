; ----- Conversion: labels -----
LABEL   ; Symbol as label
1       ; Numeric local label

; scope is unsupported
2routA
routB ROUT ; delete ROUT

; branch to local label
    B   %f1
    BLT %b2
    BGT %ba3      ; search level is unsupported
    BGT %ft4routC ; scope is unsupported

; ----- Conversion: functions -----
myproc1 PROC
    ; function body
ENDP
