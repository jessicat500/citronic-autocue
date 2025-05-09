; 6532 RIOT registers
VIAOPA              = $5400
VIAOPB              = $5402
VIADDRA             = $5401
VIADDRB             = $5403
TIMER               = $57FF

; RAM variables

; deck masks
D1MASK              = $5011
D2MASK              = $5000

; we don't know any of these yet
; $5002
; $5003
; $5004
; $5005
; $5006
; $5009 - doesn't seem to get init'd, used in FLASHLEDS

; operation flags

AUTOCUEINPROGRESS   = $500A

; tone arm states used for checking state changes
TONEARMSTATE        = $5001
ARM1STAT            = $5007
ARM2STAT            = $5008

; counters used in pausing and other subs
PAUSECOUNTER        = $500B
COUNTER             = $500C

; temp audio state for hunting subroutine
HUNTAUDIOSTATE      = $500D

; temp audio state for buttons subroutine
BUTTONSAUDIOSTATE   = $500E

; cache for 6532 IO to check state change
OPACACHE            = $500F
OPBCACHE            = $5010

; Debug flags (we think, tickles A13 which is n/c)
DEBUG_SEMAPHORE     = $AAAA
DEBUG_ROMSEL        = $5900
