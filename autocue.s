; Autocue for Citronic Tamar/Thames II
; Annotated disassembly by Jessica Rowbottom, May 2025
; Ported initially to ca65 by Ray Bellis, April 2025
;
; To be identical to the fitted v2.19AN, the built binary must
; have an md5sum of e7d3017812a0e49411d76f40937de220
;
; v2.19AN image designed to be burnt to a 2716 EPROM
; and fitted in IC3

        .include "symbols.s"

        .org $5800

        .byte "AUTOCUE(C)1983 CITRONIC LTD. "
        .byte "DO NOT COPY THIS EPROM WITHOUT PERMISSION. "
        .byte "K.DRAPER(0225)705600 EXT28",$0d

        .res $58a0 - *, $EA

START:
        CLD
        SEI
        LDX #$FF
        TXS                             ; clear stack
        LDA #$FC                        ; set up IO for PA (11000000)
        STA VIADDRA
        LDA #$0F                        ; set up IO for PB (00001111)
        STA VIADDRB
        LDA DEBUG_SEMAPHORE             ; blip the debug semaphore
        LDA #$FF
        STA TIMER
        LDA OPACACHE
        STA VIAOPA
        LDA OPBCACHE
        STA VIAOPB
        LDA D1MASK                      ; is the deck 1 mask set up?
        CMP #$AA
        BNE INITVARS
        LDA D2MASK
        CMP #$55                        ; is the deck 2 mask set up?
        BNE INITVARS
        JMP SCANLOOP                    ; assume all good, we don't need to init variables (unlikely but even so)

INITVARS:
        NOP                             ; init all RAM variables
        LDA #$00                        ; switch off all outputs on OPB (inc deck motors)
        STA VIAOPB
        STA OPBCACHE
        LDA #$F0                        ; switch on deck LEDs and mutes
        STA VIAOPA
        STA OPACACHE
        LDA VIAOPA
        AND #$01                        ; PA0 arm rest 1 state
        STA ARM1STAT
        LDA VIAOPA
        AND #$02                        ; PA1 arm rest 2 state
        STA ARM2STAT
        LDA #$00
        STA $5005
        STA $5006
        STA AUTOCUEINPROGRESS
        LDA #$AA
        STA D1MASK
        LDA #$55
        STA D2MASK
        LDX #$0A                        ; init with deck 2 first
        CLI

SCANLOOP:
        NOP
        LDA DEBUG_SEMAPHORE             ; blip the debug semaphore
        LDA #$FF
        STA TIMER
        JSR SCANDECKSTART               ; deal if decks have been started or stopped
        JSR SCANTONEARM                 ; deal if tonearms have been moved
        JSR FLIPDECKS                   ; flip deck over to scan each one alternately
        JMP SCANLOOP

; flip from deck 1 to deck 2, or back again

FLIPDECKS:
        TXA
        BNE FLIPTOD1
        LDX #$0A                        ; set deck 2 const offset as active deck
        RTS
FLIPTOD1:
        LDX #$00                        ; set deck 1 const offset as active deck
        RTS

; pausing routine, used widely

PAUSE:
        NOP
        LDA #$FF
        STA PAUSECOUNTER
PAUSELOOP:
        NOP
        LDA DEBUG_ROMSEL
        LDA #$FF
        STA TIMER
        LDA DEBUG_SEMAPHORE             ; blip the debug semaphore
        DEC PAUSECOUNTER
        BNE PAUSELOOP
        RTS

; this seems to be a half-time pause routine but it's not used anywhere?

SHORTPAUSE:
        NOP
        LDA #$80
        STA PAUSECOUNTER
SHORTPAUSELOOP:
        NOP
        LDA DEBUG_ROMSEL
        LDA #$FF
        STA TIMER
        LDA DEBUG_SEMAPHORE             ; blip the debug semaphore
        DEC PAUSECOUNTER
        BNE SHORTPAUSELOOP
        RTS

; scan deck start button for changes

SCANDECKSTART:
        LDA CONST_D1MOTOR,X
        AND VIAOPB
        STA TONEARMSTATE
        JSR PAUSE
        JSR PAUSE
        LDA CONST_D1MOTOR,X
        AND VIAOPB
        CMP TONEARMSTATE
        BEQ L5976
        RTS
L5976:
        LDA TONEARMSTATE                ; deck start hasn't changed
        BEQ L597E
        JMP L5A05
L597E:
        NOP
        LDA $5005
        STA TONEARMSTATE
        TXA
        BEQ L598E
        LDA $5006
        STA TONEARMSTATE
L598E:
        LDA TONEARMSTATE
        BNE CANCELDECKSTART
        LDA CONST_D1BUTTONS,X
        AND VIAOPB
        BNE L59D9
        LDA CONST_D1BUTTONS,X
        ORA VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1LED,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDA AUTOCUEINPROGRESS
        BNE L59C8
        LDA #$64
        STA COUNTER
CDNLOOP2:
        NOP
        JSR PAUSE
        DEC COUNTER
        BNE CDNLOOP2
L59C8:
        LDA CONST_D1MUTE,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        JMP L59F6
L59D9:
        LDA CONST_D1BUTTONS,X
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1MUTE,X
        ORA CONST_D1LED,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
L59F6:
        LDY #$FF
        TXA
        BNE L5A01
        STY $5005
        JMP CANCELDECKSTART
L5A01:
        STY $5006
CANCELDECKSTART:
        RTS
L5A05:
        LDY #$00
        TXA                             ; check which deck we're on
        BNE L5A10
        STY $5005                       ; flag semaphore for deck 1 to cancelled?
        JMP ENDDECKSTART
L5A10:
        STY $5006                       ; flag semaphore for deck 2 to cancelled?
ENDDECKSTART:
        RTS

; Scan tone arm movement subroutine, we've just dropped the tonearm, let's go
; This then goes to the audio hunting bit

SCANTONEARM:
        LDA CONST_D1TONEARMSTATE,X      ; get tone arm state
        AND VIAOPA
        STA TONEARMSTATE
        JSR PAUSE
        LDA #$05                        ; five pauses before we scan again
        STA COUNTER
REPEATSCANPAUSE:
        JSR PAUSE
        DEC COUNTER
        BNE REPEATSCANPAUSE
        JSR PAUSE
        LDA CONST_D1TONEARMSTATE,X
        AND VIAOPA
        CMP TONEARMSTATE                ; and has it changed?
        BEQ CHECKD1TONEARM              ; no
        RTS
CHECKD1TONEARM:
        TXA
        BNE CHECKD2TONEARM              ; are we on deck 2 or 1? A=nonzero we're on deck 2
        LDA TONEARMSTATE                ; check tonearm state again
        CMP ARM1STAT
        BNE STORED1TONEARM
        RTS
CHECKD2TONEARM:
        LDA TONEARMSTATE                ; check tonearm state again
        CMP ARM2STAT
        BNE STORED1TONEARM              ; branch if tonearm has changed state
        RTS                             ; otherwise escape out of scanning tone arm state

STORED1TONEARM:
        LDY TONEARMSTATE
        TXA
        BNE STORED2TONEARM              ; we're dealing with tonearm2 so jump to that
        STY ARM1STAT
        JMP PREPAREFORLISTEN

STORED2TONEARM:
        STY ARM2STAT

; tonearm has been dropped, need to mute

PREPAREFORLISTEN:
        LDA CONST_D1TONEARMSTATE,X
        AND TONEARMSTATE
        BEQ TONEARMSTILLOUT

        LDA CONST_D1BUTTONS,X           ; tonearm has been replaced, cancel it all out and reset everything
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1MUTE,X
        ORA CONST_D1LED,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
        RTS

TONEARMSTILLOUT:
        JSR CUESELECT                   ; select the cue for this deck
        LDA VIAOPB
        AND #$20                        ; check if autocue is switched on
        BEQ TONEARMCANCEL               ; branch if autocue is off
        JSR RUNAUTOCUE
TONEARMCANCEL:
        RTS

; autocue is in progress, hunt audio and then back up to silence again

RUNAUTOCUE:
        LDA #$FF
        STA AUTOCUEINPROGRESS
        LDA CONST_D1MUTE,X              ; mute the deck
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
        JSR CUESELECT                   ; select the appropriate cue
        LDA #$6E
        STA COUNTER
LONGPAUSEBEFOREDECKSTART:               ; $6E loop of pauses
        JSR PAUSE
        DEC COUNTER
        BNE LONGPAUSEBEFOREDECKSTART

        LDA #$73                        ; audio hunting timeout time (number of loops)
        STA COUNTER
HUNTAUDIO1:
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        STA HUNTAUDIOSTATE
        JSR CHECKBUTTONS
        LDA DEBUG_SEMAPHORE             ; blip the debug semaphore
        LDA #$FF
        STA TIMER
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        AND HUNTAUDIOSTATE
        BNE FOUNDAUDIO1                 ; found some audio
        DEC COUNTER
        BNE HUNTAUDIO1                  ; no, keep hunting audio if we haven't timed out
FOUNDAUDIO1:
        LDA CONST_D1BUTTONS,X           ; Reset button states to switch off buttons?
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA #$05                        ; select forward (mask bits 0 and 2 of cue drive buttons)
        AND CONST_D1BUTTONS,X
        ORA VIAOPB
        STA VIAOPB                      ; run forward
        STA OPBCACHE
        LDA #$32
        STA COUNTER
HUNTAUDIO1PAUSE:
        JSR CHECKBUTTONS
        JSR PAUSE
        DEC COUNTER
        BNE HUNTAUDIO1PAUSE
        JSR CUESELECT

HUNTSILENCE1:
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        STA HUNTAUDIOSTATE
        JSR CHECKBUTTONS
        JSR PAUSE
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        AND HUNTAUDIOSTATE
        BEQ HUNTSILENCE1
        LDA CONST_D1BUTTONS,X
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA #$8C
        STA COUNTER
HUNTSILENCE1WAITLOOP:
        JSR PAUSE
        DEC COUNTER
        BNE HUNTSILENCE1WAITLOOP
        LDA #$0A                        ; select reverse (mask bits 1 and 3 of cue drive buttons)
        AND CONST_D1BUTTONS,X
        ORA VIAOPB
        STA VIAOPB                      ; run reverse
        STA OPBCACHE
        LDA #$6E
        STA COUNTER
        JSR CUESELECT
HUNTSILENCE1PAUSE:
        JSR CHECKBUTTONS
        JSR PAUSE
        DEC COUNTER
        BNE HUNTSILENCE1PAUSE

HUNTAUDIO2:
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        STA HUNTAUDIOSTATE
        JSR CHECKBUTTONS
        JSR PAUSE
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        ORA HUNTAUDIOSTATE
        BNE HUNTAUDIO2
        JSR CUESELECT
        LDA CONST_D1BUTTONS,X           ; switch off the cue drive buttons
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        LDA #$8C
        STA COUNTER
HUNTAUDIO2WAITLOOP:
        JSR PAUSE
        DEC COUNTER
        BNE HUNTAUDIO2WAITLOOP
        LDA CONST_D1BUTTONS,X           ; Run buttons forward?
        ORA VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA #$64
        STA COUNTER
HUNTAUDIO2PAUSE:
        JSR CHECKBUTTONS
        JSR PAUSE
        DEC COUNTER
        BNE HUNTAUDIO2PAUSE

HUNTSILENCE2:
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        STA HUNTAUDIOSTATE
        JSR CHECKBUTTONS
        JSR PAUSE
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        AND HUNTAUDIOSTATE
        BEQ HUNTSILENCE2
        LDA CONST_D1BUTTONS,X
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA #$1E
        STA COUNTER
HUNTSILENCE2WAITLOOP:
        JSR CHECKBUTTONS
        JSR PAUSE
        DEC COUNTER
        BNE HUNTSILENCE2WAITLOOP
        JSR SLOWREVERSE                 ; reverse the deck back a little bit
        LDA CONST_D1BUTTONS,X           ; shut off all the buttons
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        JMP DECKISCUED                  ; jump to signalling ready

; checking buttons - possibly for running motor logic which cancels out autocue

CHECKBUTTONS:
        NOP
        JSR FLIPDECKS
        JSR SCANDECKSTART
        JSR FLIPDECKS
        LDA CONST_D1MOTOR,X
        AND VIAOPB
        BNE L5C77
        JSR PAUSE
        JSR PAUSE
        LDA CONST_D1MOTOR,X
        AND VIAOPB
        BNE L5C77
        LDA CONST_D1BUTTONS,X
        ORA VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1LED,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDA #$64
        STA COUNTER
CHECKBUTTONSPAUSELOOP:
        NOP
        JSR PAUSE
        DEC COUNTER
        BNE CHECKBUTTONSPAUSELOOP
        LDA CONST_D1MUTE,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDY #$FF
        TXA                             ; check which deck this is
        BNE L5C69
        STY $5005                       ; deck 2
        JMP L5C6C
L5C69:
        STY $5006                       ; deck 1
L5C6C:
        LDX #$FF
        TXS                             ; clear stack
        LDX #$00
        STX AUTOCUEINPROGRESS
        JMP SCANLOOP
L5C77:
        LDA CONST_D1TONEARMSTATE,X
        AND VIAOPA
        BEQ ENDCHECKBUTTONS             ; finish if tonearm has been replaced
        JSR PAUSE
        JSR PAUSE
        JSR PAUSE
        LDA CONST_D1TONEARMSTATE,X
        AND VIAOPA
        BEQ ENDCHECKBUTTONS             ; finish if tomearm has been replaced
        NOP
        LDA CONST_D1BUTTONS,X
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1MUTE,X
        ORA CONST_D1LED,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDX #$FF
        TXS                             ; clear stack
        LDX #$00
        STX AUTOCUEINPROGRESS
        JMP SCANLOOP
ENDCHECKBUTTONS:
        RTS

; Subroutine to select the appropriate cue channel for the VU meter

CUESELECT:
        LDA CONST_D1CUE,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
        STA TONEARMSTATE
        JSR PAUSE
        JSR PAUSE
        LDA CONST_D1CUE,X
        EOR #$FF
        AND TONEARMSTATE
        STA VIAOPA
        STA OPACACHE
        RTS

; pretty sure this is the link logic, and flashing the LEDs when autodue has finished and is ready

DECKISCUED:
        LDA #$00
        STA BUTTONSAUDIOSTATE
        LDA VIAOPB
        AND #$20                        ; check if autocue is switched on
        BEQ FLASHLEDS                   ; branch if autocue is switched off
        LDA #$FF
        STA BUTTONSAUDIOSTATE           ; store $FF (audio detected) in temp audio var
FLASHLEDS:
        LDA CONST_D1LED,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        DEC $5009
        LDA $5009
        AND #$08                        ; d2 cue on? not sure why this would be d2 specific
        BEQ FLASHSTATECHANGED           ; branch if deck LED is off
        LDA CONST_D1LED,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
FLASHSTATECHANGED:
        JSR CHECKBUTTONS
        JSR PAUSE
        LDA VIAOPB
        AND #$20                        ; check if autocue is still switched on
        BNE L5D28                       ; branch if autocue is still switched on
        LDA #$00                        ; autocue is switched off if we've got here
        STA BUTTONSAUDIOSTATE           ; store $00 (no audio) in temp audio var
        JMP FLASHLEDS
L5D28:
        LDA BUTTONSAUDIOSTATE           ; check temp audio var for state
        BNE FLASHLEDS                   ; temp audio var is $FF (audio detected)
        LDA #$FF
        STA BUTTONSAUDIOSTATE           ; store $FF (audio detected) in temp audio var
        JMP L5D35

L5D35:
        NOP
        JSR FLIPDECKS
        JSR CUESELECT
        LDA #$64
        STA COUNTER
L5D41:
        JSR PAUSE
        DEC COUNTER
        BNE L5D41

WAITFORCHANGEOVER:                      ; changeover logic when we've got autocue in that odd mode ('off' but not)
        JSR PAUSE
        JSR FLIPDECKS
        JSR CHECKBUTTONS
        LDA CONST_D1LED,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDA $5009
        AND #$02                        ; another deck LED flash?
        BEQ L5D73
        LDA CONST_D1LED,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
L5D73:
        DEC $5009
        JSR PAUSE
        JSR FLIPDECKS
        LDA #$E1
        STA COUNTER

WAITFORAUDIO:
        JSR PAUSE
        LDA VIAOPB
        EOR #$FF
        AND #$10                        ; check if audio detected
        BNE WAITFORCHANGEOVER
        JSR FLIPDECKS
        LDA CONST_D1LED,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        JSR FLIPDECKS
        DEC COUNTER
        BNE WAITFORAUDIO                ; go back if still audio
        JSR FLIPDECKS                   ; quiet has happened, flip the decks
        LDA CONST_D1BUTTONS,X           ; start the other deck
        ORA VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1LED,X               ; LED lit on the other deck
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDA #$96
        STA COUNTER

WAITBEFOREMUTE:                         ; loop before we mute back to the other deck
        JSR PAUSE
        DEC COUNTER
        BNE WAITBEFOREMUTE

        JSR CUESELECT
        LDA CONST_D1MUTE,X
        EOR #$FF
        AND VIAOPA
        STA VIAOPA
        STA OPACACHE
        JSR FLIPDECKS
        LDA CONST_D1BUTTONS,X
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA CONST_D1MUTE,X
        ORA CONST_D1LED,X
        ORA VIAOPA
        STA VIAOPA
        STA OPACACHE
        LDA #$00
        STA AUTOCUEINPROGRESS
        STA ARM1STAT
        STA ARM2STAT
        LDX #$FF
        TXS                             ; clear sta4ck
        LDX #$00
        JMP SCANLOOP                    ; finished, head back to the scanning loop

; think this may be the slow reverse of the deck when autocue has completed
; why else would it be pushing reverse button then stopping a mo later
; then pushing it again - simulating a slow reverse!

SLOWREVERSE:
        NOP
        LDA #$EB                        ; how long to run reverse to give a lead-in of silence
        STA COUNTER
TAPREVBUTTONS:
        LDA CONST_D1BUTTONS,X
        EOR #$FF
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        LDA #$0A                        ; mask reverse buttons
        AND CONST_D1BUTTONS,X
        ORA VIAOPB
        STA VIAOPB
        STA OPBCACHE
        JSR PAUSE                       ; pause a little
        LDA CONST_D1BUTTONS,X
        EOR #$FF                        ; switch off reverse buttons
        AND VIAOPB
        STA VIAOPB
        STA OPBCACHE
        JSR PAUSE
        DEC COUNTER
        BNE TAPREVBUTTONS
        RTS

; end of code, pad it all out with NOPs and a restart at the end for some reason

        .res $5fdc - *, $ea

        JMP START
        NOP

; these constants are used with the X index so any deck-specific operations happen on
; either deck 1 (X=$00) or deck 2 (X=$0A).

; deck 1 constants

CONST_D1BUTTONS:        .byte $03           ; d1 fwd+rev buttons
CONST_D1MOTOR:          .byte $40           ; d1 run motor (start)
CONST_D1CUE:            .byte $04           ; d1 cue
CONST_D1MUTE:           .byte $10           ; d1 mute
CONST_D1LED:            .byte $40           ; d1 led
CONST_D1TONEARMSTATE:   .byte $01           ; d1 arm rest state

CONSTA:                 .byte $ea           ; padding
CONSTB:                 .byte $ea           ; padding
CONSTC:                 .byte $ea           ; padding
CONSTD:                 .byte $ea           ; padding

; deck 2 constants ($0A after CONST_D1BUTTONS)

CONST_D2BUTTONS:        .byte $0c           ; d2 fwd+rev buttons
CONST_D2MOTOR:          .byte $80           ; d2 run motor (start)
CONST_D2CUE:            .byte $08           ; d2 cue
CONST_D2MUTE:           .byte $20           ; d2 mute
CONST_D2LED:            .byte $80           ; d2 led
CONST_D2TONEARMSTATE:   .byte $02           ; d2 arm rest state

; vectors (bootstrap pointer for 6502 runs the code, should be after the copyright message)
; putting these in this memory location is critical as it's where the 6502 will look for
; the code execution address

        .res $5ffa - *, $ea
        .word  START
        .word  START
        .word  START
