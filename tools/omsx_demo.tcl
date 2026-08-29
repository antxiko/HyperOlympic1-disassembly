# Que vale 0xE002 durante la demo y durante una partida de verdad.
#
# 0x402E manda con ese byte: si vale cero la interrupcion lee los mandos y
# mueve la musica; si no, mira el bit 7 de 0xE029 y se inventa pulsaciones en
# 0xE00B. Aqui se muestrea sin tocar nada, primero dejando correr la demo y
# despues arrancando una partida.
set ::SALIDA [file normalize "work/omsx"]
file mkdir $::SALIDA
set renderer SDLGL-PP
set throttle on
proc tecla {f m} { keymatrixdown $f $m ; after time 0.15 "keymatrixup $f $m" }
set ::filas {}
proc muestra {n etiqueta} {
    lappend ::filas [format "%-10s t=%6.1f  E002=%02X E017=%02X E029=%02X E00B=%02X E016=%02X" \
        $etiqueta [machine_info time] [debug read memory 0xE002] [debug read memory 0xE017] \
        [debug read memory 0xE029] [debug read memory 0xE00B] [debug read memory 0xE016]]
    if {$n > 0} { after time 2 "muestra [expr {$n-1}] $etiqueta" }
}
# 1) se deja correr: el titulo espera y cae en la demo
after time 14 { muestra 12 demo }
# 2) despues se arranca una partida de verdad
after time 44 { tecla 8 0x01 ; after time 1 { tecla 8 0x40 ; after time 0.6 { tecla 8 0x40 ; after time 0.6 { tecla 8 0x01 } } } }
after time 60 { muestra 8 partida }
after time 82 {
    set f [open [file join $::SALIDA "demo.txt"] w]
    foreach x $::filas { puts $f $x }
    close $f
    screenshot -raw [file join $::SALIDA "demo.png"]
    exit
}
after realtime 200 { exit }
