#Requires AutoHotkey v2.0

; 0. RELAUNCH AS ADMIN IF NEEDED
; Without elevation, Windows UIPI blocks Send from reaching elevated windows
; (e.g. admin terminals, Task Manager), so the remaps appear to do nothing there.
if !A_IsAdmin {
    try {
        if A_IsCompiled
            Run '*RunAs "' A_ScriptFullPath '" /restart'
        else
            Run '*RunAs "' A_AhkPath '" /restart "' A_ScriptFullPath '"'
    }
    ExitApp
}

; 1. GLOBALLY DISABLE CAPS LOCK TOGGLE
SetCapsLockState "AlwaysOff"

; 2. DEFINE THE LAYER
#HotIf GetKeyState("CapsLock", "P")

; HJKL -> Arrows
h::Send "{Left}"
j::Send "{Down}"
k::Send "{Up}"
l::Send "{Right}"

; A & E -> Home & End
a::Send "{Home}"
e::Send "{End}"

; P & N -> Page Up & Page Down
p::Send "{PgUp}"
n::Send "{PgDn}"

; G & T -> Grave Accent (`) & Tilde (~)
g::Send "``" 
t::Send "~"

; Backspace -> Forward Delete (Corrected v2 Syntax)
*backspace:: {
    Send "{Delete}"
}

#HotIf
