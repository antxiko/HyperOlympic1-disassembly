# Lo que se midio en el emulador

- `pruebas.txt` — las cuatro pruebas del cartucho y sus records del mundo,
  fotografiadas una a una con `tools/omsx_prueba_n.tcl`. Las capturas estan en
  `docs/imagenes/`.

Los guiones de openMSX solo LEEN memoria, salvo `omsx_prueba_n.tcl`, que cambia
0xE016 para llegar a las cuatro pruebas sin tener que clasificarse en las tres
primeras. La ROM no se toca en ningun caso.

- `demo.txt` — 0xE002, 0xE017, 0xE029 y 0xE00B muestreados durante la demo y
  durante una partida de verdad, con `tools/omsx_demo.tcl`. Es lo que demuestra
  que las pulsaciones inventadas de 0x4030 solo pasan en la demo.
