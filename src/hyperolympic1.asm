; ==========================================================================
; HYPER OLYMPIC 1 - Konami - MSX1 - cartucho RC-710 de 16 KB en la pagina 1
; ==========================================================================
; Generado por tools/mkasm.py a partir del trazado de flujo real.
; Los comentarios provienen de tools/../src/*.notes y estan anclados a
; direccion, de modo que sobreviven a un retrazado.
; ==========================================================================

	org 0x04000


; ----------------------------------------------------------------------
; DATOS cabecera: Cabecera del cartucho: la firma AB y los cuatro punteros que
;   lee la BIOS. Solo INIT (0x4081) tiene valor; STATEMENT, DEVICE y TEXT van
;   a cero.
;   0x4000..0x4010  (16 bytes)
DATA_cabecera:
	defb 041h,042h	; 4000
	defb 081h,040h	; 4002
	defb 000h,000h	; 4004
	defb 000h,000h	; 4006
	defb 000h,000h	; 4008
	defb 000h,000h	; 400a
	defb 000h,000h	; 400c
	defb 000h,000h	; 400e

; ======================================================================
; CODIGO 0x4010..0x4ae7  (2775 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  LA INTERRUPCION  ==========
; Entra por el gancho H.KEYI (0xFD9A), que INIT rellena con un `jp` aqui.
; Hace el trabajo que tiene que ir a ritmo de pantalla: el reloj, los
; mandos, la musica y el motor de la prueba que se este jugando.
; ----------------------------------------------------------------------
INTERRUPCION:
	call 0013eh		;4010   ; BIOS RDVDP - Reads VDP status register | leer el estado del VDP es lo que retira la peticion de interrupcion
	ld hl,0e01dh		;4013
	ld (hl),001h		;4016   ; avisa de que ha entrado: quien estuviera fijando una direccion de VRAM la repite
	inc hl			;4018   ; -> 0xE01E, el candado
	ld a,(hl)			;4019
	or a			;401a
	ret nz			;401b   ; con el candado puesto la interrupcion se va sin tocar nada
	ld hl,0e000h		;401c
	inc (hl)			;401f   ; el contador de cuadros
	ld a,(hl)			;4020
	and 01fh		;4021   ; los cinco bits de abajo
	jr nz,INT_CON_MANDOS		;4023
	inc hl			;4025
	dec (hl)			;4026   ; la espera de 0xE001 baja UNA VEZ CADA 32 CUADROS, no una por cuadro
INT_CON_MANDOS:
	call LEE_LOS_MANDOS		;4027   ; lee los mandos crudos
	ld a,(0e002h)		;402a
	or a			;402d
	jr z,INT_PARTIDA_DE_VERDAD		;402e   ; con 0xE002 puesto lo que corre es la DEMO: ni se leen los mandos ni suena la musica
	ld a,(0e029h)		;4030   ; MEDIDO: aqui solo se entra en la demo. El bit 7 de 0xE029 esta puesto tambien en partida, pero entonces manda 0xE002 y este trozo no corre
	rlca			;4033
	jr nc,INT_MOTOR_DE_LA_PRUEBA		;4034
	ld hl,0e00bh		;4036
	ld (hl),000h		;4039   ; borra el boton antes de inventarselo
	ld a,(0e000h)		;403b
	and 003h		;403e   ; una de cada cuatro cuadros
	jr nz,INT_MOTOR_DE_LA_PRUEBA		;4040
	ld a,r		;4042   ; el azar del cartucho es el registro de refresco de la memoria
	and 003h		;4044
	ld (hl),a			;4046   ; pulsaciones al azar en el boton del jugador 1
	jr INT_MOTOR_DE_LA_PRUEBA		;4047
INT_PARTIDA_DE_VERDAD:
	call LEE_LOS_MANDOS_DE_LOS_DOS		;4049   ; y en partida de verdad se reparten los mandos entre los dos jugadores
	call MUEVE_EL_SONIDO		;404c   ; y mueve la musica
	di			;404f
INT_MOTOR_DE_LA_PRUEBA:
	ld a,(0e003h)		;4050
	or a			;4053
	jr z,INT_FIN		;4054   ; con 0xE003 a cero no hay prueba que mover
	call PARPADEO_DEL_RESULTADO		;4056   ; el parpadeo del rotulo del resultado
	ld a,(0e016h)		;4059
	dec a			;405c
	push af			;405d
	call z,MOTOR_DE_LA_CARRERA		;405e   ; prueba 1, los 100 metros
	pop af			;4061
	dec a			;4062
	push af			;4063
	call z,MOTOR_DEL_SALTO		;4064   ; prueba 2, el salto de longitud
	pop af			;4067
	dec a			;4068
	push af			;4069
	call z,MOTOR_DEL_MARTILLO		;406a   ; prueba 3, el lanzamiento de martillo
	pop af			;406d
	dec a			;406e
	call z,MOTOR_DE_LA_CARRERA		;406f   ; prueba 4, los 400 metros: el mismo motor que los 100
INT_FIN:
	call 0013eh		;4072   ; BIOS RDVDP - Reads VDP status register | vuelve a mirar el estado del VDP
	rlca			;4075
	jp c,INTERRUPCION		;4076   ; si ha entrado OTRO cuadro mientras trabajabamos, se repite la pasada entera
	ld a,001h		;4079
	ld (0e01dh),a		;407b   ; deja la marca puesta para el que estuviera fijando VRAM
	ei			;407e
	reti		;407f

; ----------------------------------------------------------------------
; ==========  INIT  ==========
; El unico punto de entrada que declara la cabecera. La BIOS lo llama
; con la maquina ya inicializada, y de aqui no se vuelve.
; ----------------------------------------------------------------------
INIT:
	di			;4081
	ld hl,0fd9ah		;4082   ; el gancho de interrupcion de la BIOS
	ld (hl),0c3h		;4085   ; le mete un `jp`
	ld hl,INTERRUPCION		;4087   ; y detras la direccion de nuestra interrupcion
	ld (0fd9bh),hl		;408a
	ld hl,0e000h		;408d   ; limpia la RAM del juego de 0xE000 a 0xE3FE
	ld de,0e001h		;4090
	ld bc,003feh		;4093
	ld (hl),l			;4096   ; con L, que en este momento vale cero
	ldir		;4097
	ld sp,hl			;4099   ; y deja la pila justo encima, en 0xE3FE
	ld a,008h		;409a   ; los registros 8, 9 y 10 del PSG, que son los tres de VOLUMEN
	ld e,000h		;409c
	ld b,003h		;409e   ; a cero, que es lo que de verdad calla los tres canales
LIMPIA_UN_REGISTRO_DEL_PSG:
	call 00093h		;40a0   ; BIOS WRTPSG - Writes data to PSG-register
	inc a			;40a3
	djnz LIMPIA_UN_REGISTRO_DEL_PSG		;40a4
	ld de,081a2h		;40a6   ; esto NO es el PSG: 0x81A2 es una direccion de VRAM y lo que sigue
	call FIJA_ESCRITURA		;40a9   ; es FIJA_ESCRITURA, que deja puesta la direccion de escritura del VDP; nadie escribe detras (ver docs/es/PREGUNTAS-ABIERTAS.md)
	ld a,00fh		;40ac   ; registro 15, el puerto de salida
	ld e,0cfh		;40ae
	call 00093h		;40b0   ; BIOS WRTPSG - Writes data to PSG-register
	call 00132h		;40b3   ; BIOS CHGCAP - Alternates the CAPS lamp status | apaga el piloto de CAPS
	im 1		;40b6
	ld hl,05174h		;40b8   ; los cuatro records del mundo
	ld de,0e040h		;40bb   ; a su sitio en la RAM
	ld bc,0000ch		;40be
	ldir		;40c1
	ld hl,07ac5h		;40c3   ; la flecha del menu arranca en la fila de la primera linea
	ld (0e019h),hl		;40c6
	ld a,001h		;40c9   ; y la linea elegida es la primera
	ld (0e01bh),a		;40cb
ARRANQUE_DE_LA_PRESENTACION:
	di			;40ce
	ld hl,00000h		;40cf   ; borra el numero de jugadores
	ld (0e010h),hl		;40d2
	ld hl,0e020h		;40d5   ; limpia los tres canales de sonido
	ld bc,0001fh		;40d8
	call LIMPIA_MEMORIA		;40db
	ld hl,0e050h		;40de   ; y el trozo de trabajo de 0xE050
	ld c,02eh		;40e1
	call LIMPIA_MEMORIA		;40e3
	ld hl,0e083h		;40e6   ; y el de 0xE083
	ld c,01ah		;40e9
	call LIMPIA_MEMORIA		;40eb
	ld hl,0e0a0h		;40ee   ; y los tres bytes de 0xE0A0
	ld b,003h		;40f1
	call LIMPIA_MEMORIA		;40f3
	ld de,04000h		;40f6   ; se planta al principio de la VRAM
	call FIJA_ESCRITURA		;40f9
BORRA_LA_VRAM:
	ld b,e			;40fc
	ld a,e			;40fd
	call REPITE_BYTE		;40fe   ; escribe 256 bytes de una tacada
	dec d			;4101   ; hasta cubrir los 16 KB
	jr nz,BORRA_LA_VRAM		;4102
	call 00096h		;4104   ; BIOS RDPSG - Reads value from PSG-register | lee el PSG para dejarlo en un estado conocido
	ld a,001h		;4107
	ld (0e01eh),a		;4109   ; candado puesto: la interrupcion no debe pisar los registros del VDP
	ld hl,04e73h		;410c   ; los ocho registros del VDP
	ld d,008h		;410f
	ld c,000h		;4111
SUBE_LOS_REGISTROS_DEL_VDP:
	ld b,(hl)			;4113
	call 00047h		;4114   ; BIOS WRTVDP - Writes data in the VDP-register | registro C con el valor B
	inc hl			;4117
	inc c			;4118
	dec d			;4119
	jr nz,SUBE_LOS_REGISTROS_DEL_VDP		;411a
	xor a			;411c
	ld (0e01eh),a		;411d   ; candado quitado
	ei			;4120
	ld a,001h		;4121
	call ESPERA_PUNTOS		;4123   ; espera cuatro puntos de espera, o sea 128 cuadros
	di			;4126
	ld hl,05c96h		;4127   ; el guion de la pantalla del titulo
	call GUION_LARGO		;412a
	ld de,00000h		;412d   ; copia la tabla de patrones sobre la de color
	ld hl,MIRA_AL_SEGUNDO		;4130
	call COPIA_VRAM_A_VRAM		;4133
	ld de,02000h		;4136   ; y el tercer tercio sobre el segundo
	ld hl,06800h		;4139
	call COPIA_VRAM_A_VRAM		;413c
	ld a,005h		;413f   ; espera de ocho, unos cinco segundos
	ld (0e001h),a		;4141
	ei			;4144
	ld a,(0e006h)		;4145   ; con 0xE006 puesto se salta la espera del titulo
	or a			;4148
	jr nz,MENU		;4149
	ld hl,07a8bh		;414b   ; la flecha empieza en la ultima fila y sube
	ld (0e230h),hl		;414e

; ----------------------------------------------------------------------
; ==========  LA PANTALLA DEL TITULO  ==========
; Sube el rotulo una fila cada dos cuadros y espera a que toquen una
; tecla. Si no la tocan, cae en la demo.
; ----------------------------------------------------------------------
SUBE_EL_ROTULO:
	ld hl,0e000h		;4151
	ld a,(hl)			;4154
	and 003h		;4155   ; una de cada cuatro cuadros
	jr nz,TITULO_MIRA_LAS_TECLAS		;4157
	inc (hl)			;4159   ; el contador de cuadros va de dos en dos mientras dura esto
	inc (hl)			;415a
	ld de,(0e230h)		;415b   ; la fila de VRAM donde va ahora el rotulo
	ld hl,0786bh		;415f   ; cuando llega a 0x386B ya esta arriba del todo
	xor a			;4162
	sbc hl,de		;4163
	jr z,ROTULO_ARRIBA		;4165
	di			;4167
	xor a			;4168   ; el primer codigo de caracter del rotulo
	ld b,003h		;4169   ; tres caracteres en la fila de arriba
	call SUBE_CODIGOS_CORRELATIVOS		;416b
	ld b,00bh		;416e   ; once en la de en medio
	call SUBE_CODIGOS_CORRELATIVOS		;4170
	ld b,00ch		;4173   ; y doce en la de abajo
	call SUBE_CODIGOS_CORRELATIVOS		;4175
	ld b,00ch		;4178
	call FIJA_ESCRITURA		;417a   ; se pone en la fila siguiente
	xor a			;417d
	call REPITE_BYTE_EN_DE		;417e   ; y la borra, que es la que el rotulo acaba de dejar
	ei			;4181
	ld hl,0e230h		;4182
	ld a,(hl)			;4185   ; sube la direccion una fila, o sea 0x20 hacia atras
	sub 020h		;4186
	ld (hl),a			;4188
	jr nc,ROTULO_ARRIBA		;4189
	inc hl			;418b
	dec (hl)			;418c
ROTULO_ARRIBA:
	ld a,(0e001h)		;418d   ; con 0xE001 a cero se acabo la espera
	or a			;4190
	jr z,MENU		;4191
TITULO_MIRA_LAS_TECLAS:
	ld a,(0e005h)		;4193
	and 03fh		;4196   ; cualquiera de los seis mandos vale
	jr z,SUBE_EL_ROTULO		;4198
MENU:
	di			;419a
	call PINTA_EL_MARCO_DEL_MENU		;419b   ; pinta el marco del menu
	call PINTA_LA_FLECHA		;419e   ; y la flecha en la linea elegida
	ld a,008h		;41a1   ; ocho puntos de espera, unos cinco segundos
	ld (0e001h),a		;41a3
	ei			;41a6
MENU_ESPERA:
	call MUEVE_LA_FLECHA		;41a7   ; mueve la flecha o devuelve acarreo si han elegido
	ld hl,0e002h		;41aa
	ld (hl),000h		;41ad   ; mientras se elige, la demo queda armada
	jr c,EMPIEZA_LA_PARTIDA		;41af
	ld (hl),001h		;41b1   ; mientras se elige la interrupcion lee los mandos del menu
	ld a,(0e001h)		;41b3
	or a			;41b6
	jp z,PARTIDA_NUEVA		;41b7   ; se acabo la espera: a la demo
	jr MENU_ESPERA		;41ba
EMPIEZA_LA_PARTIDA:
	xor a			;41bc
	ld hl,0e01bh		;41bd
	bit 0,(hl)		;41c0   ; lineas impares (1 y 3) son de un jugador
	jr nz,GUARDA_EL_NUMERO_DE_JUGADORES		;41c2
	inc a			;41c4
GUARDA_EL_NUMERO_DE_JUGADORES:
	ld (0e010h),a		;41c5   ; 0xE010: juegan dos
	ld a,(hl)			;41c8
	cp 003h		;41c9   ; las lineas 1 y 2 son con joystick
	ld a,000h		;41cb
	jr nc,GUARDA_EL_MANDO_ELEGIDO		;41cd
	inc a			;41cf
GUARDA_EL_MANDO_ELEGIDO:
	ld (0e004h),a		;41d0   ; 0xE004: se juega con joystick
	ld a,(hl)			;41d3
	ld hl,04ed5h		;41d4   ; y el mensaje del menu que hay que borrar
	dec a			;41d7
	jr z,EMPIEZA_EL_PARPADEO_DEL_MENU		;41d8
	ld hl,04eedh		;41da
	dec a			;41dd
	jr z,EMPIEZA_EL_PARPADEO_DEL_MENU		;41de
	ld hl,04f05h		;41e0
	dec a			;41e3
	jr z,EMPIEZA_EL_PARPADEO_DEL_MENU		;41e4
	ld hl,04f1dh		;41e6
EMPIEZA_EL_PARPADEO_DEL_MENU:
	xor a			;41e9
	ld (0e000h),a		;41ea
TITULO_PARPADEA:
	ei			;41ed
	ld a,(0e000h)		;41ee
	bit 3,a		;41f1   ; el bit 3 del contador de cuadros hace el parpadeo
	di			;41f3
	jr z,TITULO_SIN_PARPADEO		;41f4
	push hl			;41f6
	ld d,(hl)			;41f7   ; la direccion de VRAM que encabeza el mensaje elegido
	inc hl			;41f8
	ld e,(hl)			;41f9
	inc hl			;41fa
	ld b,01ah		;41fb   ; 0x1A caracteres, los que ocupa la linea
	ld c,000h		;41fd
	call REPITE_BYTE_EN_DE		;41ff   ; los borra
	pop hl			;4202
	jr TITULO_PARPADEA		;4203
TITULO_SIN_PARPADEO:
	push hl			;4205
	call GUION_CORTO		;4206   ; vuelve a escribir la linea entera
	ld hl,0e000h		;4209
	bit 6,(hl)		;420c   ; y sale cuando el contador pasa de 0x40
	pop hl			;420e
	jr z,TITULO_PARPADEA		;420f
	di			;4211
	ld a,096h		;4212   ; sonido 0x96: la sintonia de arranque
	call PIDE_UN_SONIDO		;4214
	ei			;4217
PARTIDA_NUEVA:
	ld hl,0e015h		;4218
	ld a,001h		;421b   ; ronda 1
	ld (hl),a			;421d
	inc hl			;421e
	ld (hl),a			;421f   ; y prueba 1
	ld hl,05008h		;4220   ; la marca a batir de la primera ronda
	ld de,0e051h		;4223
	call COPIA_DOS_BYTES		;4226
	ld hl,0e021h		;4229
	ld a,(0e010h)		;422c   ; con un solo jugador, el segundo arranca ya eliminado
	or a			;422f
	jr nz,MONTA_LA_PRUEBA		;4230
	ld (hl),002h		;4232
MONTA_LA_PRUEBA:
	di			;4234
	call LIMPIA_LA_TABLA_DE_NOMBRES		;4235   ; limpia la tabla de nombres
	ld hl,06362h		;4238   ; el marco del marcador
	call GUION_LARGO		;423b
	ld hl,0e025h		;423e   ; intento 1 del jugador 1
	ld (hl),001h		;4241
	ld a,(0e021h)		;4243
	rrca			;4246   ; si el jugador 1 esta fuera, se le ponen cuatro (o sea, ninguno)
	jr nc,INTENTO_DEL_JUGADOR_2		;4247
	ld (hl),004h		;4249
INTENTO_DEL_JUGADOR_2:
	inc hl			;424b
	ld (hl),001h		;424c   ; intento 1 del jugador 2
	rrca			;424e
	jr nc,MONTA_EL_DECORADO		;424f
	ld (hl),004h		;4251   ; lo mismo para el jugador 2
MONTA_EL_DECORADO:
	di			;4253
	ld hl,04f3bh		;4254   ; la lista de guiones de esta prueba
	call CASILLA_DE_LA_PRUEBA		;4257
	ld b,(hl)			;425a   ; cuantos guiones lleva
	inc hl			;425b
MONTA_UN_GUION:
	push bc			;425c
	di			;425d
	call GUION_LARGO		;425e   ; uno por vuelta, dejando entrar la interrupcion entre medias
	ei			;4261
	pop bc			;4262
	djnz MONTA_UN_GUION		;4263
	ld hl,04f33h		;4265   ; y detras, el rotulo de la pizarra
	call CASILLA_DE_LA_PRUEBA		;4268
	di			;426b
	call GUION_LARGO		;426c
	ld hl,05024h		;426f   ; el marco del marcador de arriba
	call GUION_CORTO		;4272   ; el rotulo del segundo jugador si lo hay
	call ES_PRUEBA_DE_DISTANCIA		;4275   ; en longitud y martillo se anade la columna de intentos
	jr z,PINTA_EL_TURNO		;4278
	ld hl,050f4h		;427a
	call GUION_CORTO		;427d
PINTA_EL_TURNO:
	ld hl,0513dh		;4280
	ld de,078a2h		;4283   ; la casilla del jugador 1
	ld b,003h		;4286
	ld a,(0e021h)		;4288
	rrca			;428b   ; prueba impar: le toca al 1
	jr c,PINTA_LA_CASILLA_DEL_TURNO		;428c
	rrca			;428e
	jr nc,EMPIEZA_EL_INTENTO		;428f
	ld e,0c2h		;4291   ; si no, la casilla del jugador 2
PINTA_LA_CASILLA_DEL_TURNO:
	call SUBE_BYTES_SEGURO		;4293
EMPIEZA_EL_INTENTO:
	call BORRA_LA_FILA_DE_LA_MARCA		;4296   ; borra la fila de la marca
	call PINTA_LOS_TANTOS		;4299   ; pinta los tantos
	ld hl,0e051h		;429c   ; la marca a batir de esta ronda
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;429f
	ld de,07877h		;42a2   ; en la casilla de QUALIFY
	call PINTA_MARCA_SIN_INTERRUPCION		;42a5
	ld hl,0e041h		;42a8   ; el record del mundo de esta prueba
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;42ab
	ld de,07833h		;42ae   ; en la casilla de WORLD RECORD
	call PINTA_MARCA_SIN_INTERRUPCION		;42b1
	ld de,05a40h		;42b4   ; borra los patrones de sprite de 0x1A40
	ld b,000h		;42b7
	ld c,b			;42b9
	call REPITE_BYTE_SEGURO		;42ba
	call BORRA_LOS_HUECOS_DE_CIFRA		;42bd   ; sube los ceros de la fuente a los cuatro huecos de cifra
	ld hl,0e0a0h		;42c0   ; limpia el estado de los dos atletas
	ld bc,000bfh		;42c3
	call LIMPIA_MEMORIA		;42c6
	ld hl,0e200h		;42c9   ; y el trozo de 0xE200
	ld c,01fh		;42cc
	call LIMPIA_MEMORIA		;42ce
	ld hl,00000h		;42d1   ; pone a cero el reloj de la prueba
	ld (0e028h),hl		;42d4
	ld b,002h		;42d7
	ld hl,0e0f2h		;42d9
	ld a,010h		;42dc
COLOCA_LOS_DOS_ATLETAS:
	ld (hl),0cfh		;42de   ; fila 0xCF, o sea el suelo
	inc hl			;42e0
	inc hl			;42e1
	ld (hl),a			;42e2   ; columna 0x10 el primero y 0x20 el segundo
	ld l,0f6h		;42e3   ; salta a la ficha del segundo
	ld a,020h		;42e5
	djnz COLOCA_LOS_DOS_ATLETAS		;42e7
	ld a,08fh		;42e9   ; y este arranca en 0x8F
	ld (0e0fah),a		;42eb
	call FICHA_DEL_QUE_JUEGA		;42ee   ; la ficha del atleta al que le toca
	ld (hl),078h		;42f1   ; columna 0x78
	call ES_PRUEBA_IMPAR		;42f3   ; en las pruebas impares
	jr c,COLOCA_AL_QUE_JUEGA		;42f6
	ld (hl),07dh		;42f8   ; y 0x7D en las pares
COLOCA_AL_QUE_JUEGA:
	inc hl			;42fa
	ld (hl),020h		;42fb
	inc hl			;42fd
	ld (hl),010h		;42fe
	call ES_PRUEBA_DE_DISTANCIA		;4300   ; en longitud y martillo se pinta la tabla de intentos
	jr z,MONTA_LOS_ACTORES_Y_SIGUE		;4303
	ld hl,05111h		;4305
	call GUION_CORTO		;4308
MONTA_LOS_ACTORES_Y_SIGUE:
	call MONTA_LOS_ACTORES_DE_LA_PRUEBA		;430b   ; sube las figuras de los actores
	call MONTA_LOS_ACTORES		;430e   ; y el decorado que se mueve
	call ES_PRUEBA_DE_DISTANCIA		;4311   ; en las pruebas de distancia hay que pintar la lista de intentos
	jr z,SUBE_LOS_COLORES_DE_LOS_SPRITES		;4314
	call FILA_DEL_INTENTO		;4316   ; el intento en curso del jugador que juega
	ld b,(hl)			;4319
	ld de,07897h		;431a   ; la fila de la tabla de intentos
	ld hl,0e061h		;431d
	call FILA_DEL_MARCADOR_DE		;4320   ; y salta a la ficha de ese intento
	dec b			;4323   ; con un solo intento no hay lista que pintar
	jr z,SUBE_LOS_COLORES_DE_LOS_SPRITES		;4324
PINTA_UN_INTENTO:
	push bc			;4326
	ld a,(hl)			;4327   ; con marca a cero el intento aun no se ha hecho
	or a			;4328
	jr z,INTENTO_SIN_MARCA		;4329
	push de			;432b
	call PINTA_MARCA_SIN_INTERRUPCION		;432c   ; pinta la marca de ese intento
	pop de			;432f
	inc hl			;4330
	call BAJA_UNA_FILA		;4331   ; y baja a la fila siguiente
	jr SIGUIENTE_INTENTO_DE_LA_LISTA		;4334
INTENTO_SIN_MARCA:
	inc hl			;4336
	inc hl			;4337
	inc hl			;4338
	push hl			;4339   ; se guarda la fila
	ld hl,05133h		;433a   ; el rotulo de fallo
	ld b,006h		;433d
	call SUBE_BYTES_SEGURO		;433f   ; seis caracteres
	call BAJA_UNA_FILA		;4342
	pop hl			;4345
SIGUIENTE_INTENTO_DE_LA_LISTA:
	pop bc			;4346
	djnz PINTA_UN_INTENTO		;4347
SUBE_LOS_COLORES_DE_LOS_SPRITES:
	di			;4349
	ld hl,05154h		;434a   ; la tabla de colores de los 32 sprites
	ld de,07b00h		;434d   ; empezando en el sprite 0
	ld bc,020feh		;4350   ; 32 sprites, columna inicial 0xFE
	call FIJA_ESCRITURA		;4353
	exx			;4356
	ld a,(00006h)		;4357   ; el puerto de datos del VDP en el juego alterno
	ld c,a			;435a
	exx			;435b
UN_SPRITE:
	ld a,0d1h		;435c   ; fila 0xD1: fuera de la pantalla
	exx			;435e
	out (c),a		;435f
	exx			;4361
	ld a,c			;4362   ; la columna avanza de cuatro en cuatro
	add a,004h		;4363
	ld c,a			;4365
	exx			;4366
	out (c),a		;4367   ; columna
	exx			;4369
	push hl			;436a   ; un respiro para que al VDP le de tiempo
	pop hl			;436b
	exx			;436c
	out (c),a		;436d   ; y patron, que aqui lleva el mismo valor
	exx			;436f
	ld a,(hl)			;4370   ; el color sale de la tabla
	inc hl			;4371
	exx			;4372
	out (c),a		;4373
	exx			;4375
	djnz UN_SPRITE		;4376
	ei			;4378
ESPERA_A_QUE_ACABE_LA_MUSICA:
	ld a,(0e162h)		;4379   ; mientras el canal 1 tenga sonido, aqui se espera
	or a			;437c
	jr nz,ESPERA_A_QUE_ACABE_LA_MUSICA		;437d
	inc a			;437f
	ld (0e003h),a		;4380   ; ya hay partida
	ld (0e017h),a		;4383   ; y demo apagada
	ld a,004h		;4386   ; cuatro puntos de espera
	call ESPERA_PUNTOS		;4388
	di			;438b
	ld a,092h		;438c   ; sonido 0x92: los preparados
	call PIDE_UN_SONIDO		;438e
	ei			;4391
	xor a			;4392
	ld (0e017h),a		;4393
BUCLE_DE_LA_PRUEBA:
	call ES_LA_DEMO		;4396   ; en la demo, cualquier tecla vuelve al titulo
	jr z,PINTA_LA_MARCA		;4399
	ld hl,0e005h		;439b   ; si han tocado una tecla se vuelve al titulo
	ld a,(hl)			;439e
	or a			;439f
	jr z,PINTA_LA_MARCA		;43a0
	inc hl			;43a2
	ld (hl),a			;43a3
	xor a			;43a4
	ld (0e003h),a		;43a5
	jp ARRANQUE_DE_LA_PRESENTACION		;43a8   ; vuelta a la presentacion
PINTA_LA_MARCA:
	call ES_PRUEBA_DE_DISTANCIA		;43ab
	jr nz,PINTA_LA_DISTANCIA		;43ae   ; en los 100 y los 400 la marca es un tiempo
	ld de,07a47h		;43b0   ; la casilla del reloj
	ld hl,0e0e3h		;43b3
	call PINTA_DOS_CARACTERES		;43b6
	ld de,07a58h		;43b9   ; y la del reloj del segundo jugador
	ld hl,0e0adh		;43bc
	call PINTA_DOS_CARACTERES		;43bf
	jp REPARTE_EL_TRABAJO_DEL_CUADRO		;43c2
PINTA_LA_DISTANCIA:
	ld hl,0e0adh		;43c5
	ld de,07af9h		;43c8   ; la casilla de los metros
	call PINTA_DOS_CARACTERES		;43cb
	dec hl			;43ce
	ld de,07ae7h		;43cf   ; y el angulo, justo antes
	ld a,(hl)			;43d2
	or a			;43d3
	jr nz,RECORTA_EL_ANGULO		;43d4   ; con angulo cero no hay flecha que pintar
	ld bc,00ee0h		;43d6   ; borra los 0x0E caracteres de la barra
	inc de			;43d9
	call REPITE_BYTE_SEGURO		;43da
	dec de			;43dd
	jr PINTA_EL_TRAMO_A_MEDIAS		;43de
RECORTA_EL_ANGULO:
	cp 010h		;43e0   ; por encima de 0x10 la barra se acorta seis
	jr c,PINTA_LA_BARRA_DEL_ANGULO		;43e2
	sub 006h		;43e4
PINTA_LA_BARRA_DEL_ANGULO:
	ld c,0e7h		;43e6   ; el caracter de la barra llena
	ld b,a			;43e8   ; tantos como diga el angulo
	push af			;43e9
	call REPITE_BYTE_SEGURO		;43ea   ; los pinta
	pop af			;43ed
	cp 00fh		;43ee   ; con quince tramos la barra esta llena
	jr z,REPARTE_EL_TRABAJO_DEL_CUADRO		;43f0
	push af			;43f2
	call BAJA_HL_EN_DE		;43f3   ; se corre al siguiente hueco
	pop af			;43f6
	ld b,a			;43f7
	ld a,00fh		;43f8   ; lo que falta hasta quince
	sub b			;43fa
	jr z,PINTA_EL_TRAMO_A_MEDIAS		;43fb
	ld b,a			;43fd
	dec b			;43fe   ; uno menos, que lleva el tramo a medias
	jr z,PINTA_EL_TRAMO_A_MEDIAS		;43ff
	ld c,0e0h		;4401   ; caracter 0xE0: la barra vacia
	push af			;4403
	inc de			;4404   ; y se rellena el resto
	call REPITE_BYTE_SEGURO		;4405
	dec de			;4408
	pop af			;4409
PINTA_EL_TRAMO_A_MEDIAS:
	ld b,000h		;440a
	dec hl			;440c   ; la cifra de abajo del angulo
	ld a,(hl)			;440d
	or a			;440e
	jr z,PINTA_EL_TRAMO_SUELTO		;440f   ; con cero no hay tramo a medias
	ld c,015h		;4411   ; cada tramo son quince centesimas
CUENTA_LOS_TRAMOS_DE_LA_BARRA:
	inc b			;4413
	sub c			;4414   ; restando de quince en quince en BCD
	daa			;4415
	jr nc,CUENTA_LOS_TRAMOS_DE_LA_BARRA		;4416
PINTA_EL_TRAMO_SUELTO:
	ld a,0e0h		;4418   ; el primer caracter de la escala de barras
	add a,b			;441a
	ld b,001h		;441b   ; un solo caracter
	ld c,a			;441d
	call REPITE_BYTE_SEGURO		;441e
REPARTE_EL_TRABAJO_DEL_CUADRO:
	call ES_PRUEBA_DE_DISTANCIA		;4421
	jp z,CUADRO_DE_LAS_PRUEBAS_DE_TIEMPO		;4424   ; en los 100 y los 400 se va por otro lado
	ld a,(0e020h)		;4427
	bit 2,a		;442a   ; bit 2 de 0xE020: la prueba ha terminado
	jr z,MIRA_EL_ROTULO_DE_UNIDAD		;442c
	ld de,07aa5h		;442e   ; la casilla del resultado
	ld hl,0e033h		;4431
	call ES_PRUEBA_IMPAR		;4434   ; en las pruebas impares es la de la izquierda
	jr nc,PINTA_EL_RESULTADO_DEL_TIRO		;4437
	ld e,035h		;4439
PINTA_EL_RESULTADO_DEL_TIRO:
	call PINTA_UNA_CIFRA_SEGURA		;443b
MIRA_EL_ROTULO_DE_UNIDAD:
	ld a,(0e02ch)		;443e   ; bit 0 de 0xE02C: el intento ha acabado
	rrca			;4441
	jr nc,MIRA_LA_LISTA_DE_INTENTOS		;4442
	ld de,079ech		;4444   ; el rotulo de la unidad
	ld hl,05139h		;4447
	call ES_PRUEBA_IMPAR		;444a
	jr nc,PINTA_EL_ROTULO_DE_UNIDAD		;444d
	ld e,0edh		;444f   ; o la casilla del segundo jugador
PINTA_EL_ROTULO_DE_UNIDAD:
	ld b,004h		;4451
	call SUBE_BYTES_SEGURO		;4453
	jr MIRA_SI_ACABO_EL_INTENTO		;4456
MIRA_LA_LISTA_DE_INTENTOS:
	ld a,(0e020h)		;4458
	bit 2,a		;445b
	jr z,MIRA_SI_ACABO_EL_INTENTO		;445d
	call FILA_DEL_INTENTO		;445f   ; el intento en curso
	ld a,(hl)			;4462
	ld hl,0e030h		;4463
	ld de,07877h		;4466
	push af			;4469
	ld b,a			;446a
BAJA_A_LA_FILA_DEL_INTENTO:
	call BAJA_UNA_FILA		;446b
	djnz BAJA_A_LA_FILA_DEL_INTENTO		;446e
	di			;4470
	call PINTA_UNA_MARCA		;4471   ; pinta la marca en la lista de intentos
	ld hl,0e061h		;4474
	call FILA_DEL_MARCADOR_DE		;4477
	pop af			;447a
	call SALTA_N_FILAS_DE_TRES		;447b   ; salta a la fila de ese intento
	ex de,hl			;447e
	ld hl,0e030h		;447f
	call COPIA_DOS_BYTES		;4482   ; y la guarda
	ei			;4485
MIRA_SI_ACABO_EL_INTENTO:
	ld a,(0e02eh)		;4486   ; bit 0 de 0xE02E: se acabo el intento
	rrca			;4489
	jp nc,MIRA_SI_SE_ACABO_LA_PRUEBA		;448a
	ld hl,0e06bh		;448d   ; la fila de la mejor marca del jugador
	call FILA_DEL_MARCADOR_DE		;4490
	push hl			;4493
	call FILA_DEL_MARCADOR		;4494   ; la casilla de la marca de este intento
	ex de,hl			;4497
	call FILA_DEL_INTENTO		;4498
	ex de,hl			;449b
	ld a,(de)			;449c
	call SALTA_N_FILAS_DE_TRES		;449d
	ex de,hl			;44a0
	pop hl			;44a1
	push de			;44a2
	call COMPARA_TRES_BYTES		;44a3   ; compara la marca nueva con la que habia
	jr c,COMPARA_CON_LA_MARCA_A_BATIR		;44a6   ; si no la mejora, no se toca
	ex de,hl			;44a8
	inc hl			;44a9
	inc de			;44aa
	call COPIA_DOS_BYTES		;44ab   ; y si la mejora, la sustituye
COMPARA_CON_LA_MARCA_A_BATIR:
	pop de			;44ae
	ld hl,0e052h		;44af   ; la marca a batir de la ronda
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;44b2
	call COMPARA_TRES_BYTES		;44b5   ; compara la marca con ella
	jp nc,INTENTO_QUE_CLASIFICA		;44b8   ; si no llega, intento fallido
	ld a,(0e02ch)		;44bb   ; bit 0 de 0xE02C: era un nulo
	rrca			;44be
	jr nc,INTENTO_QUE_NO_CLASIFICA		;44bf
	ld hl,0e023h		;44c1
	call FILA_DEL_INTENTO_DE		;44c4   ; sube el contador de intentos
	inc (hl)			;44c7
	push hl			;44c8
	call FILA_DEL_INTENTO		;44c9
	ld b,(hl)			;44cc   ; y borra su fila
	ld de,07877h		;44cd
	ld hl,05133h		;44d0
BORRA_LA_FILA_DEL_INTENTO:
	call BAJA_UNA_FILA		;44d3
	djnz BORRA_LA_FILA_DEL_INTENTO		;44d6
	ld b,006h		;44d8
	call SUBE_BYTES_SEGURO		;44da   ; con los seis caracteres del rotulo de fallo
	pop hl			;44dd
	di			;44de
	ld a,003h		;44df   ; resultado 3: intento nulo
	ld (0e02ah),a		;44e1
	cp (hl)			;44e4   ; con los tres intentos gastados se acabo
	jp z,GUARDA_LA_MARCA		;44e5
INTENTO_QUE_NO_CLASIFICA:
	ld a,002h		;44e8   ; resultado 2: vale pero no clasifica
	ld (0e02ah),a		;44ea
	ld hl,0e020h		;44ed
	ld b,(hl)			;44f0
	call A_QUIEN_LE_TOCA		;44f1   ; el jugador que juega
	jr z,MIRA_EL_BIT_DE_CLASIFICADO		;44f4
	rrc b		;44f6
MIRA_EL_BIT_DE_CLASIFICADO:
	rrc b		;44f8   ; mira su bit de clasificado
	jr c,GUARDA_LA_MARCA		;44fa   ; si ya estaba clasificado no se hace nada
	call FILA_DEL_INTENTO		;44fc
	ld a,(hl)			;44ff
	cp 003h		;4500
	jr nz,PINTA_EL_CARTEL_DE_FALLO		;4502
	ld (0e02ah),a		;4504   ; con tres intentos el resultado pasa a 3
PINTA_EL_CARTEL_DE_FALLO:
	call CASILLA_DEL_CARTEL		;4507   ; la casilla del cartel
	ld (hl),0b9h		;450a   ; caracter 0xB9: el de fallo
	jp GUARDA_LA_MARCA		;450c
INTENTO_QUE_CLASIFICA:
	ld hl,0e020h		;450f
	call A_QUIEN_LE_TOCA		;4512   ; el jugador que juega
	add a,001h		;4515
	or (hl)			;4517
	ld (hl),a			;4518   ; le pone su bit de clasificado
	ld a,001h		;4519
	ld (0e02ah),a		;451b   ; resultado 1: clasificado
	inc a			;451e
	call PIDE_UN_SONIDO		;451f   ; sonido 2: la fanfarria de clasificacion
	call CASILLA_DEL_CARTEL		;4522
	ld (hl),0bah		;4525   ; caracter 0xBA: el de clasificado
GUARDA_LA_MARCA:
	ei			;4527
	ld hl,0e02eh		;4528
	res 0,(hl)		;452b   ; baja la bandera de intento acabado
	ld hl,0e06ah		;452d   ; copia la marca del jugador 1 a su casilla de pintado
	ld de,0e08fh		;4530
	call COPIA_DOS_BYTES		;4533
	ld hl,0e07ah		;4536   ; y la del jugador 2
	ld de,0e094h		;4539
	call COPIA_DOS_BYTES		;453c
	ld de,078a7h		;453f   ; la casilla de la marca en el marcador
	ld hl,0e08fh		;4542
	ld a,(0e021h)		;4545
	bit 1,a		;4548   ; mira si el jugador 2 sigue en juego
	jr nz,PINTA_LA_MARCA_DEL_QUE_JUEGA		;454a
	ld e,0c7h		;454c   ; si no, la casilla del otro
	ld hl,0e094h		;454e
	rrca			;4551
	jr c,PINTA_LA_MARCA_DEL_QUE_JUEGA		;4552
	call PINTA_MARCA_Y_UNIDAD		;4554   ; pinta la marca del jugador 1 en su sitio
	ld hl,0e08fh		;4557
	ld de,078a7h		;455a
PINTA_LA_MARCA_DEL_QUE_JUEGA:
	call PINTA_MARCA_Y_UNIDAD		;455d
	ld hl,0e042h		;4560   ; la mejor marca de la prueba
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;4563
	push hl			;4566
	call FILA_DEL_MARCADOR		;4567   ; y la casilla donde va
	ex de,hl			;456a
	call FILA_DEL_INTENTO		;456b
	ex de,hl			;456e
	ld a,(de)			;456f
	call SALTA_N_FILAS_DE_TRES		;4570
	ex de,hl			;4573
	pop hl			;4574
	call COMPARA_TRES_BYTES		;4575   ; compara la marca nueva con el record
	jr c,MIRA_SI_SE_ACABO_LA_PRUEBA		;4578   ; si no lo bate, se acabo
	ex de,hl			;457a
GUARDA_EL_RECORD_NUEVO:
	inc hl			;457b   ; y si lo bate, lo sustituye
	inc de			;457c
	call COPIA_DOS_BYTES		;457d
	ld hl,0e041h		;4580   ; la marca del record
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;4583
	ld de,07833h		;4586   ; en la casilla de WORLD RECORD
	call PINTA_MARCA_SIN_INTERRUPCION		;4589
	di			;458c
	ld a,099h		;458d   ; sonido 0x99: la musica de record del mundo
	call PIDE_UN_SONIDO		;458f
	ei			;4592
	ld hl,0e014h		;4593   ; enciende el parpadeo del rotulo
	ld (hl),001h		;4596
	ld a,00ah		;4598   ; y espera diez puntos
	ld (0e001h),a		;459a
ESPERA_AL_ROTULO:
	ld a,(hl)			;459d
	or a			;459e
	jr nz,ESPERA_AL_ROTULO		;459f
MIRA_SI_SE_ACABO_LA_PRUEBA:
	ld a,(0e02eh)		;45a1
	bit 1,a		;45a4   ; bit 1 de 0xE02E: la prueba ha terminado
	jp z,BUCLE_DE_LA_PRUEBA		;45a6   ; si no, otra vuelta
	di			;45a9
	xor a			;45aa   ; limpia las banderas de la prueba
	ld (0e02eh),a		;45ab
	xor a			;45ae
	ld h,a			;45af
	ld l,a			;45b0
	ld (0e02ah),hl		;45b1   ; y los resultados de los dos jugadores
	ld (0e02ch),hl		;45b4
	ld (0e030h),hl		;45b7
	ld (0e003h),a		;45ba   ; deja de pintar el marcador
	ld (0e017h),a		;45bd
	ei			;45c0
	ld a,003h		;45c1   ; tres puntos de espera
	call ESPERA_PUNTOS		;45c3
	di			;45c6
	ld a,0a5h		;45c7   ; sonido 0xA5: la marcha del final de prueba
	call PIDE_UN_SONIDO		;45c9
	call MUEVE_EL_SONIDO		;45cc   ; y para la musica
	ei			;45cf
	call ES_LA_DEMO		;45d0   ; si han tocado tecla, al titulo
	jr z,MIRA_LOS_INTENTOS_QUE_QUEDAN		;45d3
	xor a			;45d5
	ld (0e002h),a		;45d6
	jp ARRANQUE_DE_LA_PRESENTACION		;45d9
MIRA_LOS_INTENTOS_QUE_QUEDAN:
	call ES_PRUEBA_DE_DISTANCIA		;45dc
	jr z,MIRA_QUIEN_SIGUE		;45df   ; en los 100 y los 400 no hay intentos
	call FILA_DEL_INTENTO		;45e1   ; sube el intento del jugador que juega
	inc (hl)			;45e4
	call CAMBIA_DE_JUGADOR		;45e5   ; y cambia de jugador si toca
	ei			;45e8
	ld hl,0e025h		;45e9
	ld a,004h		;45ec   ; con el cuarto intento se acaba
	cp (hl)			;45ee
	jp nz,EMPIEZA_EL_INTENTO		;45ef   ; mientras quede intento al jugador 1, otra vuelta
	inc hl			;45f2
	cp (hl)			;45f3
	jp nz,EMPIEZA_EL_INTENTO		;45f4   ; o al jugador 2
MIRA_QUIEN_SIGUE:
	ld hl,0e021h		;45f7
	bit 0,(hl)		;45fa   ; el jugador 2 sigue en juego
	jr nz,MIRA_AL_JUGADOR_1		;45fc
	dec hl			;45fe
	bit 0,(hl)		;45ff   ; si el 1 tampoco, se acabo la partida
	jp z,SE_ACABO_LA_PARTIDA		;4601
	inc hl			;4604
	bit 1,(hl)		;4605   ; y si el 2 no se ha clasificado, tambien
	jr nz,SIGUIENTE_RONDA		;4607
MIRA_AL_JUGADOR_1:
	dec hl			;4609
	bit 1,(hl)		;460a   ; el jugador 1 se ha clasificado
	jp z,SE_ACABO_LA_PARTIDA		;460c
SIGUIENTE_RONDA:
	call PINTA_LOS_TANTOS_GANADOS		;460f   ; pinta los tantos que se han ganado
	ld hl,0e015h		;4612
	inc (hl)			;4615   ; sube la ronda
	inc hl			;4616
	inc (hl)			;4617   ; y la prueba
	ld a,(hl)			;4618
	cp 005h		;4619   ; tras la cuarta prueba
	jr nz,MIRA_SI_QUEDAN_RONDAS		;461b
	ld (hl),001h		;461d   ; se vuelve a la primera
MIRA_SI_QUEDAN_RONDAS:
	dec hl			;461f
	ld a,(hl)			;4620
	cp 00dh		;4621   ; las doce rondas
	jr nc,SUENA_LA_PRUEBA_NUEVA		;4623
	ld hl,05008h		;4625   ; la marca a batir de la ronda nueva
	dec a			;4628
	rlca			;4629   ; con dos bytes por ronda
	call SUMA_A_A_HL		;462a
	ex de,hl			;462d
	ld hl,0e051h		;462e   ; y la casilla donde va
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;4631
	ex de,hl			;4634
	call COPIA_DOS_BYTES		;4635
SUENA_LA_PRUEBA_NUEVA:
	ld a,(0e016h)		;4638
	dec a			;463b
	ld a,096h		;463c   ; sonido 0x96 en la primera prueba
	jr z,SUENA_Y_LIMPIA		;463e
	ld a,09ch		;4640   ; y 0x9C en las demas
SUENA_Y_LIMPIA:
	di			;4642
	call PIDE_UN_SONIDO		;4643
	ei			;4646
	ld hl,0e022h		;4647   ; borra los resultados del intento
	ld bc,0000fh		;464a
	call LIMPIA_MEMORIA		;464d
	ld hl,0e089h		;4650   ; y las marcas que se pintan
	ld c,010h		;4653
	call LIMPIA_MEMORIA		;4655
	ld hl,0e060h		;4658   ; y el trozo de marcador
	ld c,01bh		;465b
	call LIMPIA_MEMORIA		;465d
	xor a			;4660
	ld (0e020h),a		;4661   ; nadie clasificado todavia
ESPERA_AL_SONIDO:
	ld a,(0e162h)		;4664   ; hasta que el canal 1 se calle
	or a			;4667
	jr nz,ESPERA_AL_SONIDO		;4668
	jp MONTA_LA_PRUEBA		;466a   ; y a montar la prueba nueva
SE_ACABO_LA_PARTIDA:
	ld hl,0e022h		;466d
	ld a,(0e021h)		;4670   ; quien seguia en juego
	ld b,a			;4673
	ld a,(0e02ch)		;4674   ; y si al jugador 1 le queda intento
	rrca			;4677
	jr nc,MIRA_EL_INTENTO_DEL_JUGADOR_2		;4678
SIGUE_EL_JUGADOR_1:
	ld (hl),001h		;467a   ; marca al jugador 1 como el que sigue
	set 0,b		;467c
	jr CARTEL_DE_FIN		;467e
MIRA_EL_INTENTO_DEL_JUGADOR_2:
	ld a,(0e02dh)		;4680
	rrca			;4683
	jr nc,MIRA_QUIEN_ESTABA_EN_JUEGO		;4684
SIGUE_EL_JUGADOR_2:
	ld (hl),002h		;4686   ; marca al jugador 2
	set 1,b		;4688
	jr CARTEL_DE_FIN		;468a
MIRA_QUIEN_ESTABA_EN_JUEGO:
	ld a,b			;468c
	rrca			;468d
	jr c,SIGUE_EL_JUGADOR_2		;468e
	rrca			;4690
	jr c,SIGUE_EL_JUGADOR_1		;4691
	ld a,(0e020h)		;4693   ; los bits de clasificado
	rrca			;4696
	jr c,MIRA_AL_SEGUNDO_CLASIFICADO		;4697
	set 0,b		;4699
	set 0,(hl)		;469b
MIRA_AL_SEGUNDO_CLASIFICADO:
	rrca			;469d
	jr c,CARTEL_DE_FIN		;469e
	set 1,b		;46a0
	set 1,(hl)		;46a2
CARTEL_DE_FIN:
	push bc			;46a4
	di			;46a5
	ld a,09fh		;46a6   ; sonido 0x9F: la musica de fin de partida
	call PIDE_UN_SONIDO		;46a8
	ei			;46ab
	ld hl,05140h		;46ac   ; el cartel de GAME OVER
	call GUION_CORTO		;46af
	ld a,(0e022h)		;46b2   ; quien sigue
	dec a			;46b5
	jr z,ESPERA_AL_FIN		;46b6
	dec a			;46b8
	jr z,BORRA_EL_CARTEL		;46b9
	ld a,003h		;46bb   ; tres puntos de espera
	call ESPERA_PUNTOS		;46bd
	call MONTA_LOS_ACTORES		;46c0   ; vuelve a pintar el decorado
	ei			;46c3
	ld a,002h		;46c4   ; dos puntos mas
	call ESPERA_PUNTOS		;46c6
	ld hl,05140h		;46c9   ; y el cartel otra vez
	call GUION_CORTO		;46cc
BORRA_EL_CARTEL:
	ld de,0798ah		;46cf   ; la fila del cartel
	ld bc,001f2h		;46d2   ; 0x1F caracteres en blanco
	call REPITE_BYTE_SEGURO		;46d5
ESPERA_AL_FIN:
	ld a,(0e162h)		;46d8   ; hasta que se calle la musica
	or a			;46db
	jr nz,ESPERA_AL_FIN		;46dc
	pop bc			;46de
	ld a,b			;46df
	ld (0e021h),a		;46e0   ; deja apuntado quien sigue
	cp 003h		;46e3
	jr z,FIN_DE_LA_PARTIDA		;46e5   ; con los dos fuera se acabo del todo
	and 001h		;46e7
	ld (0e011h),a		;46e9   ; y con uno, ese pasa a ser el jugador
	ld hl,0e02ch		;46ec
	bit 0,(hl)		;46ef   ; si al jugador 1 le quedaba intento
	jp nz,OTRA_VEZ_A_LA_LINEA		;46f1
	inc hl			;46f4
	bit 0,(hl)		;46f5   ; o al 2
	jp nz,OTRA_VEZ_A_LA_LINEA		;46f7
	jp SIGUIENTE_RONDA		;46fa   ; se sigue jugando
FIN_DE_LA_PARTIDA:
	call PINTA_LOS_TANTOS_GANADOS		;46fd   ; los tantos finales
	ld a,003h		;4700   ; tres puntos de espera
	call ESPERA_PUNTOS		;4702
	jp ARRANQUE_DE_LA_PRESENTACION		;4705   ; y a la presentacion
CUADRO_DE_LAS_PRUEBAS_DE_TIEMPO:
	ld a,(0e029h)		;4708
	rlca			;470b   ; MEDIDO: aqui solo se entra en la demo. El bit 7 de 0xE029 esta puesto tambien en partida, pero entonces manda 0xE002 y este trozo no corre
	jp nc,MIRA_EL_FIN_DEL_INTENTO		;470c
	ld hl,0e0a1h		;470f   ; la marca de la maquina
	ld de,078b4h		;4712   ; en su casilla
	call PINTA_UNA_CIFRA_SEGURA		;4715
	ld de,078b7h		;4718   ; y en la de al lado
	call PINTA_UNA_CIFRA_SEGURA		;471b
MIRA_EL_FIN_DEL_INTENTO:
	ld hl,0e023h		;471e
	ld a,(0e02ch)		;4721   ; bit 0 de 0xE02C: el jugador 1 ha llegado
	rrca			;4724
	jr c,SUBE_EL_INTENTO_DE_TIEMPO		;4725
	inc hl			;4727   ; si no, se mira el 2
	ld a,(0e02dh)		;4728
	rrca			;472b
	jr nc,MIRA_EL_FIN_DEL_TIRO		;472c
SUBE_EL_INTENTO_DE_TIEMPO:
	xor a			;472e
	ld (0e003h),a		;472f   ; deja de pintar el marcador
	inc (hl)			;4732   ; sube el intento
	ld b,(hl)			;4733
	ld de,078a7h		;4734   ; la fila del cartel
	ld a,(0e02ch)		;4737
	rrca			;473a
	jr c,PINTA_EL_CARTEL_DE_TIEMPO		;473b   ; en las pruebas impares va a la izquierda
	ld e,0c7h		;473d
PINTA_EL_CARTEL_DE_TIEMPO:
	ld c,0beh		;473f   ; caracter 0xBE
	call REPITE_BYTE_SEGURO		;4741
	ld a,(hl)			;4744   ; con tres intentos gastados se acabo
	cp 003h		;4745
	jp z,SE_ACABO_LA_PARTIDA		;4747
OTRA_VEZ_A_LA_LINEA:
	ld hl,00000h		;474a   ; limpia las banderas de los dos jugadores
	ld (0e02ch),hl		;474d
	jp PINTA_EL_TURNO		;4750   ; y a montar la prueba otra vez
MIRA_EL_FIN_DEL_TIRO:
	ld a,(0e02eh)		;4753
	rrca			;4756   ; bit 0 de 0xE02E: el tiro ha acabado
	jp nc,MIRA_SI_SE_ACABO_LA_PRUEBA		;4757
	ld hl,0e0a9h		;475a   ; la marca que ha salido
	ld de,0e06ah		;475d
	push de			;4760
	call COPIA_DOS_BYTES		;4761   ; a la casilla de pintado del jugador 1
	pop hl			;4764
	ld de,0e08fh		;4765
	call COPIA_DOS_BYTES		;4768   ; y a la del 2
	ld hl,0e0a5h		;476b   ; el tiempo del tiro
	ld de,0e07ah		;476e
	push de			;4771
	call COPIA_DOS_BYTES		;4772
	pop hl			;4775
	ld de,0e094h		;4776
	call COPIA_DOS_BYTES		;4779
	ld de,078a5h		;477c   ; la fila del reloj
	ld bc,00a00h		;477f   ; diez caracteres en blanco
	call REPITE_BYTE_SEGURO		;4782
	ld e,0c5h		;4785   ; y la del segundo jugador
	ld b,00ah		;4787
	call REPITE_BYTE_SEGURO		;4789
	ld de,0e0abh		;478c   ; la marca a batir
	ld hl,0e020h		;478f
	set 7,(hl)		;4792   ; bit 7 de 0xE020, que aqui hace de "clasifica"
	ld hl,0e0a7h		;4794
	ld b,003h		;4797
	call COMPARA_N_BYTES		;4799   ; compara los tres bytes
	jr nc,REPARTE_EL_RESULTADO		;479c
	ld hl,0e020h		;479e   ; y si no llega, se baja
	res 7,(hl)		;47a1
REPARTE_EL_RESULTADO:
	ld hl,0e052h		;47a3   ; la marca de este intento
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;47a6
	ex de,hl			;47a9
	ld hl,0e0aah		;47aa
	push de			;47ad
	di			;47ae
	ld a,003h		;47af   ; resultado 3 de entrada
	ld (0e02ah),a		;47b1
	ld a,0b9h		;47b4   ; caracter 0xB9, el de fallo
	ld (0e091h),a		;47b6
	call COMPARA_TRES_BYTES		;47b9   ; compara con la marca a batir
	jr c,REPARTE_EL_DEL_JUGADOR_2		;47bc   ; si no llega, se queda con el fallo
	ld a,0bah		;47be   ; caracter 0xBA, el de clasificado
	ld (0e091h),a		;47c0
	ld a,001h		;47c3
	ld (0e02ah),a		;47c5   ; resultado 1
	inc a			;47c8
	call PIDE_UN_SONIDO		;47c9   ; sonido 2: la fanfarria
	ld hl,0e020h		;47cc
	set 0,(hl)		;47cf   ; y le pone su bit de clasificado
REPARTE_EL_DEL_JUGADOR_2:
	pop de			;47d1
	ld hl,0e0a6h		;47d2
	ld a,003h		;47d5
	ld (0e02bh),a		;47d7   ; lo mismo para el jugador 2
	ld a,0b9h		;47da
	ld (0e096h),a		;47dc
	call COMPARA_TRES_BYTES		;47df
	jr c,REPARTE_LOS_TANTOS		;47e2
	ld a,0bah		;47e4
	ld (0e096h),a		;47e6
	ld a,001h		;47e9
	ld (0e02bh),a		;47eb
	inc a			;47ee
	call PIDE_UN_SONIDO		;47ef   ; sonido 2
	ld hl,0e020h		;47f2
	set 1,(hl)		;47f5
REPARTE_LOS_TANTOS:
	ld hl,0e02ah		;47f7
	ld a,(hl)			;47fa   ; el resultado del jugador 1
	dec a			;47fb
	jr nz,PINTA_LAS_DOS_MARCAS		;47fc   ; con resultado 1 no se toca
	inc hl			;47fe
	ld a,(hl)			;47ff
MIRA_AL_SEGUNDO:
	dec a			;4800
	jr nz,PINTA_LAS_DOS_MARCAS		;4801
	ld a,(0e020h)		;4803   ; bit 7 de 0xE020
	dec hl			;4806
	inc (hl)			;4807   ; sube el resultado del jugador 1
	rlca			;4808
	jr c,PINTA_LAS_DOS_MARCAS		;4809
	dec (hl)			;480b
	inc hl			;480c
	inc (hl)			;480d   ; o el del 2
PINTA_LAS_DOS_MARCAS:
	ei			;480e
	ld hl,0e02eh		;480f
	res 0,(hl)		;4812   ; baja la bandera de intento acabado
	ld hl,0e08fh		;4814   ; la marca del jugador 1
	ld de,078a7h		;4817   ; en su casilla
	call PINTA_MARCA_Y_UNIDAD		;481a
	ld hl,0e094h		;481d   ; y la del 2
	ld de,078c7h		;4820
	call PINTA_MARCA_Y_UNIDAD		;4823
	ld hl,0e042h		;4826   ; la mejor marca de la prueba
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;4829
	ex de,hl			;482c
	ld hl,0e0a6h		;482d
	ld a,(0e021h)		;4830   ; el jugador 1 sigue en juego
	rrca			;4833
	jr c,ELIGE_LA_MARCA_A_COMPARAR		;4834
	ld hl,0e0aah		;4836
	rrca			;4839
	jr c,ELIGE_LA_MARCA_A_COMPARAR		;483a
	ld a,(0e020h)		;483c   ; bit 7 de 0xE020
	rlca			;483f
	jr nc,ELIGE_LA_MARCA_A_COMPARAR		;4840
	ld hl,0e0a6h		;4842
ELIGE_LA_MARCA_A_COMPARAR:
	call COMPARA_TRES_BYTES		;4845   ; compara la marca con el record
	jp nc,GUARDA_EL_RECORD_NUEVO		;4848   ; si lo bate, se apunta
	jp MIRA_SI_SE_ACABO_LA_PRUEBA		;484b
CASILLA_DEL_CARTEL:
	ld hl,0e091h		;484e   ; la del jugador 1
	call A_QUIEN_LE_TOCA		;4851   ; mira a quien le toca
	ret z			;4854
	ld hl,0e096h		;4855   ; y si es el 2, la suya
	ret			;4858
ES_LA_DEMO:
	ld a,(0e002h)		;4859   ; devuelve Z cuando la partida es de verdad; con 0xE002 puesto corre la demo
	or a			;485c
	ret			;485d
PINTA_LOS_TANTOS_GANADOS:
	ld hl,0e02ch		;485e
	bit 0,(hl)		;4861   ; con el jugador 1 aun en el intento
	jr nz,BORRA_LAS_DOS_FILAS		;4863
	inc hl			;4865
	bit 0,(hl)		;4866   ; o el 2
	jr nz,BORRA_LAS_DOS_FILAS		;4868
	call PUNTUA_EL_INTENTO		;486a   ; no se cuentan todavia
BORRA_LAS_DOS_FILAS:
	ld de,078a7h		;486d   ; la fila del jugador 1
	push de			;4870
	ld bc,00900h		;4871   ; nueve caracteres en blanco
	call REPITE_BYTE_SEGURO		;4874
	ld de,078c7h		;4877   ; y la del 2
	ld b,009h		;487a
	call REPITE_BYTE_SEGURO		;487c
	pop de			;487f
	ld hl,0e089h		;4880   ; los tantos del jugador 1
	ld a,(0e021h)		;4883
	ld b,a			;4886
	ld a,(0e022h)		;4887   ; quien pasa de ronda
	or a			;488a
	jr z,MIRA_SI_PINTA_A_LOS_DOS		;488b   ; nadie: se pintan los dos
	dec a			;488d
	jr nz,MIRA_SI_PINTA_AL_JUGADOR_2		;488e
	bit 1,b		;4890
	jr z,PINTA_LOS_DOS		;4892
	jr PINTA_UNOS_TANTOS		;4894
MIRA_SI_PINTA_AL_JUGADOR_2:
	ld hl,0e08ch		;4896
	dec a			;4899   ; con 0xE022 a 1 pinta la fila del jugador 2
	jr nz,PINTA_LOS_DOS		;489a
	ld de,078c7h		;489c   ; y su casilla
	bit 0,b		;489f   ; mientras el jugador 1 siga en juego
	jr z,PINTA_LOS_DOS		;48a1
	jr PINTA_UNOS_TANTOS		;48a3
MIRA_SI_PINTA_A_LOS_DOS:
	bit 1,b		;48a5   ; el jugador 2 sigue en juego
	jr nz,PINTA_UNOS_TANTOS		;48a7
	ld hl,0e08ch		;48a9   ; su fila del marcador
	ld de,078c7h		;48ac   ; y su casilla
	bit 0,b		;48af   ; y el 1 tambien
	jr nz,PINTA_UNOS_TANTOS		;48b1
PINTA_LOS_DOS:
	ld hl,0e089h		;48b3   ; los tantos del jugador 1
	ld de,078a7h		;48b6   ; en su fila
	ld b,003h		;48b9
	call PINTA_CIFRAS_SEGURAS		;48bb
	ld hl,0e08ch		;48be
	ld de,078c7h		;48c1
PINTA_UNOS_TANTOS:
	ld b,003h		;48c4
	call PINTA_CIFRAS_SEGURAS		;48c6   ; tres bytes en BCD
	ld a,(0e021h)		;48c9
	rrca			;48cc
	jr nc,SUMA_LOS_DEL_JUGADOR_1		;48cd   ; el jugador 1 sigue
	ld a,(0e022h)		;48cf
	dec a			;48d2
	jr z,SUMA_LOS_DEL_JUGADOR_1		;48d3
	cp 002h		;48d5
	jr nz,SUMA_LOS_DEL_JUGADOR_2		;48d7
SUMA_LOS_DEL_JUGADOR_1:
	ld hl,0e089h		;48d9   ; le suma los tantos del intento
	ld de,0e085h		;48dc
	call SUMA_TRES_BYTES_BCD		;48df
SUMA_LOS_DEL_JUGADOR_2:
	ld a,(0e021h)		;48e2
	bit 1,a		;48e5   ; el jugador 2 sigue en juego
	jr z,SUMA_LOS_TANTOS_DEL_2		;48e7
	ld a,(0e022h)		;48e9   ; quien pasa de ronda
	sub 002h		;48ec   ; con 2 se le suman al 2
	jr z,SUMA_LOS_TANTOS_DEL_2		;48ee
	dec a			;48f0   ; y con 3, a los dos
	jr nz,PASA_LOS_TANTOS_A_LA_CUENTA		;48f1
SUMA_LOS_TANTOS_DEL_2:
	ld hl,0e08ch		;48f3   ; los tantos del jugador 2
	ld de,0e088h		;48f6   ; a su cuenta
	call SUMA_TRES_BYTES_BCD		;48f9   ; y al jugador 2 los suyos
PASA_LOS_TANTOS_A_LA_CUENTA:
	ld de,0e082h		;48fc   ; la cuenta del jugador 1
	ld hl,0e085h		;48ff
	ld b,002h		;4902
UNA_CUENTA_DE_TANTOS:
	push bc			;4904
	push de			;4905
	ld b,003h		;4906   ; compara la cuenta de este intento con la del anterior
	call COMPARA_N_BYTES		;4908
	jr nc,SIGUIENTE_JUGADOR		;490b
	inc de			;490d
	inc hl			;490e
	ld bc,00003h		;490f
	ldir		;4912   ; y se queda con la mayor
SIGUIENTE_JUGADOR:
	ld hl,0e088h		;4914
	pop de			;4917
	pop bc			;4918
	djnz UNA_CUENTA_DE_TANTOS		;4919
	ld a,006h		;491b   ; seis puntos de espera
	call ESPERA_PUNTOS		;491d
	xor a			;4920
	ld (0e022h),a		;4921   ; se acabo el reparto
	call BORRA_LA_FILA_DE_LA_MARCA		;4924   ; borra la fila de la marca
	jp PINTA_LOS_TANTOS		;4927   ; y vuelve a pintar los tantos
SUMA_TRES_BYTES_BCD:
	ld a,(hl)			;492a   ; los tres bytes que hay que sumar
	inc hl			;492b
	ld b,(hl)			;492c
	inc hl			;492d
	ld c,(hl)			;492e
	inc hl			;492f
	ex de,hl			;4930
	jp SUMA_BCD_DE_TRES_BYTES		;4931   ; y a la suma en BCD
MONTA_LOS_ACTORES:
	ld hl,04f43h		;4934   ; el guion del marcador de esta prueba
	call CASILLA_DE_LA_PRUEBA		;4937
	call GUION_CORTO		;493a
	ld ix,0e120h		;493d   ; el atleta del jugador que juega
	call PINTA_UN_ACTOR		;4941   ; con sus dos partes
	ld ix,0e130h		;4944   ; el del otro jugador
	call PINTA_UN_ACTOR		;4948
	ld ix,0e140h		;494b   ; el objeto que vuela
	call PINTA_SI_ESTA_ENCENDIDO		;494f
	ld ix,0e150h		;4952   ; y el segundo objeto
	call PINTA_SI_ESTA_ENCENDIDO		;4956
	ret			;4959
SALTA_A_LA_FILA_DE_LA_PRUEBA:
	ld a,(0e016h)		;495a   ; la prueba en curso
SALTA_N_FILAS_DE_TRES:
	dec a			;495d
	ret z			;495e   ; la primera no salta nada
	ld b,a			;495f
SALTA_TRES:
	ld a,003h		;4960   ; tres bytes por fila
	call SUMA_A_A_HL		;4962
	djnz SALTA_TRES		;4965
	ret			;4967
ES_PRUEBA_DE_DISTANCIA:
	ld a,(0e016h)		;4968   ; el bit 1 de la prueba separa 2 y 3 (distancia) de 1 y 4 (tiempo)
	bit 1,a		;496b
	ret			;496d
ES_PRUEBA_IMPAR:
	ld a,(0e016h)		;496e   ; el bit 0 separa 1 y 3 de 2 y 4
	rrca			;4971
	ret			;4972
PINTA_DOS_CARACTERES:
	call PINTA_UNA_CIFRA_SEGURA		;4973   ; uno
	dec de			;4976   ; se echa dos atras
	dec de			;4977
	jp PINTA_UNA_CIFRA_SEGURA		;4978   ; y el otro
FILA_DEL_INTENTO:
	ld hl,0e025h		;497b   ; la del jugador 1
FILA_DEL_INTENTO_DE:
	call A_QUIEN_LE_TOCA		;497e   ; mira a quien le toca
	jp SUMA_A_A_HL		;4981   ; y si es el 2, salta una casilla
FILA_DEL_MARCADOR:
	ld hl,0e062h		;4984   ; la del jugador 1
FILA_DEL_MARCADOR_DE:
	call A_QUIEN_LE_TOCA		;4987
	ret z			;498a   ; el jugador 1 no salta
	ld a,010h		;498b   ; y el 2 salta 0x10
	jp SUMA_A_A_HL		;498d
COPIA_DOS_BYTES:
	ld bc,00002h		;4990
	ldir		;4993
	ret			;4995
BAJA_UNA_FILA:
	ld a,020h		;4996   ; una fila de la tabla de nombres son 0x20 caracteres
BAJA_HL_EN_DE:
	ex de,hl			;4998   ; suma A a DE, no a HL
	call SUMA_A_A_HL		;4999
	ex de,hl			;499c
	ret			;499d
PINTA_LOS_TANTOS:
	ld hl,0e080h		;499e   ; los tantos del record de la partida
	ld de,07826h		;49a1   ; en la fila de arriba del marcador
	ld b,002h		;49a4   ; dos filas: record y jugador 1
	ld a,(0e010h)		;49a6
	or a			;49a9
	jr z,PINTA_UNA_FILA_DE_TANTOS		;49aa
	inc b			;49ac   ; con dos jugadores, tres
PINTA_UNA_FILA_DE_TANTOS:
	push bc			;49ad
	ld b,003h		;49ae   ; tres bytes en BCD
	call PINTA_CIFRAS_SEGURAS		;49b0
	call BAJA_UNA_FILA		;49b3   ; y baja de fila
	pop bc			;49b6
	djnz PINTA_UNA_FILA_DE_TANTOS		;49b7
	ret			;49b9
CASILLA_DE_LA_PRUEBA:
	ld a,(0e016h)		;49ba   ; la prueba, de 1 a 4
	ld b,a			;49bd
SALTA_UNA_PALABRA:
	inc hl			;49be   ; dos bytes por casilla; AVANZA ANTES DE LEER, asi que la direccion que
	inc hl			;49bf   ; le pasan esta dos bytes antes de la casilla de la prueba 1
	djnz SALTA_UNA_PALABRA		;49c0
	ld e,(hl)			;49c2   ; y saca el puntero
	inc hl			;49c3
	ld d,(hl)			;49c4
	ex de,hl			;49c5
	ret			;49c6
PINTA_MARCA_Y_UNIDAD:
	call PINTA_MARCA_SIN_INTERRUPCION		;49c7   ; los tres grupos de cifras
	inc de			;49ca   ; tres caracteres mas alla
	inc de			;49cb
	inc de			;49cc
	ld b,001h		;49cd   ; va la unidad
	jp SUBE_BYTES_SEGURO		;49cf
PINTA_UNA_MARCA:
	call PINTA_UNA_CIFRA		;49d2   ; el primer grupo, dos cifras
	inc de			;49d5
	inc de			;49d6
	push hl			;49d7
	ld hl,050f6h		;49d8   ; el separador de las de distancia
	ld b,002h		;49db
	call ES_PRUEBA_DE_DISTANCIA		;49dd   ; en las de tiempo
	jr nz,PINTA_EL_SEPARADOR		;49e0
	ld hl,05056h		;49e2   ; el separador es otro
PINTA_EL_SEPARADOR:
	call SUBE_BYTES_EN_DE		;49e5
	pop hl			;49e8
	inc de			;49e9   ; y detras, el ultimo grupo
	inc de			;49ea
	jp PINTA_UNA_CIFRA		;49eb
PINTA_MARCA_SIN_INTERRUPCION:
	di			;49ee   ; escribir en VRAM y dejar entrar la interrupcion no se llevan bien
	call PINTA_UNA_MARCA		;49ef
	ei			;49f2
	ret			;49f3
LEE_EL_JOYSTICK:
	ld a,00fh		;49f4   ; registro 15 del PSG: elige que puerto se lee
	call 00093h		;49f6   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,00eh		;49f9   ; y el 14 lo devuelve
	call 00096h		;49fb   ; BIOS RDPSG - Reads value from PSG-register
	cpl			;49fe   ; el PSG devuelve los bits al reves
	ret			;49ff
LEE_LOS_MANDOS_DE_LOS_DOS:
	ld b,002h		;4a00   ; los dos jugadores
	ld hl,0e008h		;4a02
	ld a,(0e004h)		;4a05   ; con 0xE004 puesto se juega con joystick
	or a			;4a08
	jr z,LEE_EL_TECLADO		;4a09
	ld e,08fh		;4a0b   ; puerto A del joystick
LEE_UN_JOYSTICK:
	ld a,00fh		;4a0d
	call LEE_EL_JOYSTICK		;4a0f
	and 018h		;4a12   ; los dos botones
	rrca			;4a14
	rrca			;4a15
	rrca			;4a16
	ld (hl),a			;4a17   ; en los dos bits de abajo
	ld hl,0e00ch		;4a18   ; el hueco del jugador 2
	ld e,0cfh		;4a1b   ; y su puerto
	djnz LEE_UN_JOYSTICK		;4a1d
	jr GUARDA_LOS_MANDOS		;4a1f
LEE_EL_TECLADO:
	ld a,008h		;4a21   ; fila 8 del teclado
LEE_UNA_FILA:
	call 00141h		;4a23   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4a26   ; el bit 7 (derecha) y el 0 (espacio)
	and 081h		;4a27
	rlca			;4a29   ; juntos en los dos de abajo
	ld (hl),a			;4a2a
	ld hl,0e00ch		;4a2b
	ld a,005h		;4a2e   ; y el jugador 2 juega con la fila 5
	djnz LEE_UNA_FILA		;4a30
GUARDA_LOS_MANDOS:
	ld b,002h		;4a32   ; los dos jugadores
	ld hl,0e008h		;4a34
GUARDA_UN_MANDO:
	ld a,(hl)			;4a37   ; lo que habia antes
	inc hl			;4a38
	cp (hl)			;4a39   ; contra lo que hay ahora
	ld c,a			;4a3a
	jr nz,PASA_AL_SIGUIENTE_MANDO		;4a3b   ; si ha cambiado, no hay nada que hacer
	inc hl			;4a3d
	srl (hl)		;4a3e   ; y si no, se va gastando la cuenta de repeticion
	ld (hl),a			;4a40
	inc hl			;4a41
	jr nc,REPITE_EL_MANDO		;4a42
	and 002h		;4a44
REPITE_EL_MANDO:
	ld (hl),a			;4a46
	dec hl			;4a47
	dec hl			;4a48
PASA_AL_SIGUIENTE_MANDO:
	ld (hl),c			;4a49
	ld hl,0e00ch		;4a4a
	djnz GUARDA_UN_MANDO		;4a4d
	ret			;4a4f
LEE_LOS_MANDOS:
	ld b,002h		;4a50   ; los dos puertos de joystick
	ld e,08fh		;4a52   ; el puerto A
LEE_UN_PUERTO:
	call LEE_EL_JOYSTICK		;4a54
	and 03fh		;4a57   ; los seis bits utiles
	ld (0e005h),a		;4a59
	or a			;4a5c
	ret nz			;4a5d   ; con algo pulsado ya vale
	ld e,0cfh		;4a5e   ; y si no, el puerto B
	djnz LEE_UN_PUERTO		;4a60
	ld e,000h		;4a62   ; sin joystick se prueba el teclado
	ld hl,0e005h		;4a64
	ld a,007h		;4a67   ; fila 7: la F5
	call 00141h		;4a69   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4a6c
	bit 6,a		;4a6d
	jr z,LEE_LA_FILA_8_DEL_TECLADO		;4a6f
	set 5,e		;4a71   ; en el bit 5
LEE_LA_FILA_8_DEL_TECLADO:
	ld a,008h		;4a73   ; fila 8: espacio y cursores
	call 00141h		;4a75   ; BIOS SNSMAT - Returns the value of the specified line from the keyboard matrix
	cpl			;4a78
	bit 0,a		;4a79
	jr z,JUNTA_LOS_CURSORES		;4a7b   ; espacio en el bit 4
	set 4,e		;4a7d
JUNTA_LOS_CURSORES:
	and 060h		;4a7f   ; arriba y abajo
	rrca			;4a81   ; bajados a los dos bits de abajo
	rrca			;4a82
	rrca			;4a83
	rrca			;4a84
	rrca			;4a85
	or e			;4a86
	ld (0e005h),a		;4a87
	ret			;4a8a
MUEVE_LA_FLECHA:
	ld hl,0e01ch		;4a8b
	ld a,(0e005h)		;4a8e   ; sin nada pulsado se suelta el antirrebote
	or a			;4a91
	jr nz,MIRA_LA_TECLA		;4a92
	ld (hl),a			;4a94
	ret			;4a95
MIRA_LA_TECLA:
	bit 0,(hl)		;4a96   ; con el antirrebote puesto no se repite
	ret nz			;4a98
	ld a,(0e005h)		;4a99
	and 030h		;4a9c   ; espacio o F5
	or a			;4a9e
	scf			;4a9f   ; acarreo: han elegido
	ret nz			;4aa0
	ld a,(0e005h)		;4aa1
	and 003h		;4aa4   ; arriba o abajo
	set 0,(hl)		;4aa6   ; y baja el antirrebote
	dec a			;4aa8   ; abajo va por el otro lado
	jr nz,FLECHA_ABAJO		;4aa9
	dec hl			;4aab
	ld a,(hl)			;4aac   ; la linea elegida
	dec a			;4aad
	or a			;4aae   ; de la 1 se pasa a la 4
	jr nz,GUARDA_LA_LINEA_DE_ARRIBA		;4aaf
	ld a,004h		;4ab1
GUARDA_LA_LINEA_DE_ARRIBA:
	ld (hl),a			;4ab3
	dec hl			;4ab4
	dec hl			;4ab5
	ld a,(hl)			;4ab6   ; y la fila de VRAM sube 0x40, o sea dos filas
	sub 040h		;4ab7
	ld (hl),a			;4ab9
	jr PINTA_LA_FLECHA		;4aba
FLECHA_ABAJO:
	dec hl			;4abc
	ld a,(hl)			;4abd   ; la linea elegida
	inc a			;4abe
	cp 005h		;4abf   ; de la 4 se pasa a la 1
	jr nz,GUARDA_LA_LINEA_DE_ABAJO		;4ac1
	ld a,001h		;4ac3
GUARDA_LA_LINEA_DE_ABAJO:
	ld (hl),a			;4ac5
	dec hl			;4ac6
	dec hl			;4ac7
	ld a,(hl)			;4ac8   ; y la fila baja dos
	add a,040h		;4ac9
	ld (hl),a			;4acb
PINTA_LA_FLECHA:
	di			;4acc
	ld hl,0e019h		;4acd   ; la fila de VRAM de la linea elegida
	ld e,(hl)			;4ad0
	inc hl			;4ad1
	ld d,(hl)			;4ad2
	ld hl,04ae7h		;4ad3   ; los tres pares de caracteres de la flecha
PINTA_UNA_FILA_DE_LA_FLECHA:
	ld a,(hl)			;4ad6
	cp 0ffh		;4ad7   ; el 0xFF cierra la lista
	ret z			;4ad9
	ld b,002h		;4ada   ; dos caracteres por fila
	di			;4adc
	call SUBE_BYTES_EN_DE		;4add
	ei			;4ae0
	ld a,040h		;4ae1   ; y baja una fila
	add a,e			;4ae3
	ld e,a			;4ae4
	jr PINTA_UNA_FILA_DE_LA_FLECHA		;4ae5

; ----------------------------------------------------------------------
; DATOS marca_del_menu: La flecha que senala la linea elegida del menu: tres
;   filas de dos caracteres y un 0xFF de fin. La pinta 0x4ACC en la direccion
;   de VRAM guardada en 0xE019, bajando 0x40 por fila.
;   0x4ae7..0x4aee  (7 bytes)
DATA_marca_del_menu:
	defb 000h,000h	; 4ae7
	defb 0b6h,0b7h	; 4ae9
	defb 000h,000h	; 4aeb
	defb 0ffh	; 4aed

; ======================================================================
; CODIGO 0x4aee..0x4e73  (901 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  LOS INTERPRETES DE PANTALLA  ==========
; ----------------------------------------------------------------------
PINTA_EL_MARCO_DEL_MENU:
	call LIMPIA_LA_TABLA_DE_NOMBRES		;4aee   ; limpia la tabla de nombres
	ld hl,04e87h		;4af1   ; el guion del menu
	ld b,005h		;4af4   ; y sus cinco grupos: el marco y las cuatro lineas
PINTA_UN_GRUPO_DEL_MENU:
	push bc			;4af6
	call GUION_CORTO		;4af7
	pop bc			;4afa
	djnz PINTA_UN_GRUPO_DEL_MENU		;4afb
	ret			;4afd
GUION_CORTO:
	exx			;4afe   ; el puerto de datos del VDP, en el juego alterno
	ld a,(00006h)		;4aff
	ld c,a			;4b02
	exx			;4b03
	di			;4b04   ; nadie puede interrumpir mientras se escribe en VRAM
	call FIJA_LA_VRAM_DEL_GUION		;4b05   ; los dos primeros bytes son la direccion de VRAM
GUION_CORTO_UN_BYTE:
	inc hl			;4b08
	ld a,(hl)			;4b09
	cp 0feh		;4b0a   ; 0xFE abre una racha
	jr nz,GUION_CORTO_MIRA_EL_FIN		;4b0c
GUION_CORTO_RACHA:
	inc hl			;4b0e
	ld b,(hl)			;4b0f   ; cuantas veces
	inc hl			;4b10
	ld a,(hl)			;4b11   ; y que byte
	call REPITE_BYTE		;4b12
	inc hl			;4b15
	ld a,(hl)			;4b16
	cp 0feh		;4b17   ; detras puede venir otra racha
	jr z,GUION_CORTO_RACHA		;4b19
GUION_CORTO_MIRA_EL_FIN:
	cp 0ffh		;4b1b   ; 0xFF cierra el bloque
	jr z,GUION_CORTO_OTRO_BLOQUE		;4b1d
	exx			;4b1f
	out (c),a		;4b20   ; y cualquier otro byte va tal cual a la VRAM
	exx			;4b22
	jr GUION_CORTO_UN_BYTE		;4b23
GUION_CORTO_OTRO_BLOQUE:
	inc hl			;4b25
	ld a,(hl)			;4b26
	cp 0ffh		;4b27   ; dos 0xFF seguidos cierran el guion
	jr nz,GUION_CORTO		;4b29   ; y si no, viene otro bloque detras
	inc hl			;4b2b
	ei			;4b2c
	ret			;4b2d
PINTA_UNA_CIFRA:
	ld b,001h		;4b2e   ; un solo byte, o sea dos cifras
PINTA_CIFRAS:
	call FIJA_ESCRITURA		;4b30   ; fija la direccion de VRAM
PINTA_UN_BYTE_BCD:
	ld a,(hl)			;4b33
	ld c,a			;4b34
	call CIFRA_DE_ARRIBA		;4b35   ; la cifra de arriba
	ld a,c			;4b38
	call CIFRA_A_CARACTER		;4b39   ; y la de abajo
	inc hl			;4b3c
	djnz PINTA_UN_BYTE_BCD		;4b3d
	ret			;4b3f
CIFRA_DE_ARRIBA:
	rrca			;4b40   ; el nibble alto al bajo
	rrca			;4b41
	rrca			;4b42
	rrca			;4b43
CIFRA_A_CARACTER:
	and 00fh		;4b44   ; se queda con el nibble
	or 0f0h		;4b46   ; y los caracteres de las cifras empiezan en 0xF0
	push bc			;4b48
	push af			;4b49
	ld a,(00006h)		;4b4a   ; el puerto de datos del VDP
	ld c,a			;4b4d
	pop af			;4b4e
	out (c),a		;4b4f
	pop bc			;4b51
	ret			;4b52
PINTA_UNA_CIFRA_SEGURA:
	ld b,001h		;4b53
PINTA_CIFRAS_SEGURAS:
	di			;4b55   ; con la interrupcion cerrada, que va a escribir en VRAM
	call PINTA_CIFRAS		;4b56
	ei			;4b59
	ret			;4b5a
CAMBIA_DE_JUGADOR:
	ld hl,0e011h		;4b5b   ; el jugador al que le toca
	ld b,(hl)			;4b5e
	ld a,(0e010h)		;4b5f   ; con un solo jugador no hay cambio
	or a			;4b62
	ret z			;4b63
	ld (hl),a			;4b64
	ld a,(0e021h)		;4b65   ; el jugador 1 sigue en juego
	rrca			;4b68
	ret c			;4b69   ; entonces le toca a el
	dec (hl)			;4b6a   ; y si no, se prueba con el 2
	rrca			;4b6b
	ret c			;4b6c
	ld a,b			;4b6d
	inc a			;4b6e   ; y si tampoco, se alterna
	and 001h		;4b6f
	ld (hl),a			;4b71
	ret			;4b72
PARPADEO_DEL_RESULTADO:
	call ES_LA_DEMO		;4b73   ; en la demo no hay nada que parpadear
	ret nz			;4b76
	ld a,(0e014h)		;4b77   ; con 0xE014 puesto se ensena el resultado grande
	or a			;4b7a
	jp nz,ENSENA_EL_RESULTADO_GRANDE		;4b7b
	ld hl,0e012h		;4b7e   ; la cuenta atras del parpadeo
	dec (hl)			;4b81
	ret nz			;4b82
	ld (hl),020h		;4b83   ; medio segundo entre cambios
	inc hl			;4b85
	ld c,0bdh		;4b86   ; caracter 0xBD, el del rotulo encendido
	ld a,(hl)			;4b88
	or a			;4b89
	jr z,PARPADEA_EL_ROTULO		;4b8a   ; con la cuenta a cero se apaga
	dec (hl)			;4b8c
	dec (hl)			;4b8d
	ld c,000h		;4b8e   ; y el rotulo se pone en blanco
PARPADEA_EL_ROTULO:
	inc (hl)			;4b90
	ld de,078a5h		;4b91   ; la fila del rotulo
	call ES_PRUEBA_DE_DISTANCIA		;4b94   ; en las de distancia solo hay un rotulo
	jr z,PARPADEA_LOS_DOS_ROTULOS		;4b97
	call A_QUIEN_LE_TOCA		;4b99   ; en las de tiempo, el del jugador que juega
	jr z,PINTA_UN_ROTULO		;4b9c
	ld e,0c5h		;4b9e   ; o el del otro
PINTA_UN_ROTULO:
	ld b,001h		;4ba0
	call REPITE_BYTE_CON_CANDADO		;4ba2
	jp PINTA_LA_MARCA_DEL_ROTULO		;4ba5
PARPADEA_LOS_DOS_ROTULOS:
	push bc			;4ba8
	ld b,000h		;4ba9
	ld a,c			;4bab
	or a			;4bac
	jr z,PINTA_LOS_DOS_ROTULOS		;4bad
	ld bc,0bcbdh		;4baf   ; con la cuenta a cero los dos rotulos en blanco
PINTA_LOS_DOS_ROTULOS:
	ld h,b			;4bb2   ; caracteres 0xBC y 0xBD, uno por jugador
	ld b,001h		;4bb3
	call REPITE_BYTE_CON_CANDADO		;4bb5
	ld de,078c5h		;4bb8   ; la fila del jugador 2
	ld c,h			;4bbb
	ld b,001h		;4bbc
	call REPITE_BYTE_CON_CANDADO		;4bbe
	pop bc			;4bc1
PINTA_LA_MARCA_DEL_ROTULO:
	ld a,c			;4bc2
	or a			;4bc3
	jr z,PINTA_LA_CASILLA_APAGADA		;4bc4
	ld c,0bbh		;4bc6   ; caracter 0xBB, el de la casilla apagada
PINTA_LA_CASILLA_APAGADA:
	ld de,0787dh		;4bc8
	ld b,001h		;4bcb
	call REPITE_BYTE_CON_CANDADO		;4bcd
	ret			;4bd0
ENSENA_EL_RESULTADO_GRANDE:
	ld hl,0e001h		;4bd1   ; la espera, en puntos de 32 cuadros
	ld de,07833h		;4bd4   ; la fila del resultado
	bit 0,(hl)		;4bd7   ; mientras quede espera, se pinta
	jr nz,PINTA_EL_RESULTADO_GRANDE		;4bd9
	ld a,(hl)			;4bdb
	or a			;4bdc
	jr nz,BORRA_EL_RESULTADO_GRANDE		;4bdd   ; con la espera agotada
	ld (0e014h),a		;4bdf   ; se acabo de ensenar
	ret			;4be2
BORRA_EL_RESULTADO_GRANDE:
	ld b,006h		;4be3   ; seis caracteres
	ld c,000h		;4be5
	call REPITE_BYTE_CON_CANDADO		;4be7
	ret			;4bea
PINTA_EL_RESULTADO_GRANDE:
	ld hl,0e041h		;4beb   ; la mejor marca de la prueba
	call SALTA_A_LA_FILA_DE_LA_PRUEBA		;4bee
	jp PINTA_UNA_MARCA		;4bf1
SUMA_BCD_DE_TRES_BYTES:
	ld d,a			;4bf4   ; A lleva el byte alto, B el medio y C el bajo
	ld a,(hl)			;4bf5
	add a,c			;4bf6
	daa			;4bf7   ; en BCD desde el byte de abajo
	ld (hl),a			;4bf8
	dec hl			;4bf9
	ld a,(hl)			;4bfa
	adc a,b			;4bfb
	daa			;4bfc
	ld (hl),a			;4bfd
	dec hl			;4bfe
	ld a,(hl)			;4bff
	adc a,d			;4c00
	daa			;4c01
	ld (hl),a			;4c02
	ret			;4c03
LIMPIA_LA_TABLA_DE_NOMBRES:
	di			;4c04
	ld de,07800h		;4c05   ; el principio de la tabla de nombres
	call FIJA_ESCRITURA		;4c08
	ld h,003h		;4c0b   ; tres tercios
	xor a			;4c0d
LIMPIA_UN_TERCIO:
	ld b,a			;4c0e
	call REPITE_BYTE		;4c0f   ; 256 caracteres a cero
	dec h			;4c12
	jr nz,LIMPIA_UN_TERCIO		;4c13
	ei			;4c15
	ret			;4c16
COPIA_VRAM_A_VRAM:
	ld bc,00fffh		;4c17   ; 0x1000 bytes, un tercio entero
	exx			;4c1a
	ld a,(00006h)		;4c1b   ; el puerto de datos
	ld d,a			;4c1e
	ld a,(00007h)		;4c1f   ; y el de direcciones
	ld e,a			;4c22
	exx			;4c23
COPIA_UN_BYTE_DE_VRAM:
	call FIJA_LECTURA		;4c24   ; fija la direccion de lectura
	inc de			;4c27
	exx			;4c28
	ld c,e			;4c29   ; lee un byte
	in a,(c)		;4c2a
	exx			;4c2c
	ex de,hl			;4c2d
	push af			;4c2e
	call FIJA_ESCRITURA		;4c2f   ; fija la de escritura
	inc de			;4c32
	pop af			;4c33
	exx			;4c34
	ld c,d			;4c35
	out (c),a		;4c36   ; y lo suelta
	exx			;4c38
	ex de,hl			;4c39
	dec bc			;4c3a
	ld a,b			;4c3b
	or c			;4c3c
	jr nz,COPIA_UN_BYTE_DE_VRAM		;4c3d
	ret			;4c3f
ESPERA_PUNTOS:
	ld hl,0e001h		;4c40   ; A puntos de espera; cada punto son 32 cuadros, o sea 0,64 segundos
	ld (hl),a			;4c43   ; la interrupcion los va bajando
ESPERA_A_QUE_LLEGUE_A_CERO:
	ld a,(hl)			;4c44
	or a			;4c45
	jr nz,ESPERA_A_QUE_LLEGUE_A_CERO		;4c46
	ret			;4c48

; ----------------------------------------------------------------------
; ==========  LAS LETRAS GRANDES  ==========
; Un rotulo de letra grande no esta dibujado en la ROM: se monta. Se
; copian los glifos normales a 0xE230, se suben tal cual, y luego se dan
; TRES PASADAS que van sacando los dos bits altos de cada byte y
; metiendolos en el byte de ocho posiciones antes. Con eso una fila de
; ocho glifos da cuatro filas de patron: la letra sale al doble.
; ----------------------------------------------------------------------
MONTA_UN_ROTULO:
	call LLENA_EL_PAPEL		;4c49   ; llena 0xE230 con los glifos del rotulo
	ex de,hl			;4c4c   ; DE quedo en el final del papel
	ld de,00008h		;4c4d
	or a			;4c50
	sbc hl,de		;4c51   ; ocho bytes antes
	ld a,(hl)			;4c53
	ld (hl),011h		;4c54   ; le pone la marca de fin
	push af			;4c56
	ld hl,0e230h		;4c57
	call SUBE_EL_PAPEL		;4c5a   ; y sube a la VRAM lo que queda por delante
	pop af			;4c5d
	ld (hl),a			;4c5e   ; devuelve el byte que habia pisado
	call ESTIRA_LAS_LETRAS		;4c5f   ; y estira las letras
	ret			;4c62
LLENA_EL_PAPEL:
	ld de,0e230h		;4c63   ; el papel donde se monta el rotulo
	ld a,(hl)			;4c66   ; el primer byte dice de que tipo es
	inc hl			;4c67
	or a			;4c68
	jr nz,ROTULO_DE_GLIFOS		;4c69   ; tipo 0: bytes tal cual
	ld c,(hl)			;4c6b   ; cuantos bytes salen
ROTULO_UN_BYTE:
	inc hl			;4c6c
	ld a,(hl)			;4c6d
	cp 011h		;4c6e   ; 0x11 abre una racha
	jr z,ROTULO_RACHA		;4c70
	ld (de),a			;4c72
	inc de			;4c73
	dec c			;4c74
	jr nz,ROTULO_UN_BYTE		;4c75
ROTULO_FIN:
	ld a,011h		;4c77   ; la marca de fin del papel
	ld (de),a			;4c79
	ret			;4c7a
ROTULO_RACHA:
	inc hl			;4c7b
	ld b,(hl)			;4c7c   ; cuantas veces
	inc hl			;4c7d
ROTULO_REPITE:
	ld a,(hl)			;4c7e
	ld (de),a			;4c7f
	inc de			;4c80
	dec c			;4c81   ; la cuenta manda sobre la racha
	jr z,ROTULO_FIN		;4c82
	djnz ROTULO_REPITE		;4c84
	jr ROTULO_UN_BYTE		;4c86
ROTULO_DE_GLIFOS:
	ld b,(hl)			;4c88   ; el indice del glifo
	push hl			;4c89
	ld hl,06002h		;4c8a   ; la fuente
	inc b			;4c8d   ; el glifo 0 no salta nada
	dec b			;4c8e
	jr z,COPIA_EL_GLIFO		;4c8f
SALTA_UN_GLIFO:
	ld a,008h		;4c91   ; ocho bytes por glifo
	add a,l			;4c93
	ld l,a			;4c94
	jr nc,SIGUE_SALTANDO_GLIFOS		;4c95
	inc h			;4c97
SIGUE_SALTANDO_GLIFOS:
	djnz SALTA_UN_GLIFO		;4c98
COPIA_EL_GLIFO:
	ld bc,00008h		;4c9a   ; ocho bytes al papel
	ldir		;4c9d
	pop hl			;4c9f
	inc hl			;4ca0
	ld a,0ffh		;4ca1   ; 0xFF cierra la lista de glifos
	cp (hl)			;4ca3
	jr nz,ROTULO_DE_GLIFOS		;4ca4
	ld a,011h		;4ca6   ; y se cierra el papel
	ld (de),a			;4ca8
	inc hl			;4ca9
	ret			;4caa
ESTIRA_LAS_LETRAS:
	ld b,003h		;4cab   ; tres pasadas
UNA_PASADA:
	push bc			;4cad
	ld hl,0e230h		;4cae   ; desde el principio del papel
UNA_FILA_DE_OCHO:
	ld b,008h		;4cb1   ; ocho bytes por fila
UN_BYTE_DE_LA_FILA:
	push bc			;4cb3
	xor a			;4cb4
	ld c,a			;4cb5   ; aqui se recogen los dos bits
	ld b,002h		;4cb6   ; dos bits por byte y pasada
SACA_DOS_BITS:
	sla (hl)		;4cb8   ; saca el bit alto del byte
	rl c		;4cba   ; y lo mete en C
	djnz SACA_DOS_BITS		;4cbc
	ld de,00008h		;4cbe
	or a			;4cc1
	sbc hl,de		;4cc2   ; ocho posiciones antes
	ld a,(hl)			;4cc4
	or c			;4cc5   ; alli se meten los dos bits
	ld (hl),a			;4cc6
	add hl,de			;4cc7   ; y se vuelve al byte siguiente
	inc hl			;4cc8
	pop bc			;4cc9
	djnz UN_BYTE_DE_LA_FILA		;4cca
	ld a,011h		;4ccc   ; la marca cierra el papel
	cp (hl)			;4cce
	jr nz,UNA_FILA_DE_OCHO		;4ccf
	ld de,00008h		;4cd1   ; otra vez ocho antes
	or a			;4cd4
	sbc hl,de		;4cd5
	ld a,(hl)			;4cd7
	push af			;4cd8
	ld (hl),011h		;4cd9   ; marca de fin provisional
	ld hl,0e230h		;4cdb
	call SUBE_EL_PAPEL		;4cde   ; sube a la VRAM lo que quede por delante
	pop af			;4ce1
	ld (hl),a			;4ce2   ; devuelve el byte pisado
	add hl,de			;4ce3
	ld (hl),011h		;4ce4   ; y corre la marca ocho mas
	pop bc			;4ce6
	djnz UNA_PASADA		;4ce7
	ld hl,0e230h		;4ce9   ; al acabar, el papel se deja limpio
	ld bc,000a0h		;4cec   ; sus 0xA0 bytes
	call LIMPIA_MEMORIA		;4cef
	ret			;4cf2
SUBE_EL_PAPEL:
	ld b,008h		;4cf3   ; de ocho en ocho
SUBE_OCHO:
	ld a,(hl)			;4cf5
	push bc			;4cf6
	push af			;4cf7
	ld a,(00006h)		;4cf8   ; el puerto de datos del VDP
	ld c,a			;4cfb
	pop af			;4cfc
	out (c),a		;4cfd
	pop bc			;4cff
	inc hl			;4d00
	djnz SUBE_OCHO		;4d01
	ld a,011h		;4d03
	cp (hl)			;4d05   ; hasta la marca de fin
	jr nz,SUBE_EL_PAPEL		;4d06
	ret			;4d08

; ----------------------------------------------------------------------
; ==========  EL GUION LARGO  ==========
; [N] y detras N ordenes. La primera de cada una dice de que tipo es:
; 0  bytes a VRAM, con 0x11 cuenta valor para las rachas
; 1  tiras de glifos de la fuente, subidos como patron
; 2  rotulos de letra grande
; 3  rellenos de un byte
; 4+ repetir un patron de ocho bytes N veces
; ----------------------------------------------------------------------
GUION_LARGO:
	ld b,(hl)			;4d09   ; cuantas ordenes
	inc hl			;4d0a
UNA_ORDEN:
	push bc			;4d0b
	ld a,(hl)			;4d0c   ; el tipo
	inc hl			;4d0d   ; y detras van sus datos
	or a			;4d0e
	jr z,ORDEN_DE_BYTES		;4d0f   ; tipo 0
	dec a			;4d11
	jr z,ORDEN_DE_GLIFOS		;4d12   ; tipo 1
	dec a			;4d14
	jr z,ORDEN_DE_ROTULOS		;4d15   ; tipo 2
	dec a			;4d17
	jr z,ORDEN_DE_RELLENOS		;4d18   ; tipo 3
	jp ORDEN_DE_PATRON_REPETIDO		;4d1a   ; y cualquier otro va al tipo 4
SIGUIENTE_ORDEN:
	pop bc			;4d1d
	djnz UNA_ORDEN		;4d1e   ; una orden menos
	ret			;4d20
ORDEN_DE_BYTES:
	ld b,(hl)			;4d21   ; cuantos bloques
	inc hl			;4d22
UN_BLOQUE_DE_BYTES:
	push bc			;4d23
	call FIJA_LA_VRAM_DEL_GUION		;4d24   ; la direccion de VRAM
	inc hl			;4d27
	ld c,(hl)			;4d28   ; y cuantos bytes; cero significa 256
	inc hl			;4d29
UN_BYTE_DEL_BLOQUE:
	ld a,(hl)			;4d2a
	cp 011h		;4d2b   ; 0x11 abre una racha
	jr z,RACHA_DE_BYTES		;4d2d
	ex af,af'			;4d2f
	exx			;4d30
	ld a,(00006h)		;4d31   ; el puerto de datos del VDP
	ld c,a			;4d34
	ex af,af'			;4d35
	out (c),a		;4d36
	exx			;4d38
	inc hl			;4d39
	dec c			;4d3a
	jr nz,UN_BYTE_DEL_BLOQUE		;4d3b
SIGUIENTE_BLOQUE_DE_BYTES:
	pop bc			;4d3d
	djnz UN_BLOQUE_DE_BYTES		;4d3e
	jr SIGUIENTE_ORDEN		;4d40
RACHA_DE_BYTES:
	inc hl			;4d42
	ld b,(hl)			;4d43   ; cuantas veces
	inc hl			;4d44
	ld a,(hl)			;4d45   ; y que byte
	inc hl			;4d46
SUELTA_LA_RACHA:
	ex af,af'			;4d47
	exx			;4d48
	ld a,(00006h)		;4d49   ; el puerto de datos del VDP
	ld c,a			;4d4c
	ex af,af'			;4d4d
	out (c),a		;4d4e
	exx			;4d50
	dec c			;4d51   ; la cuenta del bloque manda sobre la de la racha
	jr z,SIGUIENTE_BLOQUE_DE_BYTES		;4d52
	djnz SUELTA_LA_RACHA		;4d54   ; y mientras la racha aguante
	jr UN_BYTE_DEL_BLOQUE		;4d56
ORDEN_DE_GLIFOS:
	ld b,(hl)			;4d58   ; cuantos bloques
UN_BLOQUE_DE_GLIFOS:
	push bc			;4d59
	inc hl			;4d5a
	call FIJA_LA_VRAM_DEL_GUION		;4d5b   ; la direccion de VRAM
	inc hl			;4d5e
UN_GLIFO:
	ld b,(hl)			;4d5f   ; el indice
	push hl			;4d60
	ld hl,06002h		;4d61   ; la fuente
	ld a,b			;4d64
	or a			;4d65
	jr z,SUELTA_EL_GLIFO		;4d66
SALTA_GLIFOS:
	ld a,008h		;4d68   ; ocho bytes por glifo
	add a,l			;4d6a
	ld l,a			;4d6b
	jr nc,ACABA_DE_SALTAR_GLIFOS		;4d6c
	inc h			;4d6e
ACABA_DE_SALTAR_GLIFOS:
	djnz SALTA_GLIFOS		;4d6f
SUELTA_EL_GLIFO:
	ld b,008h		;4d71   ; sus ocho bytes
	call SUBE_BYTES		;4d73
	pop hl			;4d76
	inc hl			;4d77
	ld a,0ffh		;4d78
	cp (hl)			;4d7a   ; 0xFF cierra la tira
	jr nz,UN_GLIFO		;4d7b
	pop bc			;4d7d
	djnz UN_BLOQUE_DE_GLIFOS		;4d7e
	inc hl			;4d80
VUELVE_A_LA_SIGUIENTE_ORDEN:
	jr SIGUIENTE_ORDEN		;4d81
ORDEN_DE_ROTULOS:
	ld b,(hl)			;4d83   ; cuantos rotulos
	inc hl			;4d84
	call FIJA_LA_VRAM_DEL_GUION		;4d85   ; la direccion de VRAM, que vale para todos
	inc hl			;4d88
UN_ROTULO:
	push bc			;4d89
	ld e,(hl)			;4d8a   ; el puntero al rotulo
	inc hl			;4d8b
	ld d,(hl)			;4d8c
	inc hl			;4d8d
	push hl			;4d8e
	ex de,hl			;4d8f
	call MONTA_UN_ROTULO		;4d90   ; y a montarlo
	pop hl			;4d93
	pop bc			;4d94
	djnz UN_ROTULO		;4d95
	jr SIGUIENTE_ORDEN		;4d97
ORDEN_DE_RELLENOS:
	ld b,(hl)			;4d99   ; cuantos rellenos
	inc hl			;4d9a
	call FIJA_LA_VRAM_DEL_GUION		;4d9b   ; la direccion de VRAM
UN_RELLENO:
	push bc			;4d9e
	inc hl			;4d9f
	ld b,(hl)			;4da0   ; cuantas veces
	inc hl			;4da1
	ld a,(hl)			;4da2   ; y que byte
	call REPITE_BYTE		;4da3
	pop bc			;4da6
	djnz UN_RELLENO		;4da7
	inc hl			;4da9
	jr VUELVE_A_LA_SIGUIENTE_ORDEN		;4daa
ORDEN_DE_PATRON_REPETIDO:
	call FIJA_LA_VRAM_DEL_GUION		;4dac   ; la direccion de VRAM
	inc hl			;4daf
	ld b,(hl)			;4db0   ; cuantas veces
	inc hl			;4db1
	ld e,(hl)			;4db2   ; y de donde sale el patron
	inc hl			;4db3
	ld d,(hl)			;4db4
	push hl			;4db5
	push de			;4db6
	pop hl			;4db7
REPITE_EL_PATRON:
	push bc			;4db8
	push hl			;4db9
	ld b,008h		;4dba   ; ocho bytes cada vez, siempre los mismos
	call SUBE_BYTES		;4dbc
	pop hl			;4dbf
	pop bc			;4dc0
	djnz REPITE_EL_PATRON		;4dc1
	pop hl			;4dc3
	inc hl			;4dc4
	jr VUELVE_A_LA_SIGUIENTE_ORDEN		;4dc5
FIJA_LA_VRAM_DEL_GUION:
	ld d,(hl)			;4dc7   ; los guiones guardan la direccion de VRAM al reves, byte alto primero
	inc hl			;4dc8
	ld e,(hl)			;4dc9
	jp FIJA_ESCRITURA		;4dca
SUBE_CODIGOS_CORRELATIVOS:
	push af			;4dcd
	call FIJA_ESCRITURA		;4dce   ; fija la direccion
	pop af			;4dd1
UN_CODIGO_MAS:
	ex af,af'			;4dd2
	exx			;4dd3
	ld a,(00006h)		;4dd4   ; el puerto de datos
	ld c,a			;4dd7
	ex af,af'			;4dd8
	out (c),a		;4dd9
	exx			;4ddb
	inc a			;4ddc   ; cada caracter es el siguiente del anterior
	djnz UN_CODIGO_MAS		;4ddd
	ex de,hl			;4ddf
	ld de,00020h		;4de0   ; y al acabar baja una fila
	add hl,de			;4de3
	ex de,hl			;4de4
	ret			;4de5
LIMPIA_MEMORIA:
	push hl			;4de6
	pop de			;4de7   ; el clasico relleno con LDIR desplazado un byte
	inc de			;4de8
	ld (hl),000h		;4de9
	ldir		;4deb
	ret			;4ded
BORRA_LA_FILA_DE_LA_MARCA:
	ld de,07b00h		;4dee   ; la fila 0x3B00 de la tabla de nombres
	ld bc,080cfh		;4df1   ; 0x80 caracteres a 0xCF
	jp REPITE_BYTE_SEGURO		;4df4
SUMA_A_A_HL:
	add a,l			;4df7   ; con acarreo al byte alto
	ld l,a			;4df8
	ret nc			;4df9
	inc h			;4dfa
	ret			;4dfb

; ----------------------------------------------------------------------
; ==========  FIJAR DIRECCION DE VRAM SIN QUE LA INTERRUPCION LA PISE
; El VDP lleva la direccion en un registro suyo, y la interrupcion
; tambien escribe. Estas rutinas borran 0xE01D, fijan la direccion y
; comprueban si la interrupcion ha entrado por en medio: si ha entrado,
; vuelven a fijarla. Es el mismo truco en las cuatro variantes.
; ----------------------------------------------------------------------
FIJA_ESCRITURA_CON_CANDADO:
	xor a			;4dfc
	ld (0e01dh),a		;4dfd   ; baja la marca de "ha entrado la interrupcion"
	inc a			;4e00
	ld (0e01eh),a		;4e01   ; y sube el candado
	ex de,hl			;4e04
	call 00053h		;4e05   ; BIOS SETWRT - Enables VDP to write | la BIOS fija la direccion de escritura
	di			;4e08
	ex de,hl			;4e09
	ld a,(0e01dh)		;4e0a   ; si la interrupcion se colo, se repite
	or a			;4e0d
	jr nz,FIJA_ESCRITURA_CON_CANDADO		;4e0e
	ld (0e01eh),a		;4e10   ; y al salir se quita el candado
	ret			;4e13
FIJA_LECTURA:
	xor a			;4e14
	ld (0e01dh),a		;4e15   ; baja la marca
	ex de,hl			;4e18
	call 00050h		;4e19   ; BIOS SETRD - Enables VDP to read | la BIOS fija la direccion de lectura
	di			;4e1c
	ex de,hl			;4e1d
	ld a,(0e01dh)		;4e1e   ; y si se colo la interrupcion, otra vez
	or a			;4e21
	jr nz,FIJA_LECTURA		;4e22
	ret			;4e24
FIJA_ESCRITURA:
	xor a			;4e25
	ld (0e01dh),a		;4e26   ; baja la marca
	ex de,hl			;4e29
	call 00053h		;4e2a   ; BIOS SETWRT - Enables VDP to write | la BIOS fija la direccion de escritura
	di			;4e2d
	ex de,hl			;4e2e
	ld a,(0e01dh)		;4e2f   ; y si se colo la interrupcion, otra vez
	or a			;4e32
	jr nz,FIJA_ESCRITURA		;4e33
	ret			;4e35
SUBE_BYTES_CON_DIRECCION:
	call FIJA_ESCRITURA_CON_CANDADO		;4e36
SUBE_BYTES:
	push bc			;4e39
	ld a,(00006h)		;4e3a   ; el puerto de datos del VDP
	ld c,a			;4e3d
	ld a,(hl)			;4e3e   ; byte a byte desde HL
	out (c),a		;4e3f
	inc hl			;4e41
	pop bc			;4e42
	djnz SUBE_BYTES		;4e43
	ret			;4e45
SUBE_BYTES_EN_DE:
	call FIJA_ESCRITURA		;4e46   ; fija la direccion y suelta B bytes
	jr SUBE_BYTES		;4e49
REPITE_BYTE_CON_CANDADO:
	call FIJA_ESCRITURA_CON_CANDADO		;4e4b
	ld a,c			;4e4e
REPITE_BYTE:
	push bc			;4e4f
	push af			;4e50
	ld a,(00006h)		;4e51   ; el puerto de datos
	ld c,a			;4e54
	pop af			;4e55
	out (c),a		;4e56   ; el mismo byte B veces
	pop bc			;4e58
	djnz REPITE_BYTE		;4e59
	ret			;4e5b
REPITE_BYTE_EN_DE:
	call FIJA_ESCRITURA		;4e5c
	ld a,c			;4e5f
	jr REPITE_BYTE		;4e60
A_QUIEN_LE_TOCA:
	ld a,(0e011h)		;4e62   ; devuelve Z si le toca al jugador 1
	or a			;4e65
	ret			;4e66
SUBE_BYTES_SEGURO:
	di			;4e67   ; escribir en VRAM con la interrupcion abierta sale mal
	call SUBE_BYTES_EN_DE		;4e68
	ei			;4e6b
	ret			;4e6c
REPITE_BYTE_SEGURO:
	di			;4e6d
	call REPITE_BYTE_EN_DE		;4e6e
	ei			;4e71
	ret			;4e72

; ----------------------------------------------------------------------
; DATOS registros_del_vdp: Los ocho registros del VDP tal cual los escribe
;   0x410C. Dan SCREEN 2 con nombres en 0x3800, color en 0x0000, patrones en
;   0x2000, atributos de sprite en 0x3B00 y patrones de sprite en 0x1800
;   (16x16, sin ampliar).
;   0x4e73..0x4e7b  (8 bytes)
DATA_registros_del_vdp:
	defb 002h,0e2h,00eh,07fh,007h,076h,003h,0e1h	; 4e73  .....v..

; ----------------------------------------------------------------------
; DATOS restos_sin_uso: Tres grupos de cuatro bytes con pinta de atributos de
;   sprite (y, x, patron, color). NADIE los lee: ningun puntero de la ROM cae
;   aqui y 0x410C solo sube los ocho registros de arriba.
;   0x4e7b..0x4e87  (12 bytes)
DATA_restos_sin_uso:
	defb 000h,070h,038h,070h	; 4e7b
	defb 000h,0a0h,038h,070h	; 4e7f
	defb 000h,0f0h,038h,0f0h	; 4e83

; ----------------------------------------------------------------------
; DATOS pantalla_del_menu: Guion corto de SEIS bloques, y los cuatro PRIMEROS
;   colocan el LOGOTIPO del juego (filas 3-6, columnas 12-21); PLAY SELECT y
;   los cuatro numeros de la izquierda son los dos de detras, a VRAM 0x390B y
;   0x39AB. Medido ejecutando el guion al comparar las dos compilaciones del
;   cartucho (ver docs/es/COMPARATIVA-TRACK-AND-FIELD.md).
;   0x4e87..0x4ed5  (78 bytes)
DATA_pantalla_del_menu:
	defb 078h,06ch,020h,021h,022h,023h,024h,025h	; 4e87  xl !"#$%
	defb 026h,03fh,040h,0ffh,078h,08ch,030h,031h	; 4e8f  &?@.x.01
	defb 032h,033h,034h,035h,036h,041h,042h,0ffh	; 4e97  23456AB.
	defb 078h,0ach,027h,028h,029h,022h,02ah,02bh	; 4e9f  x.'()"*+
	defb 02ch,02dh,02eh,02fh,0ffh,078h,0cch,037h	; 4ea7  ,-./.x.7
	defb 038h,039h,032h,03ah,03bh,03ch,03dh,03eh	; 4eaf  892:;<=>
	defb 0ffh,079h,00bh,0eah,0ebh,0ech,0edh,0eeh	; 4eb7  .y......
	defb 0efh,000h,0f1h,0f9h,0f8h,0f4h,0ffh,079h	; 4ebf  .......y
	defb 0abh,0cfh,0cbh,0c0h,0d6h,000h,0d1h,0c4h	; 4ec7  ........
	defb 0cbh,0c4h,0c2h,0d2h,0ffh,0ffh	; 4ecf

; ----------------------------------------------------------------------
; DATOS linea_de_menu_1: "1PLAYER with JOYSTICK", en la fila 0x3A07 de la
;   tabla de nombres.
;   0x4ed5..0x4eed  (24 bytes)
DATA_linea_de_menu_1:
	defb 07ah,007h,0a1h,0adh,0aeh,0afh,0b0h,0b1h	; 4ed5  z.......
	defb 0b2h,000h,000h,0b4h,0b5h,000h,0a7h,0a8h	; 4edd  ........
	defb 0b0h,0b3h,0a9h,0aah,0abh,0ach,0ffh,0ffh	; 4ee5  ........

; ----------------------------------------------------------------------
; DATOS linea_de_menu_2: "2PLAYERS with JOYSTICK", en 0x3A47.
;   0x4eed..0x4f05  (24 bytes)
DATA_linea_de_menu_2:
	defb 07ah,047h,0a2h,0adh,0aeh,0afh,0b0h,0b1h	; 4eed  zG......
	defb 0b2h,0b3h,000h,0b4h,0b5h,000h,0a7h,0a8h	; 4ef5  ........
	defb 0b0h,0b3h,0a9h,0aah,0abh,0ach,0ffh,0ffh	; 4efd  ........

; ----------------------------------------------------------------------
; DATOS linea_de_menu_3: "1PLAYER with KEYBOARD", en 0x3A87.
;   0x4f05..0x4f1d  (24 bytes)
DATA_linea_de_menu_3:
	defb 07ah,087h,0a1h,0adh,0aeh,0afh,0b0h,0b1h	; 4f05  z.......
	defb 0b2h,000h,000h,0b4h,0b5h,000h,0ach,0b1h	; 4f0d  ........
	defb 0b0h,0a5h,0a8h,0afh,0b2h,0a6h,0ffh,0ffh	; 4f15  ........

; ----------------------------------------------------------------------
; DATOS linea_de_menu_4: "2PLAYERS with KEYBOARD", en 0x3AC7. El 0xFF 0xFF del
;   final le sirve tambien de casilla cero a la tabla de abajo.
;   0x4f1d..0x4f35  (24 bytes)
DATA_linea_de_menu_4:
	defb 07ah,0c7h,0a2h,0adh,0aeh,0afh,0b0h,0b1h	; 4f1d  z.......
	defb 0b2h,0b3h,000h,0b4h,0b5h,000h,0ach,0b1h	; 4f25  ........
	defb 0b0h,0a5h,0a8h,0afh,0b2h,0a6h,0ffh,0ffh	; 4f2d  ........

; ----------------------------------------------------------------------
; DATOS rotulo_de_la_prueba: Un guion largo por prueba con el nombre que va en
;   la pizarra. Lo carga 0x4265 con 0x49BA, que indexa desde uno: por eso el
;   codigo registra 0x4F33, dos bytes antes de la primera casilla.
;   0x4f35..0x4f3d  (8 bytes)
DATA_rotulo_de_la_prueba:
	defw 06657h	; 4f35  -> DATA_pizarra_de_los_100_metros
	defw 0665eh	; 4f37  -> DATA_pizarra_del_salto_de_longitud
	defw 06665h	; 4f39  -> DATA_pizarra_del_martillo
	defw 06688h	; 4f3b  -> DATA_pizarra_de_los_400_metros

; ----------------------------------------------------------------------
; DATOS pantallas_de_la_prueba: Una lista de guiones largos por prueba, el
;   decorado. La carga 0x4253 desde 0x4F3B. Las pruebas 2 y 3 comparten lista
;   y la 4 usa la misma que la 1.
;   0x4f3d..0x4f45  (8 bytes)
DATA_pantallas_de_la_prueba:
	defw 063c9h	; 4f3d  -> DATA_pantallas_de_los_100_metros
	defw 0648dh	; 4f3f  -> DATA_pantallas_de_longitud_y_martillo
	defw 0648dh	; 4f41  -> DATA_pantallas_de_longitud_y_martillo
	defw 063c9h	; 4f43  -> DATA_pantallas_de_los_100_metros

; ----------------------------------------------------------------------
; DATOS marcador_de_la_prueba: El guion corto del marcador de cada prueba, que
;   carga 0x4934 desde 0x4F43. La prueba 4 repite el de la 1.
;   0x4f45..0x4f4d  (8 bytes)
DATA_marcador_de_la_prueba:
	defw 06443h	; 4f45  -> DATA_marcador_de_los_100_metros
	defw 065bah	; 4f47  -> DATA_marcador_del_salto_de_longitud
	defw 06603h	; 4f49  -> DATA_marcador_del_martillo
	defw 06443h	; 4f4b  -> DATA_marcador_de_los_100_metros

; ======================================================================
; CODIGO 0x4f4d..0x5008  (187 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  LOS PUNTOS DEL INTENTO  ==========
; Los puntos salen de la diferencia entre la marca y una referencia fija
; por prueba (0x5020). En las de tiempo la referencia esta ARRIBA y se le
; resta la marca; en las de distancia esta ABAJO y es la marca la que le
; gana. Despues se multiplica por dieciseis, y en las pruebas impares se
; dobla otra vez.
; ----------------------------------------------------------------------
PUNTUA_EL_INTENTO:
	ld hl,05020h		;4f4d   ; la tabla de referencias
	ld a,(0e016h)		;4f50   ; la prueba en curso
	push af			;4f53
	dec a			;4f54
	call SUMA_A_A_HL		;4f55   ; una referencia por prueba
	ex de,hl			;4f58   ; DE apunta a la referencia
	pop af			;4f59
	bit 1,a		;4f5a
	jp nz,PUNTUA_POR_DISTANCIA		;4f5c   ; pruebas 2 y 3: se puntua por distancia
	push de			;4f5f
	ld hl,0e06bh		;4f60   ; la marca del jugador 1
	call REFERENCIA_MENOS_MARCA		;4f63   ; referencia menos marca, en BCD
	jr c,PUNTUA_AL_JUGADOR_2		;4f66   ; si la marca se pasa, cero puntos
	ld hl,0e08ah		;4f68   ; los puntos del jugador 1
	call GUARDA_Y_ESCALA		;4f6b
	call c,DOBLA_LOS_PUNTOS		;4f6e   ; en las pruebas impares se dobla
PUNTUA_AL_JUGADOR_2:
	pop de			;4f71
	ld hl,0e07bh		;4f72   ; la marca del jugador 2
	call REFERENCIA_MENOS_MARCA		;4f75
	ret c			;4f78
	ld hl,0e08dh		;4f79   ; si se pasa, cero
	call GUARDA_Y_ESCALA		;4f7c
	ret nc			;4f7f
	jp DOBLA_LOS_PUNTOS		;4f80   ; y su doble en las impares
PUNTUA_POR_DISTANCIA:
	ld a,(de)			;4f83   ; la referencia
	ld b,a			;4f84
	ld a,(0e010h)		;4f85   ; con un solo jugador se salta el segundo
	or a			;4f88
	jr z,PUNTUA_POR_DISTANCIA_AL_1		;4f89
	push bc			;4f8b
	ld hl,0e07bh		;4f8c   ; la marca del jugador 2
	call MARCA_MENOS_REFERENCIA		;4f8f   ; marca menos referencia
	jr c,RECUPERA_LA_REFERENCIA		;4f92   ; si no llega, cero puntos
	ld hl,0e08dh		;4f94
	call GUARDA_Y_ESCALA		;4f97
	call nc,MULTIPLICA_POR_DIECISEIS		;4f9a   ; en distancia hay que escalar aparte
	call DOBLA_LOS_PUNTOS		;4f9d
RECUPERA_LA_REFERENCIA:
	pop bc			;4fa0
PUNTUA_POR_DISTANCIA_AL_1:
	ld hl,0e06bh		;4fa1   ; la marca del jugador 1
	call MARCA_MENOS_REFERENCIA		;4fa4
	ret c			;4fa7
	ld hl,0e08ah		;4fa8
	call GUARDA_Y_ESCALA		;4fab
	call nc,MULTIPLICA_POR_DIECISEIS		;4fae
	jp DOBLA_LOS_PUNTOS		;4fb1
MULTIPLICA_POR_DIECISEIS:
	xor a			;4fb4
	ld d,004h		;4fb5   ; cuatro desplazamientos
UN_DESPLAZAMIENTO:
	sla c		;4fb7   ; BC a la izquierda, y lo que se sale va a A
	rl b		;4fb9
	rla			;4fbb
	dec d			;4fbc
	jr nz,UN_DESPLAZAMIENTO		;4fbd
	push hl			;4fbf
	ld (hl),c			;4fc0   ; los tres bytes del resultado
	dec hl			;4fc1
	ld (hl),b			;4fc2
	dec hl			;4fc3
	ld (hl),a			;4fc4
	pop hl			;4fc5
	ret			;4fc6
DOBLA_LOS_PUNTOS:
	ld a,(hl)			;4fc7   ; el byte de abajo
	add a,a			;4fc8
	daa			;4fc9
	ld (hl),a			;4fca
	ld b,002h		;4fcb   ; y los dos de arriba, con acarreo
DOBLA_UN_BYTE:
	dec hl			;4fcd
	ld a,(hl)			;4fce   ; el byte siguiente, con el acarreo del anterior
	adc a,(hl)			;4fcf   ; sumarse a si mismo es doblar
	daa			;4fd0
	ld (hl),a			;4fd1
	djnz DOBLA_UN_BYTE		;4fd2
	ret			;4fd4
REFERENCIA_MENOS_MARCA:
	ld c,(hl)			;4fd5   ; la marca, dos bytes
	dec hl			;4fd6
	ld b,(hl)			;4fd7
	xor a			;4fd8   ; cero menos la marca, en BCD
	sub c			;4fd9
	daa			;4fda
	ld c,a			;4fdb
	ld a,(de)			;4fdc   ; y la referencia por encima
	sbc a,b			;4fdd
	daa			;4fde
	ld b,a			;4fdf
	ret			;4fe0
GUARDA_Y_ESCALA:
	ld (hl),b			;4fe1   ; deja la diferencia donde va
	inc hl			;4fe2
	ld (hl),c			;4fe3
	call ES_PRUEBA_DE_DISTANCIA		;4fe4   ; en las de distancia no se escala aqui
	jr nz,DEVUELVE_SI_ES_IMPAR		;4fe7
	call MULTIPLICA_POR_DIECISEIS		;4fe9   ; y en las de tiempo, por dieciseis
DEVUELVE_SI_ES_IMPAR:
	jp ES_PRUEBA_IMPAR		;4fec
MARCA_MENOS_REFERENCIA:
	call ES_PRUEBA_IMPAR		;4fef   ; en las pares se tira la cifra de abajo
	ld a,(hl)			;4ff2
	jr nc,GUARDA_LA_DIFERENCIA		;4ff3
	and 0f0h		;4ff5
GUARDA_LA_DIFERENCIA:
	ld c,a			;4ff7
	dec hl			;4ff8
	ld a,(hl)			;4ff9   ; y la diferencia contra la referencia
	sub b			;4ffa
	daa			;4ffb
	ld b,a			;4ffc
	ret			;4ffd
COMPARA_TRES_BYTES:
	ld b,002h		;4ffe
COMPARA_N_BYTES:
	or a			;5000   ; acarreo limpio para la primera resta
UNA_RESTA:
	ld a,(de)			;5001   ; (DE) menos (HL) desde el byte de abajo; solo interesa el acarreo
	sbc a,(hl)			;5002
	dec hl			;5003
	dec de			;5004
	djnz UNA_RESTA		;5005
	ret			;5007

; ----------------------------------------------------------------------
; DATOS marcas_de_clasificacion: La marca que hay que batir en cada una de las
;   DOCE rondas, dos bytes en BCD. 0x4625 la lee con 2*(ronda-1). Salen 14.00
;   06.00 80.00 55.00 / 12.00 07.00 85.00 50.00 / 11.00 08.00 95.00 40.00: las
;   cuatro pruebas se repiten tres veces y cada vuelta aprieta.
;   0x5008..0x5020  (24 bytes)
DATA_marcas_de_clasificacion:
	defw 00014h	; 5008
	defw 00006h	; 500a
	defw 00080h	; 500c
	defw 00055h	; 500e
	defw 00012h	; 5010
	defw 00007h	; 5012
	defw 00085h	; 5014
	defw 00050h	; 5016
	defw 00011h	; 5018
	defw 00008h	; 501a
	defw 00095h	; 501c
	defw 00040h	; 501e

; ----------------------------------------------------------------------
; DATOS marca_de_referencia: La marca desde la que se cuentan los puntos, una
;   por prueba (0x4F4D). En las de tiempo se resta de ella (0x15 en los 100 m,
;   0x60 en los 400); en las de distancia se resta ella del resultado (0x03 en
;   longitud, 0x30 en martillo).
;   0x5020..0x5024  (4 bytes)
DATA_marca_de_referencia:
	defb 015h,003h,030h,060h	; 5020

; ----------------------------------------------------------------------
; DATOS marco_del_marcador: El recuadro de arriba con SCORE, WORLD RECORD y
;   QUALIFY. Guion corto de ocho bloques.
;   0x5024..0x50f4  (208 bytes)
DATA_marco_del_marcador:
	defb 078h,000h,0a0h,07bh,083h,086h,086h,09bh	; 5024  x..{....
	defb 09ch,09dh,09eh,09fh,086h,086h,086h,087h	; 502c  ........
	defb 083h,086h,09ah,09dh,09eh,099h,098h,000h	; 5034  ........
	defb 09eh,09fh,09ch,09dh,09eh,098h,086h,087h	; 503c  ........
	defb 07dh,0a0h,0ffh,078h,020h,0a0h,07bh,084h	; 5044  }..x .{.
	defb 0c7h,0c8h,0feh,008h,000h,088h,084h,0feh	; 504c  ........
	defb 006h,000h,0deh,0dfh,0feh,006h,000h,088h	; 5054  ........
	defb 07dh,0a0h,0ffh,078h,040h,0a0h,07bh,084h	; 505c  }..x@.{.
	defb 0f1h,0cfh,0feh,008h,000h,088h,085h,0feh	; 5064  ........
	defb 00eh,086h,089h,07dh,0a0h,0ffh,078h,060h	; 506c  ...}..x`
	defb 0a0h,07bh,084h,0f2h,0cfh,0feh,008h,000h	; 5074  .{......
	defb 088h,000h,0e3h,0e4h,0e5h,0e6h,0e7h,0e8h	; 507c  ........
	defb 0e9h,000h,000h,000h,0deh,0dfh,000h,000h	; 5084  ........
	defb 000h,07dh,0a0h,0ffh,078h,080h,0a0h,07bh	; 508c  .}..x..{
	defb 085h,0feh,00ah,086h,089h,0feh,004h,000h	; 5094  ........
	defb 08ah,08dh,0feh,005h,090h,092h,095h,000h	; 509c  ........
	defb 000h,000h,07dh,0a0h,0ffh,078h,0a0h,0a0h	; 50a4  ..}..x..
	defb 07bh,0f1h,0cfh,000h,000h,000h,0feh,003h	; 50ac  {.......
	defb 0bfh,000h,000h,0feh,006h,000h,08bh,08eh	; 50b4  ........
	defb 0f0h,0f0h,0e2h,0f0h,0f0h,093h,096h,000h	; 50bc  ........
	defb 000h,000h,07dh,0a0h,0ffh,078h,0c0h,0a0h	; 50c4  ..}..x..
	defb 07bh,0f2h,0cfh,000h,000h,000h,0feh,003h	; 50cc  {.......
	defb 0bfh,000h,000h,0feh,006h,000h,08ch,08fh	; 50d4  ........
	defb 0feh,005h,091h,094h,097h,000h,000h,000h	; 50dc  ........
	defb 07dh,0a0h,0ffh,078h,0e0h,0a0h,07ch,07fh	; 50e4  }..x..|.
	defb 0feh,01ah,081h,080h,07eh,0a0h,0ffh,0ffh	; 50ec  ....~...

; ----------------------------------------------------------------------
; DATOS rotulo_de_dos_jugadores: Lo que se anade al marcador cuando juegan
;   dos.
;   0x50f4..0x5111  (29 bytes)
DATA_rotulo_de_dos_jugadores:
	defb 078h,035h,0dch,0ddh,0ffh,078h,079h,0dch	; 50f4  x5...xy.
	defb 0ddh,0ffh,078h,090h,0feh,00dh,000h,0ffh	; 50fc  ..x.....
	defb 078h,0a5h,0feh,018h,000h,0ffh,078h,0c5h	; 5104  x.....x.
	defb 0feh,018h,000h,0ffh,0ffh	; 510c

; ----------------------------------------------------------------------
; DATOS rotulo_de_intentos: La columna de TRY del marcador de las pruebas de
;   distancia.
;   0x5111..0x5133  (34 bytes)
DATA_rotulo_de_intentos:
	defb 078h,090h,0f1h,000h,0d2h,0d0h,0d6h,0feh	; 5111  x.......
	defb 008h,000h,0ffh,078h,0b0h,0f2h,000h,0d2h	; 5119  ...x....
	defb 0d0h,0d6h,0feh,008h,000h,0ffh,078h,0d0h	; 5121  ......x.
	defb 0f3h,000h,0d2h,0d0h,0d6h,0feh,008h,000h	; 5129  ........
	defb 0ffh,0ffh	; 5131

; ----------------------------------------------------------------------
; DATOS rotulo_de_fallo: Seis codigos de caracter que 0x433A y 0x44D0 escriben
;   cuando un intento no vale.
;   0x5133..0x5139  (6 bytes)
DATA_rotulo_de_fallo:
	defb 000h,0c5h,0ceh,0d3h,0cbh,000h	; 5133

; ----------------------------------------------------------------------
; DATOS rotulo_de_unidad: Cuatro codigos de caracter que 0x4444 pone al lado
;   del resultado.
;   0x5139..0x513d  (4 bytes)
DATA_rotulo_de_unidad:
	defb 0dch,0ddh,0deh,0dfh	; 5139

; ----------------------------------------------------------------------
; DATOS rotulo_de_turno: Tres codigos de caracter que 0x4280 pone en 0x38A2 o
;   en 0x38C2 segun a quien le toque.
;   0x513d..0x5140  (3 bytes)
DATA_rotulo_de_turno:
	defb 0c2h,0cfh,0d3h	; 513d

; ----------------------------------------------------------------------
; DATOS pantalla_de_fin_de_ronda: Guion corto de un bloque que 0x46AC saca al
;   acabar la vuelta.
;   0x5140..0x5154  (20 bytes)
DATA_pantalla_de_fin_de_ronda:
	defb 079h,089h,000h,0f1h,0e4h,000h,000h,0eah	; 5140  y.......
	defb 0e6h,0ebh,0e8h,000h,0ech,0edh,0e8h,0e9h	; 5148  ........
	defb 000h,000h,0ffh,0ffh	; 5150

; ----------------------------------------------------------------------
; DATOS colores_de_los_sprites: Un color por cada uno de los 32 sprites; los
;   sube 0x434A a la tabla de atributos con la Y a 0xD1, o sea escondidos.
;   0x5154..0x5174  (32 bytes)
DATA_colores_de_los_sprites:
	defb 006h,006h,006h,006h,00bh,006h,00fh,00bh	; 5154  ........
	defb 001h,00bh,001h,006h,001h,007h,006h,00fh	; 515c  ........
	defb 006h,00fh,001h,001h,001h,001h,001h,001h	; 5164  ........
	defb 001h,001h,004h,009h,00bh,00fh,001h,001h	; 516c  ........

; ----------------------------------------------------------------------
; DATOS records_del_mundo: Los cuatro records del mundo, tres bytes en BCD por
;   prueba, copiados a 0xE040 por 0x40B8: 09.95 en los 100 m, 8.90 en
;   longitud, 83.98 en martillo y 43.86 en los 400 m. Son marcas reales, pero
;   ANTERIORES a la temporada de 1983: cuando el cartucho salio, los 9.95 y
;   los 83.98 ya estaban batidos. Ver docs/es/HALLAZGOS.md.
;   0x5174..0x5180  (12 bytes)
DATA_records_del_mundo:
	defb 000h,009h,095h	; 5174
	defb 000h,008h,090h	; 5177
	defb 000h,083h,098h	; 517a
	defb 000h,043h,086h	; 517d

; ======================================================================
; CODIGO 0x5180..0x53a0  (544 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  MOTOR DE LOS 100 Y LOS 400 METROS  ==========
; Lo llama la interrupcion una vez por cuadro. Los dos atletas NO se
; mueven en el mismo cuadro: en los pares se mueve el del jugador 1 y en
; los impares el del 2, que es como el cartucho se ahorra la mitad del
; trabajo por cuadro.
; ----------------------------------------------------------------------
MOTOR_DE_LA_CARRERA:
	ld hl,0e02eh		;5180
	bit 2,(hl)		;5183   ; bit 2: se acabo el tiempo
	jr nz,MUEVE_A_UNO_DE_LOS_DOS		;5185
	bit 6,(hl)		;5187   ; bit 6: hay carrera en marcha
	jr z,APUNTA_LAS_PULSACIONES		;5189
	call REPARTE_EL_ESFUERZO		;518b   ; reparte el esfuerzo de las pulsaciones
	call SUMA_LA_VELOCIDAD_A_LA_MARCA		;518e   ; lo convierte en avance
	call REPARTE_EL_AVANCE		;5191   ; y reparte el avance entre los dos
APUNTA_LAS_PULSACIONES:
	ld a,(0e00bh)		;5194   ; el boton del jugador 1
	rrca			;5197
	jr nc,APUNTA_LA_DEL_JUGADOR_2		;5198
	ld a,001h		;519a
	ld (0e0cch),a		;519c   ; queda apuntado en 0xE0CC
APUNTA_LA_DEL_JUGADOR_2:
	ld a,(0e00fh)		;519f   ; el boton del jugador 2
	rrca			;51a2
	jr nc,CUENTA_EL_RELOJ		;51a3
	ld a,001h		;51a5
	ld (0e0cdh),a		;51a7   ; y en 0xE0CD
CUENTA_EL_RELOJ:
	call EL_RELOJ_DE_LA_PRUEBA		;51aa   ; el reloj de la prueba
MUEVE_A_UNO_DE_LOS_DOS:
	ld a,(0e000h)		;51ad   ; el contador de cuadros
	rrca			;51b0
	jr c,MUEVE_AL_JUGADOR_2		;51b1   ; en los impares le toca al jugador 2
	call MUEVE_AL_ATLETA_1		;51b3   ; mueve al atleta del jugador 1
	xor a			;51b6
	ld (0e0cch),a		;51b7
	ld a,(0e028h)		;51ba   ; bit 2 de 0xE028: ya ha llegado
	bit 2,a		;51bd
	jr nz,PINTA_AL_JUGADOR_1		;51bf
	ld hl,0e150h		;51c1   ; la ficha del segundo objeto
	call MUEVE_Y_PINTA_UN_ACTOR		;51c4
	ld a,001h		;51c7
	call MUEVE_EL_DECORADO		;51c9   ; y su sprite
PINTA_AL_JUGADOR_1:
	ld hl,0e130h		;51cc   ; y la ficha del atleta del jugador 1
	jp MUEVE_Y_PINTA_UN_ACTOR		;51cf
MUEVE_AL_JUGADOR_2:
	call MUEVE_AL_ATLETA_2		;51d2   ; mueve al atleta del jugador 2
	xor a			;51d5
	ld (0e0cdh),a		;51d6
	ld a,(0e029h)		;51d9   ; bit 2 de 0xE029: ya ha llegado
	bit 2,a		;51dc
	jr nz,PINTA_AL_JUGADOR_2		;51de
	ld hl,0e140h		;51e0   ; la ficha del primer objeto
	call MUEVE_Y_PINTA_UN_ACTOR		;51e3
	xor a			;51e6
	call MUEVE_EL_DECORADO		;51e7
PINTA_AL_JUGADOR_2:
	ld hl,0e120h		;51ea
	jp MUEVE_Y_PINTA_UN_ACTOR		;51ed
REPARTE_EL_ESFUERZO:
	ld hl,0e021h		;51f0
	bit 1,(hl)		;51f3   ; el jugador 2 sigue en juego
	jr nz,GASTA_LA_DEL_JUGADOR_1		;51f5
	bit 0,(hl)		;51f7   ; o el 1
	jr nz,REPARTE_EL_ESFUERZO_DEL_2		;51f9
GASTA_LA_DEL_JUGADOR_1:
	push hl			;51fb
	ld a,(0e028h)		;51fc   ; bit 2 de 0xE028: el jugador 1 ya ha llegado
	bit 2,a		;51ff
	jr nz,LE_TOCA_AL_JUGADOR_2		;5201
	ld hl,0e0adh		;5203   ; su velocidad
	ld a,(0e00bh)		;5206   ; la pulsacion apuntada
	ld (0e0c5h),a		;5209
	call GASTA_Y_APUNTA		;520c   ; gasta un poco de velocidad
LE_TOCA_AL_JUGADOR_2:
	pop hl			;520f
	bit 1,(hl)		;5210
	jr z,REPARTE_EL_ESFUERZO_DEL_2		;5212
	ld hl,0e0e4h		;5214   ; y le toca al 2
	ld de,0e0ebh		;5217
	ld a,(0e029h)		;521a
	jp GASTA_LA_VELOCIDAD		;521d
REPARTE_EL_ESFUERZO_DEL_2:
	push hl			;5220
	ld a,(0e029h)		;5221
	bit 2,a		;5224   ; bit 2 de 0xE029
	jr nz,LE_TOCA_AL_JUGADOR_1		;5226
	ld hl,0e0e3h		;5228   ; la velocidad del jugador 2
	ld a,(0e00fh)		;522b   ; su pulsacion
	ld (0e0c5h),a		;522e
	call GASTA_Y_APUNTA		;5231
LE_TOCA_AL_JUGADOR_1:
	pop hl			;5234
	bit 0,(hl)		;5235
	ret z			;5237
	ld hl,0e0aeh		;5238   ; y luego el 1
	ld de,0e0b5h		;523b
	ld a,(0e028h)		;523e
	jp GASTA_LA_VELOCIDAD		;5241
GASTA_LA_VELOCIDAD:
	bit 2,a		;5244   ; si ese atleta ya ha llegado no se le toca
	ret nz			;5246
	ld a,(hl)			;5247   ; su velocidad
	cp 005h		;5248
	jr nc,GASTA_A_TODA_VELOCIDAD		;524a   ; por debajo de 5 el rozamiento es otro
	dec hl			;524c
	ld a,001h		;524d
	ld (0e0c5h),a		;524f   ; hay marca nueva que pintar
	ld a,(0e02eh)		;5252
	set 5,a		;5255   ; bit 5 de 0xE02E: no se apunte un tramo
	ld (0e02eh),a		;5257
	call GASTA_Y_APUNTA		;525a   ; gasta lo que toque
	ld a,(hl)			;525d   ; y baja la velocidad 0x20 en BCD
	sub 020h		;525e
	daa			;5260
	ld (hl),a			;5261
	inc hl			;5262
	ld b,000h		;5263
	ld a,(hl)			;5265
	sbc a,b			;5266   ; con acarreo al byte de arriba
	daa			;5267
	ld (hl),a			;5268
	inc hl			;5269
	ld a,(hl)			;526a
	sub 014h		;526b   ; y la distancia recorrida baja 0x14
	ld (hl),a			;526d
	inc hl			;526e
	jr nc,SIN_VELOCIDAD_QUE_GASTAR		;526f
	dec (hl)			;5271
SIN_VELOCIDAD_QUE_GASTAR:
	ret			;5272
GASTA_A_TODA_VELOCIDAD:
	dec hl			;5273
	ex de,hl			;5274
	ld a,(0e021h)		;5275   ; mira a quien le toca
	rrca			;5278
	ld a,(0e0ebh)		;5279   ; la posicion del otro atleta
	jr c,COMPARA_LAS_DOS_POSICIONES		;527c
	ld a,(0e0b5h)		;527e
COMPARA_LAS_DOS_POSICIONES:
	ld c,a			;5281
	cp (hl)			;5282   ; comparada con la de este
	ex de,hl			;5283
	ld b,002h		;5284   ; se gastan dos por cuadro
	jr c,FRENA_UN_POCO		;5286   ; si va por detras, no se le frena mas
	ld a,(0e02eh)		;5288
	bit 7,a		;528b   ; bit 7 de 0xE02E: el que va delante ya frena poco
	jr nz,APUNTA_EL_REFRESCO		;528d
	ld a,(de)			;528f   ; su velocidad
	ld b,001h		;5290
	cp 018h		;5292   ; por debajo de 0x18 solo se gasta uno
	jr nc,FRENA_UN_POCO		;5294
	push hl			;5296
	ld hl,0e02eh		;5297
	set 7,(hl)		;529a
	pop hl			;529c
	jr APUNTA_EL_REFRESCO		;529d
FRENA_UN_POCO:
	push hl			;529f
	ld hl,0e02eh		;52a0   ; baja el bit de "va suelto"
	res 7,(hl)		;52a3
	pop hl			;52a5
	ld a,(hl)			;52a6   ; baja la velocidad en BCD
	sub b			;52a7
	daa			;52a8
	ld (hl),a			;52a9
	inc hl			;52aa
	push bc			;52ab   ; el byte de arriba
	ld c,000h		;52ac
	ld a,(hl)			;52ae
	sbc a,c			;52af
	daa			;52b0
	ld (hl),a			;52b1
	pop bc			;52b2
	inc hl			;52b3
	ld a,(hl)			;52b4   ; y la distancia
	sub b			;52b5
	ld (hl),a			;52b6
	inc hl			;52b7   ; con acarreo
	jr nc,MIRA_EL_SUELO_DE_VELOCIDAD		;52b8
	dec (hl)			;52ba
MIRA_EL_SUELO_DE_VELOCIDAD:
	dec hl			;52bb
	dec hl			;52bc
	ld a,(hl)			;52bd   ; por debajo de 5 la velocidad se planta
	cp 005h		;52be
	jr nc,MIRA_SI_HAY_QUE_REFRESCAR		;52c0
	dec hl			;52c2
	ld (hl),000h		;52c3   ; en 0x05F4 de velocidad y 0x01 de distancia
	inc hl			;52c5
	ld (hl),005h		;52c6
	inc hl			;52c8
	ld (hl),0f4h		;52c9
	inc hl			;52cb
	ld (hl),001h		;52cc
	dec hl			;52ce
	dec hl			;52cf
MIRA_SI_HAY_QUE_REFRESCAR:
	dec hl			;52d0
	ld a,c			;52d1
	cp 011h		;52d2   ; con el otro por debajo de 0x11
	jr c,LIMPIA_EL_TRAMO		;52d4
	ex de,hl			;52d6
	ld hl,0e02eh		;52d7
	bit 3,(hl)		;52da   ; bit 3 de 0xE02E
	jr z,LIMPIA_EL_TRAMO		;52dc
	ex de,hl			;52de
APUNTA_EL_REFRESCO:
	ld a,001h		;52df
	ld (0e0c5h),a		;52e1   ; hay marca nueva
	ld a,(0e02eh)		;52e4
	set 5,a		;52e7   ; bit 5 de 0xE02E
	ld (0e02eh),a		;52e9
	call GASTA_Y_APUNTA		;52ec
LIMPIA_EL_TRAMO:
	ld hl,0e02eh		;52ef
	res 3,(hl)		;52f2
	ret			;52f4
GASTA_Y_APUNTA:
	push de			;52f5
	push hl			;52f6
	ld b,002h		;52f7   ; dos por cuadro
	call ES_PRUEBA_IMPAR		;52f9   ; en las pruebas pares el gasto depende de lo que quede
	jr nz,GASTA_LA_VELOCIDAD_BCD		;52fc
	ld hl,(0e0b2h)		;52fe   ; la marca del jugador 2
	ld a,(0e000h)		;5301   ; en los cuadros pares
	rrca			;5304
	jr nc,RESTA_LO_QUE_FALTA		;5305
	ld hl,(0e0e8h)		;5307   ; la del jugador 1
RESTA_LO_QUE_FALTA:
	ld de,0fe2ch		;530a   ; lo que falta para 0x1D4
	add hl,de			;530d
	jr c,GASTA_DOS_POR_CUADRO		;530e
	ld b,001h		;5310   ; cerca de la meta solo se gasta uno
GASTA_DOS_POR_CUADRO:
	pop hl			;5312
	push hl			;5313
GASTA_LA_VELOCIDAD_BCD:
	ld a,(hl)			;5314
	or a			;5315
	jr nz,RESTA_LA_VELOCIDAD		;5316   ; con la velocidad ya a cero no hay nada que gastar
	inc hl			;5318
	ld a,(hl)			;5319
	or a			;531a
	dec hl			;531b
	jr z,GASTA_LA_DISTANCIA		;531c
RESTA_LA_VELOCIDAD:
	ld a,(hl)			;531e
	sub b			;531f   ; en BCD
	daa			;5320
	ld (hl),a			;5321
	jr nc,GASTA_LA_DISTANCIA		;5322
	inc hl			;5324
	ld a,(hl)			;5325
	sub 001h		;5326   ; con acarreo al byte de arriba
	daa			;5328
	ld (hl),a			;5329
	jr nc,GASTA_LA_DISTANCIA		;532a
	xor a			;532c   ; y sin bajar de cero
	ld (hl),a			;532d
	dec hl			;532e
	ld (hl),a			;532f
GASTA_LA_DISTANCIA:
	pop hl			;5330
	push hl			;5331
	inc hl			;5332
	inc hl			;5333
	ld a,(hl)			;5334   ; la distancia, dos bytes en binario
	or a			;5335
	jr nz,RESTA_LA_DISTANCIA		;5336
	inc hl			;5338
	ld a,(hl)			;5339   ; el byte de arriba
	or a			;533a
	dec hl			;533b
	jr z,MIRA_EL_TRAMO		;533c
RESTA_LA_DISTANCIA:
	ld a,(hl)			;533e   ; le resta la velocidad
	sub b			;533f
	ld (hl),a			;5340
	jr nc,MIRA_EL_TRAMO		;5341
	inc hl			;5343   ; con acarreo al byte de arriba
	ld a,(hl)			;5344
	sub 001h		;5345
	ld (hl),a			;5347
	jr nc,MIRA_EL_TRAMO		;5348
	xor a			;534a   ; y sin bajar de cero
	ld (hl),a			;534b
	dec hl			;534c
	ld (hl),a			;534d
MIRA_EL_TRAMO:
	pop hl			;534e
	ld a,(0e0c5h)		;534f   ; la marca de refresco
	rrca			;5352
	jr nc,SIN_TRAMO		;5353   ; sin ella no hay tramo que apuntar
	xor a			;5355
	ld (0e0c5h),a		;5356
	push hl			;5359
	ld hl,0e02eh		;535a
	bit 5,(hl)		;535d   ; bit 5: el tramo no cuenta
	jr nz,APUNTA_UN_TRAMO		;535f
	set 3,(hl)		;5361   ; y si no, se apunta
APUNTA_UN_TRAMO:
	res 5,(hl)		;5363
	pop hl			;5365
	push hl			;5366
	ld a,(0e016h)		;5367   ; la prueba
	ld de,053a0h		;536a   ; la tabla de avance de las de tiempo
	bit 1,a		;536d
	jr z,SUMA_EL_TRAMO		;536f
	ld de,053c0h		;5371   ; o la de las de distancia
SUMA_EL_TRAMO:
	inc hl			;5374
	ld b,000h		;5375   ; el nivel de esfuerzo
	ld a,(hl)			;5377
	cp 010h		;5378
	jr c,BUSCA_EN_LA_TABLA_DE_AVANCE		;537a   ; por encima de 0x10 se recorta seis
	sub 006h		;537c
BUSCA_EN_LA_TABLA_DE_AVANCE:
	ld c,a			;537e
	ex de,hl			;537f
	add hl,bc			;5380   ; la casilla del nivel
	ld a,(hl)			;5381
	ex de,hl			;5382
	dec hl			;5383
	add a,(hl)			;5384   ; se suma a la marca en BCD
	daa			;5385
	ld (hl),a			;5386
	inc hl			;5387
	ld a,000h		;5388
	adc a,(hl)			;538a
	daa			;538b
	ld (hl),a			;538c
	push hl			;538d
	ex de,hl			;538e
	ld de,00010h		;538f   ; la segunda tira de la misma tabla
	add hl,de			;5392
	ld a,(hl)			;5393
	pop hl			;5394
	inc hl			;5395
	add a,(hl)			;5396   ; y se suma al reloj, este en binario
	ld (hl),a			;5397
	inc hl			;5398
	ld a,000h		;5399
	adc a,(hl)			;539b
	ld (hl),a			;539c
	pop hl			;539d
SIN_TRAMO:
	pop de			;539e
	ret			;539f

; ----------------------------------------------------------------------
; DATOS avance_de_las_pruebas_de_tiempo: Dos tiras de dieciseis: cuanto suma
;   la marca y cuanto el reloj en cada nivel de esfuerzo. Las usa 0x5366 en
;   los 100 y los 400 metros.
;   0x53a0..0x53c0  (32 bytes)
DATA_avance_de_las_pruebas_de_tiempo:
	defb 094h,081h,078h,065h,047h,040h,032h,024h,018h,012h,010h,008h,007h,006h,005h,000h	; 53a0  ..xeG@2$........
	defb 05eh,051h,04eh,041h,02fh,028h,020h,018h,012h,00ch,00ah,008h,007h,006h,005h,000h	; 53b0  ^QNA/( .........

; ----------------------------------------------------------------------
; DATOS avance_de_las_pruebas_de_distancia: Las mismas dos tiras para longitud
;   y martillo (0x5371).
;   0x53c0..0x53e0  (32 bytes)
DATA_avance_de_las_pruebas_de_distancia:
	defb 099h,095h,090h,085h,080h,075h,070h,060h,050h,040h,030h,020h,015h,012h,006h,000h	; 53c0  .....up`P@0 ....
	defb 063h,05fh,05ah,055h,050h,04bh,046h,03ch,032h,028h,01eh,014h,00fh,00ch,006h,000h	; 53d0  c_ZUPKF<2(......

; ======================================================================
; CODIGO 0x53e0..0x5769  (905 bytes)
; ======================================================================


SUMA_LA_VELOCIDAD_A_LA_MARCA:
	ld a,(0e0edh)		;53e0
	rrca			;53e3   ; bit 0 de 0xE0ED: el jugador 2 ya no corre
	ld hl,0e0e5h		;53e4   ; su velocidad
	ld de,0e0eeh		;53e7   ; y su marca
	call nc,MULTIPLICA_LA_VELOCIDAD		;53ea
	ld a,(0e0b7h)		;53ed   ; bit 0 de 0xE0B7: el jugador 1 ya no corre
	rrca			;53f0
	ret c			;53f1
	ld hl,0e0afh		;53f2   ; su velocidad
	ld de,0e0b8h		;53f5
MULTIPLICA_LA_VELOCIDAD:
	push de			;53f8
	call ES_PRUEBA_DE_DISTANCIA		;53f9   ; en las pruebas de distancia
	ld b,019h		;53fc   ; se suma 0x19 veces
	jr nz,SUMA_REPETIDA		;53fe
	ld b,03ah		;5400   ; y en las de tiempo 0x3A
SUMA_REPETIDA:
	ld c,000h		;5402
	ld e,(hl)			;5404   ; la velocidad, dos bytes en BCD
	ld d,(hl)			;5405
	inc hl			;5406
	ld a,(hl)			;5407
	ld h,(hl)			;5408
	ld l,a			;5409
UNA_SUMA:
	ld a,e			;540a   ; byte de abajo
	add a,d			;540b
	daa			;540c
	ld e,a			;540d
	ld a,l			;540e   ; byte de arriba
	adc a,h			;540f
	daa			;5410
	ld h,a			;5411
	ld a,c			;5412   ; y el acarreo se guarda aparte
	adc a,000h		;5413
	ld c,a			;5415
	djnz UNA_SUMA		;5416
	ld a,h			;5418
	pop hl			;5419   ; la casilla de destino
	add a,(hl)			;541a   ; se le suma lo acumulado
	daa			;541b
	ld (hl),a			;541c
	inc hl			;541d
	ld a,c			;541e
	adc a,(hl)			;541f
	daa			;5420
	ld (hl),a			;5421
	ret			;5422
REPARTE_EL_AVANCE:
	ld hl,0e028h		;5423
	bit 2,(hl)		;5426   ; bit 2 de 0xE028: el jugador 1 ya ha llegado
	jr z,MIRA_AL_JUGADOR_2		;5428
	ld hl,0e0b5h		;542a   ; entonces solo avanza el 2
	call AVANZA_EL_ATLETA		;542d
	ld hl,0e029h		;5430
	bit 2,(hl)		;5433   ; bit 2 de 0xE029: y el 2 tambien
	jr nz,SOLO_AVANZA_UNO		;5435
	ld hl,0e141h		;5437   ; la columna del objeto del jugador 2
	ld a,(0e0efh)		;543a   ; se le suma su avance
	add a,(hl)			;543d
	ld (hl),a			;543e
	jr FIN_DEL_REPARTO		;543f
MIRA_AL_JUGADOR_2:
	inc hl			;5441
	bit 2,(hl)		;5442   ; bit 2 de 0xE029: el 2 ha llegado
	jr z,AVANZAN_LOS_DOS		;5444
	ld hl,0e151h		;5446   ; la columna del objeto del jugador 1
	ld a,(0e0b9h)		;5449
	add a,(hl)			;544c
	ld (hl),a			;544d
SOLO_AVANZA_UNO:
	ld hl,0e0ebh		;544e
	call AVANZA_EL_ATLETA		;5451
FIN_DEL_REPARTO:
	jp LIMPIA_LOS_AVANCES		;5454
AVANZAN_LOS_DOS:
	ld hl,(0e0b2h)		;5457   ; la posicion del jugador 1
	ld a,(0e0b9h)		;545a   ; mas su avance
	call SUMA_A_A_HL		;545d
	ex de,hl			;5460
	ld hl,(0e0e8h)		;5461   ; la del jugador 2
	ld a,(0e0efh)		;5464   ; mas el suyo
	call SUMA_A_A_HL		;5467
	push hl			;546a
	ld hl,0e0ebh		;546b
	ld a,(0e0b5h)		;546e   ; quien va delante
	cp (hl)			;5471
	pop hl			;5472
	jr nc,COMPARA_LAS_POSICIONES		;5473
	ex de,hl			;5475
COMPARA_LAS_POSICIONES:
	or a			;5476
	sbc hl,de		;5477   ; si van igualados
	jr nz,UNO_SE_QUEDA_ATRAS		;5479
	ld hl,0e0b9h		;547b   ; los dos avanzan lo suyo y no hay arrastre
	ld a,(hl)			;547e
	ld (hl),000h		;547f
	ld hl,0e151h		;5481
	add a,(hl)			;5484
	ld (hl),a			;5485
	ld hl,0e0efh		;5486
	ld a,(hl)			;5489
	ld (hl),000h		;548a
	ld hl,0e141h		;548c
	add a,(hl)			;548f
	ld (hl),a			;5490
	ret			;5491
UNO_SE_QUEDA_ATRAS:
	jp c,EL_JUGADOR_2_VA_DELANTE		;5492   ; si el de detras es el que manda, por el otro lado
	exx			;5495
	ld hl,(0e0e8h)		;5496   ; las dos posiciones en el juego alterno
	ld de,(0e0b2h)		;5499
	exx			;549d
	ld de,0e0efh		;549e   ; el avance del jugador 2
	ld a,(de)			;54a1
	ld (0e0c7h),a		;54a2
	ld bc,0e0b9h		;54a5   ; y el del 1
	ld a,(bc)			;54a8
	ld (0e0c8h),a		;54a9
	ld hl,0e0ebh		;54ac
	ld a,(0e0b5h)		;54af
	cp (hl)			;54b2   ; el que va delante manda la camara
	jr c,MIRA_SI_CABEN_LOS_DOS		;54b3
	ld de,0e0b9h		;54b5
	ld a,(de)			;54b8
	ld (0e0c7h),a		;54b9
	ld bc,0e0efh		;54bc
	ld a,(bc)			;54bf
	ld (0e0c8h),a		;54c0
	ld a,(0e0ebh)		;54c3
	exx			;54c6
	ex de,hl			;54c7
	exx			;54c8
MIRA_SI_CABEN_LOS_DOS:
	ld h,a			;54c9   ; la distancia entre los dos
	ld a,(bc)			;54ca
	add a,h			;54cb
	ld h,a			;54cc
	ld a,(de)			;54cd
	add a,050h		;54ce   ; con 0x50 de margen
	cp h			;54d0
	jr z,SE_SALE_DE_LA_PANTALLA		;54d1   ; si caben en pantalla, se mueven los dos
	jr c,SE_SALE_DE_LA_PANTALLA		;54d3
ARRASTRA_AL_DE_ATRAS:
	ld a,(de)			;54d5
	push af			;54d6
	exx			;54d7
	xor a			;54d8
	sbc hl,de		;54d9   ; la diferencia
	ld a,l			;54db
	exx			;54dc
	bit 7,a		;54dd
	jr z,CALCULA_EL_ARRASTRE		;54df   ; en valor absoluto
	cpl			;54e1
CALCULA_EL_ARRASTRE:
	ld l,a			;54e2
	ld a,(bc)			;54e3
	sub l			;54e4   ; lo que se puede mover el de detras
	ld h,a			;54e5
	ld a,(de)			;54e6
	ld l,a			;54e7
	ld a,h			;54e8
	sub l			;54e9
	ld b,a			;54ea
	exx			;54eb
	ld hl,0e141h		;54ec   ; las columnas de los dos objetos
	ld de,0e151h		;54ef
	exx			;54f2
	ld hl,0e0ebh		;54f3
	ld de,0e0b5h		;54f6
	ld a,(de)			;54f9   ; y quien va delante
	cp (hl)			;54fa
	jr c,REPARTE_LO_QUE_CABE		;54fb
	exx			;54fd
	ld hl,0e151h		;54fe
	ld de,0e141h		;5501
	exx			;5504
	ex de,hl			;5505
REPARTE_LO_QUE_CABE:
	ld a,(de)			;5506
	add a,b			;5507   ; al de detras se le da lo que cabe
	ld (de),a			;5508
	ld a,(0e0c8h)		;5509   ; y el resto se lo lleva el decorado
	sub b			;550c
	ld b,a			;550d
	exx			;550e
	ld a,(hl)			;550f
	exx			;5510
	add a,b			;5511
	exx			;5512
	ld (hl),a			;5513
	exx			;5514
	pop af			;5515
	exx			;5516
	ex de,hl			;5517
	add a,(hl)			;5518
	ld (hl),a			;5519
	jp LIMPIA_LOS_AVANCES		;551a
SE_SALE_DE_LA_PANTALLA:
	ld hl,0e0ebh		;551d
	ld de,0e0b5h		;5520
	ld a,(de)			;5523   ; quien va delante
	cp (hl)			;5524
	jr z,EMPATE_A_POSICION		;5525   ; empatados: desempata la velocidad
	jr c,CLAVA_LA_SEPARACION		;5527
DESEMPATA:
	ex de,hl			;5529
CLAVA_LA_SEPARACION:
	ld a,(de)			;552a
	ld h,a			;552b
	ld a,050h		;552c   ; 0x50 es lo que caben los dos en pantalla
	sub h			;552e
	ld h,a			;552f
	ld a,(0e0c8h)		;5530   ; lo que sobra se lo come el decorado
	sub h			;5533
	ld b,a			;5534
	ld hl,0e141h		;5535   ; la columna del primer objeto
	add a,(hl)			;5538
	ld (hl),a			;5539
	ld hl,0e151h		;553a   ; y la del segundo
	ld a,b			;553d
	add a,(hl)			;553e
	ld (hl),a			;553f
	ld a,(0e0c7h)		;5540
	ld c,a			;5543
	ld a,b			;5544
	sub c			;5545
	ld b,a			;5546
	ld hl,0e0ebh		;5547
	ld de,0e0b5h		;554a
	ld a,(de)			;554d
	cp (hl)			;554e
	jr c,QUITA_LO_ARRASTRADO		;554f
	ex de,hl			;5551
QUITA_LO_ARRASTRADO:
	ld a,(hl)			;5552
	sub b			;5553
	ld (hl),a			;5554
	ld a,050h		;5555   ; el de delante se clava en 0x50
	ld (de),a			;5557
	jr LIMPIA_LOS_AVANCES		;5558
EMPATE_A_POSICION:
	ld a,(0e0efh)		;555a   ; el avance del jugador 2
	ld b,a			;555d
	ld a,(0e0b9h)		;555e   ; contra el del 1
	cp b			;5561
	jr nc,DESEMPATA		;5562
	jr CLAVA_LA_SEPARACION		;5564
EL_JUGADOR_2_VA_DELANTE:
	ld hl,0e0ebh		;5566
	ld a,(0e0b5h)		;5569   ; quien va delante de verdad
	cp (hl)			;556c
	jr c,EL_JUGADOR_1_VA_DELANTE		;556d
	ld a,(0e0b9h)		;556f   ; el avance del jugador 2
	ld hl,0e151h		;5572   ; al decorado
	add a,(hl)			;5575
	ld (hl),a			;5576
	ld a,(0e0ebh)		;5577
	cp 009h		;557a   ; con el otro por debajo de 9
	jr nc,AJUSTA_LA_SEPARACION		;557c
	ld a,(0e0efh)		;557e   ; su avance tambien al decorado
	ld hl,0e141h		;5581
	add a,(hl)			;5584
	ld (hl),a			;5585
	jr LIMPIA_LOS_AVANCES		;5586
AJUSTA_LA_SEPARACION:
	ld hl,0e0b9h		;5588
	ld a,(0e0ebh)		;558b   ; la separacion actual
	sub (hl)			;558e
	ld b,a			;558f
	ld a,(0e0efh)		;5590   ; mas el avance del otro
	add a,b			;5593
	cp 008h		;5594   ; por debajo de 8 se recorta
	jr nc,SEPARACION_QUE_CABE		;5596
	ld b,a			;5598
	ld a,008h		;5599
	sub b			;559b
	ld b,a			;559c
	ld a,(0e0b9h)		;559d
	sub b			;55a0
	ld hl,0e141h		;55a1
	add a,(hl)			;55a4
	ld (hl),a			;55a5
	ld a,008h		;55a6
	ld (0e0ebh),a		;55a8   ; y la separacion se clava en 8
LIMPIA_LOS_AVANCES:
	xor a			;55ab   ; los dos avances gastados
	ld (0e0b9h),a		;55ac
	ld (0e0efh),a		;55af
	ret			;55b2
SEPARACION_QUE_CABE:
	ld hl,0e141h		;55b3
	ld a,(0e0b9h)		;55b6   ; el avance del jugador 1
	ld b,a			;55b9
	add a,(hl)			;55ba   ; al decorado
	ld (hl),a			;55bb
	ld a,(0e0ebh)		;55bc   ; la separacion
	sub b			;55bf
	ld b,a			;55c0
	ld a,(0e0efh)		;55c1   ; mas el avance del jugador 2
	add a,b			;55c4
	ld (0e0ebh),a		;55c5
	jr LIMPIA_LOS_AVANCES		;55c8
EL_JUGADOR_1_VA_DELANTE:
	ld a,(0e0efh)		;55ca   ; el avance del jugador 2
	ld hl,0e141h		;55cd   ; al decorado
	add a,(hl)			;55d0
	ld (hl),a			;55d1
	ld a,(0e0b5h)		;55d2   ; con la separacion por debajo de 9
	cp 009h		;55d5
	jr nc,AJUSTA_LA_SEPARACION_2		;55d7
	ld a,(0e0b9h)		;55d9   ; el avance del jugador 1
	ld hl,0e151h		;55dc   ; va al segundo decorado
	add a,(hl)			;55df
	ld (hl),a			;55e0
	jr LIMPIA_LOS_AVANCES		;55e1
AJUSTA_LA_SEPARACION_2:
	ld hl,0e0efh		;55e3
	ld a,(0e0b5h)		;55e6   ; la separacion menos el avance del 2
	sub (hl)			;55e9
	ld b,a			;55ea
	ld a,(0e0b9h)		;55eb   ; mas el avance del 1
	add a,b			;55ee
	cp 008h		;55ef   ; por encima de 8 cabe entera
	jr nc,SEPARACION_QUE_CABE_2		;55f1
	ld b,a			;55f3
	ld a,008h		;55f4   ; lo que le falta para 8
	sub b			;55f6
	ld b,a			;55f7
	ld a,(0e0efh)		;55f8   ; se le quita al avance del 2
	sub b			;55fb
	ld hl,0e151h		;55fc
	add a,(hl)			;55ff
	ld (hl),a			;5600
	ld a,008h		;5601   ; y la separacion se clava en 8
	ld (0e0b5h),a		;5603
	jr LIMPIA_LOS_AVANCES		;5606
SEPARACION_QUE_CABE_2:
	ld hl,0e151h		;5608
	ld a,(0e0efh)		;560b   ; el avance del jugador 2
	ld b,a			;560e
	add a,(hl)			;560f   ; al segundo decorado
	ld (hl),a			;5610
	ld a,(0e0b5h)		;5611   ; la separacion
	sub b			;5614
	ld b,a			;5615
	ld a,(0e0b9h)		;5616   ; mas el avance del 1
	add a,b			;5619
	ld (0e0b5h),a		;561a
	jr LIMPIA_LOS_AVANCES		;561d
AVANZA_EL_ATLETA:
	push hl			;561f
	push bc			;5620
	push hl			;5621
	ld bc,00004h		;5622   ; cuatro bytes mas alla esta su avance
	add hl,bc			;5625
	ld a,(hl)			;5626   ; se le suma a la columna
	pop hl			;5627
	add a,(hl)			;5628
	ld (hl),a			;5629
	cp 051h		;562a   ; hasta 0x51 se mueve libre
	jr c,SIN_LLEGADA		;562c
	inc hl			;562e
	inc hl			;562f
	set 6,(hl)		;5630   ; bit 6: ya esta en el tramo final
	dec hl			;5632
	dec hl			;5633
	cp 0d8h		;5634   ; y a partir de 0xD8 se planta
	jr c,SIN_LLEGADA		;5636
	ld (hl),0d8h		;5638
	inc hl			;563a
	inc hl			;563b
	bit 0,(hl)		;563c   ; bit 0: ya ha llegado
	jr nz,SIN_LLEGADA		;563e
	set 0,(hl)		;5640
	dec hl			;5642
	ld (hl),00fh		;5643   ; la postura de llegada
	ld a,0b6h		;5645   ; 0xE0B6 es el jugador 1
	cp l			;5647
	ld a,001h		;5648
	jr z,PINTA_LA_LLEGADA		;564a
	xor a			;564c
PINTA_LA_LLEGADA:
	call PINTA_AL_ATLETA		;564d   ; y a pintarlo
SIN_LLEGADA:
	pop bc			;5650
	pop hl			;5651
	ret			;5652
EL_RELOJ_DE_LA_PRUEBA:
	ld hl,0e0b7h		;5653
	bit 6,(hl)		;5656   ; bit 6 de 0xE0B7: el jugador 1 ya ha llegado
	jr nz,EL_RELOJ_DEL_JUGADOR_2		;5658
	ld hl,0e0abh		;565a   ; su reloj
	call SUMA_AL_RELOJ		;565d
EL_RELOJ_DEL_JUGADOR_2:
	ld hl,0e0edh		;5660
	bit 6,(hl)		;5663   ; bit 6 de 0xE0ED
	jr nz,MIRA_EL_RELOJ_DEL_JUGADOR_1		;5665
	ld hl,0e0a7h		;5667   ; el reloj del jugador 2
	call SUMA_AL_RELOJ		;566a
	ld hl,0e0b7h		;566d
	bit 6,(hl)		;5670   ; si el 1 ya paro
	jr z,SUMA_AL_RELOJ_COMUN		;5672
	ld a,(0e021h)		;5674   ; y sigue en juego
	rrca			;5677
	jr nc,PASA_EL_CUADRO		;5678
SUMA_AL_RELOJ_COMUN:
	ld hl,0e0a3h		;567a   ; el reloj comun
	call SUMA_AL_RELOJ		;567d
	jr PASA_EL_CUADRO		;5680
MIRA_EL_RELOJ_DEL_JUGADOR_1:
	ld a,(0e021h)		;5682
	bit 1,a		;5685   ; el jugador 2 sigue en juego
	jr z,PASA_EL_CUADRO		;5687
	ld a,(0e0b7h)		;5689   ; bit 6 de 0xE0B7
	bit 6,a		;568c
	jr z,SUMA_AL_RELOJ_COMUN		;568e
PASA_EL_CUADRO:
	ld hl,0e0ach		;5690
	inc (hl)			;5693   ; el contador del reloj
	ret			;5694
SUMA_AL_RELOJ:
	ld a,(0e0ach)		;5695   ; el contador de cuadros del reloj
	rrca			;5698
	ld a,067h		;5699   ; un cuadro suma 0x0167 y el siguiente 0x0166
	jr c,SUMA_LAS_CENTESIMAS		;569b
	ld a,066h		;569d   ; o sea 1,67 y 1,66 centesimas de segundo, media 1,665: UN SESENTAVO DE
SUMA_LAS_CENTESIMAS:
	add a,(hl)			;569f   ; SEGUNDO. El reloj esta calculado para una maquina de 60 Hz
	daa			;56a0
	ld (hl),a			;56a1   ; suma en BCD, centesimas
	dec hl			;56a2
	ld a,001h		;56a3
	adc a,(hl)			;56a5
	daa			;56a6
	ld (hl),a			;56a7
	dec hl			;56a8
	ld a,000h		;56a9
	adc a,(hl)			;56ab
	daa			;56ac
	ld (hl),a			;56ad
	jr nc,MIRA_EL_LIMITE_DEL_RELOJ		;56ae
MIRA_EL_LIMITE_DEL_RELOJ:
	ld a,(0e016h)		;56b0   ; en los 100 metros
	cp 001h		;56b3
	jr nz,LIMITE_DE_SESENTA_SEGUNDOS		;56b5
	ld a,(hl)			;56b7
	cp 040h		;56b8   ; el limite son 40 segundos
	ret nz			;56ba
	jr SE_ACABO_EL_TIEMPO		;56bb
LIMITE_DE_SESENTA_SEGUNDOS:
	ld a,(hl)			;56bd
	cp 060h		;56be   ; y en las demas, 60
	ret nz			;56c0
SE_ACABO_EL_TIEMPO:
	inc hl			;56c1
	ld (hl),000h		;56c2   ; el reloj se planta
	ld hl,0e02eh		;56c4
	set 2,(hl)		;56c7   ; bit 2 de 0xE02E: se acabo el tiempo
	ret			;56c9

; ----------------------------------------------------------------------
; ==========  EL ATLETA DEL JUGADOR 1  ==========
; ----------------------------------------------------------------------
MUEVE_AL_ATLETA_1:
	ld hl,0e0cah		;56ca
	bit 0,(hl)		;56cd   ; bit 0 de 0xE0CA: ya esta puesto en su sitio
	jr nz,MIRA_EL_ESTADO_DEL_ATLETA_1		;56cf
	set 0,(hl)		;56d1   ; se marca para no repetirlo
	ld hl,05096h		;56d3   ; la ficha de sprite del jugador 1
	ld (0e0b4h),hl		;56d6
	ld a,010h		;56d9   ; postura 0x10, la de espera
	ld (0e0b6h),a		;56db
	call PINTA_AL_ATLETA_1		;56de   ; y se pinta
	ld hl,05769h		;56e1   ; el estado inicial del atleta
	ld de,0e0bch		;56e4   ; a su hueco de trabajo
	ld bc,00007h		;56e7
	ldir		;56ea
	ld a,096h		;56ec   ; caracter 0x96 en la casilla del suelo
	ld (0e0c4h),a		;56ee
	ld (0e0fah),a		;56f1
	ld hl,05769h		;56f4   ; el mismo estado inicial
	ld de,0e0f2h		;56f7   ; al del segundo atleta
	ld bc,00007h		;56fa
	ldir		;56fd
BORRA_LOS_HUECOS_DE_CIFRA:
	ld de,05a50h		;56ff   ; los cuatro sitios de la VRAM donde van las cifras
	ld hl,06002h		;5702   ; el glifo del cero
	ld b,008h		;5705   ; sus ocho bytes
	call SUBE_BYTES_CON_DIRECCION		;5707
	ld de,05a90h		;570a   ; segundo hueco
	ld hl,06002h		;570d
	ld b,008h		;5710
	call SUBE_BYTES_CON_DIRECCION		;5712
	ld de,05ad0h		;5715   ; tercero
	ld hl,06002h		;5718
	ld b,008h		;571b
	call SUBE_BYTES_CON_DIRECCION		;571d
	ld de,05b10h		;5720   ; y cuarto
	ld hl,06002h		;5723
	ld b,008h		;5726
	jp SUBE_BYTES_CON_DIRECCION		;5728
MIRA_EL_ESTADO_DEL_ATLETA_1:
	ld hl,0e02dh		;572b
	bit 4,(hl)		;572e   ; bit 4 de 0xE02D: el jugador 2 ya no cuenta
	ret nz			;5730
	ld hl,0e02eh		;5731
	bit 2,(hl)		;5734   ; bit 2 de 0xE02E: se acabo el tiempo
	jp nz,ATLETA_1_FUERA_DE_TIEMPO		;5736
	ld a,(0e028h)		;5739   ; bit 3 de 0xE028: el atleta esta parando
	bit 3,a		;573c
	jp nz,ATLETA_1_PARANDO		;573e
	bit 1,a		;5741   ; bit 1: aun no ha arrancado
	jp z,SALIDA_DEL_ATLETA_1		;5743
	ld a,(0e0b7h)		;5746   ; bit 0 de 0xE0B7: ya ha llegado
	rrca			;5749
	ld a,(0e02ah)		;574a   ; el resultado del intento
	ld hl,0e0bbh		;574d
	jp c,MIRA_SI_HAN_LLEGADO_LOS_DOS		;5750   ; entonces toca la animacion de llegada
	ld hl,0e0aeh		;5753   ; y si no, la de correr
	ld de,0e0b1h		;5756
	jp CORRE_EL_ATLETA		;5759
ATLETA_1_FUERA_DE_TIEMPO:
	ld a,(0e02ah)		;575c
	or a			;575f   ; sin resultado no hay nada que ensenar
	jp z,SE_ACABO_LA_CARRERA		;5760
	ld hl,0e0bbh		;5763
	jp ANIMA_LA_LLEGADA		;5766

; ----------------------------------------------------------------------
; DATOS estado_inicial_del_atleta: Siete bytes que 0x56CA copia a 0xE0BC y a
;   0xE0F2 para dejar al atleta en su sitio al empezar.
;   0x5769..0x5770  (7 bytes)
DATA_estado_inicial_del_atleta:
	defb 0cfh,000h,010h,000h,0cfh,000h,020h	; 5769

; ======================================================================
; CODIGO 0x5770..0x5c96  (1318 bytes)
; ======================================================================


MUEVE_AL_ATLETA_2:
	ld hl,0e0cbh		;5770
	bit 0,(hl)		;5773   ; bit 0 de 0xE0CB: ya esta puesto
	jr nz,MIRA_EL_ESTADO_DEL_ATLETA_2		;5775
	set 0,(hl)		;5777
	ld hl,05066h		;5779   ; la ficha de sprite del jugador 2
	ld (0e0eah),hl		;577c
	ld a,010h		;577f   ; postura 0x10
	ld (0e0ech),a		;5781
	jp PINTA_AL_ATLETA_2		;5784
MIRA_EL_ESTADO_DEL_ATLETA_2:
	ld hl,0e02ch		;5787
	bit 4,(hl)		;578a   ; bit 4 de 0xE02C
	ret nz			;578c
	ld hl,0e02eh		;578d
	bit 2,(hl)		;5790   ; bit 2 de 0xE02E
	jr nz,ATLETA_2_FUERA_DE_TIEMPO		;5792
	ld a,(0e029h)		;5794   ; bit 3 de 0xE029
	bit 3,a		;5797
	jp nz,ATLETA_2_PARANDO		;5799
	bit 1,a		;579c   ; bit 1
	jp z,SALIDA_DEL_ATLETA_2		;579e
	ld a,(0e0edh)		;57a1   ; bit 0 de 0xE0ED
	rrca			;57a4
	ld a,(0e02bh)		;57a5
	ld hl,0e0f1h		;57a8
	jp c,MIRA_SI_HAN_LLEGADO_LOS_DOS		;57ab
	ld hl,0e0e4h		;57ae
	ld de,0e0e7h		;57b1
	jp CORRE_EL_ATLETA		;57b4
ATLETA_2_FUERA_DE_TIEMPO:
	ld a,(0e02bh)		;57b7
	or a			;57ba
	jp z,SE_ACABO_LA_CARRERA		;57bb
	ld hl,0e0f1h		;57be
	jp ANIMA_LA_LLEGADA		;57c1
SALIDA_DEL_ATLETA_1:
	ld a,(0e0a1h)		;57c4   ; el contador de la salida
	cp 005h		;57c7   ; hasta 5 no pasa nada
	jr nc,ATLETA_1_EN_LA_SALIDA		;57c9
	cp 003h		;57cb   ; y por debajo de 3, tampoco
	ret c			;57cd
	ld de,07981h		;57ce   ; la casilla del juez de salida
	ld bc,001efh		;57d1   ; caracter 0xEF: el pistoletazo
	call REPITE_BYTE_CON_CANDADO		;57d4
	ld a,006h		;57d7   ; postura 6
	ld (0e0b6h),a		;57d9
	jp PINTA_AL_ATLETA_1		;57dc
ATLETA_1_EN_LA_SALIDA:
	ld hl,0e02ch		;57df
	bit 4,(hl)		;57e2   ; bit 4 de 0xE02C: ya salio
	jr nz,ATLETA_1_YA_SALIO		;57e4
	cp 008h		;57e6   ; con 8 arranca la carrera
	jr nc,SALIDA_NULA		;57e8
	ld a,007h		;57ea   ; postura 7
	ld (0e0b6h),a		;57ec
	ld de,07982h		;57ef   ; la casilla del juez
	ld bc,001efh		;57f2   ; caracter 0xEF
	call REPITE_BYTE_CON_CANDADO		;57f5
	call PINTA_AL_ATLETA_1		;57f8
	ld a,(0e021h)		;57fb   ; el jugador 1 no juega esta prueba
	rrca			;57fe
	ret c			;57ff
	ld a,(0e00bh)		;5800   ; y hasta que no pulse, nada
	rrca			;5803
	ret nc			;5804
	ld a,020h		;5805   ; 0x20 cuadros de aguante
	ld (0e0bbh),a		;5807
	ld a,008h		;580a   ; postura 8: la de arrancar
	ld (0e0b6h),a		;580c
	call PINTA_AL_ATLETA_1		;580f
	ld hl,0e02eh		;5812
	res 6,(hl)		;5815   ; bit 6 de 0xE02E
	ld hl,0e02ch		;5817   ; bit 4 de 0xE02C: ya ha salido
	set 4,(hl)		;581a
	inc hl			;581c
	bit 4,(hl)		;581d   ; si el otro tambien ha salido
	ret nz			;581f
	ld a,04ch		;5820   ; sonido 0x4C: el disparo
	jp PIDE_UN_SONIDO		;5822
ATLETA_1_YA_SALIO:
	ld a,(0e0bbh)		;5825   ; el aguante que le queda
	or a			;5828
	jr z,SIN_AGUANTE		;5829
	dec a			;582b
	ld (0e0bbh),a		;582c   ; se le va gastando
	cp 00ah		;582f   ; al llegar a 10
	ret nz			;5831
	ld a,010h		;5832   ; postura 0x10, la de espera
	ld (0e0b6h),a		;5834
	jp PINTA_AL_ATLETA_1		;5837
SIN_AGUANTE:
	set 0,(hl)		;583a   ; bit 0 de 0xE02D
	ret			;583c
SALIDA_NULA:
	ld hl,0e028h		;583d
	bit 3,(hl)		;5840   ; bit 3 de 0xE028
	jr nz,ATLETA_1_PARANDO		;5842
	set 3,(hl)		;5844   ; se marca
	inc hl			;5846
	set 3,(hl)		;5847   ; y en 0xE029 tambien
	set 7,(hl)		;5849   ; bit 7: A PARTIR DE AQUI EL BOTON LO PULSA LA MAQUINA, al azar, desde
	ld hl,0e0a0h		;584b   ; la interrupcion (0x4030). Es lo que mueve al rival CPU
	xor a			;584e   ; limpia el estado del atleta
	ld b,00ch		;584f
LIMPIA_UN_BYTE:
	ld (hl),a			;5851
	inc hl			;5852
	djnz LIMPIA_UN_BYTE		;5853
	ld de,07983h		;5855   ; la casilla del juez
	ld bc,001efh		;5858   ; caracter 0xEF
	call REPITE_BYTE_CON_CANDADO		;585b
	ld a,04ah		;585e   ; sonido 0x4A
	call PIDE_UN_SONIDO		;5860
	ld a,043h		;5863   ; y 0x43 detras
	jp PIDE_UN_SONIDO		;5865
ATLETA_1_PARANDO:
	ld a,(0e0b6h)		;5868   ; su postura
	cp 008h		;586b
	jr z,ATLETA_1_SE_PARA		;586d   ; con la 8 ya esta parado
	ld a,(0e021h)		;586f
	rrca			;5872   ; en las pruebas impares
	jr c,PONE_LA_POSTURA_DE_ARRANQUE		;5873
	ld a,(0e0cch)		;5875   ; la pulsacion apuntada
	rrca			;5878
	jr nc,PINTA_AL_ATLETA_1		;5879
PONE_LA_POSTURA_DE_ARRANQUE:
	ld a,008h		;587b   ; postura 8
	ld (0e0b6h),a		;587d
	call PINTA_AL_ATLETA_1		;5880
	ld a,002h		;5883   ; dos cuadros
	ld (0e0bbh),a		;5885
	ret			;5888
ATLETA_1_SE_PARA:
	ld hl,0e0bbh		;5889
	dec (hl)			;588c   ; la cuenta
	jr nz,PINTA_AL_ATLETA_1		;588d
	ld hl,0e028h		;588f
	set 1,(hl)		;5892   ; bit 1 de 0xE028: ya corre
	res 3,(hl)		;5894   ; y se quita la de parando
	ld hl,0e02eh		;5896
	set 6,(hl)		;5899   ; bit 6 de 0xE02E: la carrera esta en marcha
	ld a,004h		;589b   ; velocidad inicial 4
	ld (0e0b9h),a		;589d
	ld a,009h		;58a0   ; postura 9, la primera de correr
	ld (0e0b6h),a		;58a2
PINTA_AL_ATLETA_1:
	ld a,001h		;58a5   ; el 1 es el jugador 1
	jp PINTA_AL_ATLETA		;58a7
SALIDA_DEL_ATLETA_2:
	ld a,(0e0a1h)		;58aa   ; el contador de la salida
	cp 005h		;58ad
	jr nc,ATLETA_2_EN_LA_SALIDA		;58af
	cp 003h		;58b1
	ret c			;58b3
	ld a,006h		;58b4   ; postura 6
	ld (0e0ech),a		;58b6
	jp PINTA_AL_ATLETA_2		;58b9
ATLETA_2_EN_LA_SALIDA:
	ld hl,0e02dh		;58bc
	bit 4,(hl)		;58bf   ; bit 4 de 0xE02D
	jr nz,ATLETA_2_YA_SALIO		;58c1
	cp 008h		;58c3
	jr nc,SALIDA_NULA_2		;58c5
	ld a,007h		;58c7   ; postura 7
	ld (0e0ech),a		;58c9
	call PINTA_AL_ATLETA_2		;58cc
	ld a,(0e021h)		;58cf   ; el jugador 2 no juega esta prueba
	bit 1,a		;58d2
	ret nz			;58d4
	ld a,(0e0cdh)		;58d5   ; su pulsacion
	rrca			;58d8
	ret nc			;58d9
	ld a,020h		;58da   ; 0x20 cuadros de aguante
	ld (0e0f1h),a		;58dc
	ld a,008h		;58df
	ld (0e0ech),a		;58e1   ; postura 8
	call PINTA_AL_ATLETA_2		;58e4
	ld hl,0e02eh		;58e7
	res 6,(hl)		;58ea   ; bit 6 de 0xE02E
	ld hl,0e02dh		;58ec
	set 4,(hl)		;58ef   ; bit 4 de 0xE02D
	dec hl			;58f1
	bit 4,(hl)		;58f2
	ret nz			;58f4
	ld a,04ch		;58f5   ; sonido 0x4C
	jp PIDE_UN_SONIDO		;58f7
ATLETA_2_YA_SALIO:
	ld a,(0e0f1h)		;58fa
	or a			;58fd
	jr z,SIN_AGUANTE_2		;58fe
	dec a			;5900   ; gasta el aguante
	ld (0e0f1h),a		;5901
	cp 00ah		;5904
	ret nz			;5906
	ld a,010h		;5907   ; postura 0x10
	ld (0e0ech),a		;5909
	jp PINTA_AL_ATLETA_2		;590c
SIN_AGUANTE_2:
	set 0,(hl)		;590f
	ret			;5911
SALIDA_NULA_2:
	ld hl,0e029h		;5912
	bit 3,(hl)		;5915   ; bit 3 de 0xE029
	jr nz,ATLETA_2_PARANDO		;5917
	set 3,(hl)		;5919
	ret			;591b
ATLETA_2_PARANDO:
	ld a,(0e0ech)		;591c
	cp 008h		;591f   ; su postura
	jr z,ATLETA_2_SE_PARA		;5921
	ld a,(0e021h)		;5923   ; el jugador 2 sigue en juego
	bit 1,a		;5926
	jr nz,ATLETA_2_ARRANCA		;5928
	ld a,(0e0cdh)		;592a   ; su pulsacion
	rrca			;592d
	jr nc,PINTA_AL_ATLETA_2		;592e
ATLETA_2_ARRANCA:
	ld a,008h		;5930
	ld (0e0ech),a		;5932   ; postura 8
	call PINTA_AL_ATLETA_2		;5935
	ld a,002h		;5938   ; dos cuadros
	ld (0e0f1h),a		;593a
	ret			;593d
ATLETA_2_SE_PARA:
	ld hl,0e0f1h		;593e
	dec (hl)			;5941
	jr nz,PINTA_AL_ATLETA_2		;5942
	ld hl,0e029h		;5944   ; bit 1 de 0xE029
	set 1,(hl)		;5947
	res 3,(hl)		;5949
	ld hl,0e02eh		;594b
	set 6,(hl)		;594e   ; bit 6 de 0xE02E
	ld a,004h		;5950   ; velocidad inicial 4
	ld (0e0efh),a		;5952
	ld a,009h		;5955   ; postura 9
	ld (0e0ech),a		;5957
PINTA_AL_ATLETA_2:
	xor a			;595a   ; el 0 es el jugador 2
	jp PINTA_AL_ATLETA		;595b
PONE_LA_POSTURA_Y_PINTA:
	dec hl			;595e
	dec hl			;595f
	dec hl			;5960
	dec hl			;5961
	ld (hl),b			;5962   ; la postura queda cuatro bytes antes
	ld a,0b6h		;5963   ; 0xE0B6 es el atleta del jugador 1
	cp l			;5965
	ld a,001h		;5966
	jr z,PINTA_LA_POSTURA		;5968
	xor a			;596a
PINTA_LA_POSTURA:
	jp PINTA_AL_ATLETA		;596b
MIRA_SI_HAN_LLEGADO_LOS_DOS:
	or a			;596e
	jr nz,ANIMA_LA_LLEGADA		;596f   ; con resultado, va por otro lado
	ld a,(0e0b7h)		;5971   ; bit 0 de 0xE0B7
	rrca			;5974
	ret nc			;5975
	ld a,(0e0edh)		;5976   ; y bit 0 de 0xE0ED
	rrca			;5979
	ret nc			;597a
SE_ACABO_LA_CARRERA:
	ld a,080h		;597b
	ld (0e0bbh),a		;597d   ; cuenta de 0x80 cuadros para los dos
	ld (0e0f1h),a		;5980
	ld hl,0e02eh		;5983
	set 0,(hl)		;5986   ; bit 0 de 0xE02E: intento acabado
	ld a,0a5h		;5988   ; sonido 0xA5
	call PIDE_UN_SONIDO		;598a
	jp MUEVE_EL_SONIDO		;598d   ; y para la musica
ANIMA_LA_LLEGADA:
	ld c,a			;5990
	dec (hl)			;5991   ; la cuenta de la animacion
	jr z,SE_ACABO_LA_ANIMACION		;5992   ; al llegar a cero se acaba
	bit 4,(hl)		;5994   ; bit 4: va hacia atras
	jr nz,UNA_POSTURA_ATRAS		;5996
	ld a,002h		;5998   ; dos posturas mas
	jr CAMBIA_DE_POSTURA		;599a
UNA_POSTURA_ATRAS:
	ld a,0ffh		;599c   ; o una menos
CAMBIA_DE_POSTURA:
	add a,c			;599e
	ld b,a			;599f
	dec hl			;59a0
	ld a,(0e016h)		;59a1   ; en las pruebas de distancia la postura va cuatro bytes antes
	bit 1,a		;59a4
	jr z,PONE_LA_POSTURA_Y_PINTA		;59a6
	dec hl			;59a8
	dec hl			;59a9
	dec hl			;59aa
	dec hl			;59ab
	ld (hl),b			;59ac
	call FICHA_DEL_QUE_JUEGA		;59ad   ; la ficha del atleta al que le toca
	ld a,b			;59b0
	jp PINTA_AL_ATLETA		;59b1
SE_ACABO_LA_ANIMACION:
	ld hl,0e02eh		;59b4
	set 1,(hl)		;59b7   ; bit 1 de 0xE02E: se acabo la prueba
	ld hl,0e020h		;59b9
	res 2,(hl)		;59bc   ; y baja el bit de prueba terminada
	ret			;59be
CORRE_EL_ATLETA:
	push hl			;59bf
	call FICHA_DEL_QUE_JUEGA		;59c0   ; la ficha del que juega
	pop hl			;59c3
	ld a,(0e020h)		;59c4   ; bit 2 de 0xE020: la prueba ya termino
	bit 2,a		;59c7
	ld a,b			;59c9
	jp nz,PINTA_AL_ATLETA		;59ca
	push hl			;59cd
	push de			;59ce
	ld a,l			;59cf
	ld de,0e15ch		;59d0   ; la columna del objeto del jugador 1
	ld hl,0e028h		;59d3
	cp 0aeh		;59d6
	jr z,MIRA_SI_LLEGA_A_LA_META		;59d8
	ld de,0e14ch		;59da   ; o la del 2
	ld hl,0e029h		;59dd
MIRA_SI_LLEGA_A_LA_META:
	ld a,(de)			;59e0
	cp 05ah		;59e1   ; la columna del objeto
	jr nc,MUEVE_LAS_PIERNAS		;59e3   ; la meta esta en 0x5A
	dec de			;59e5
	ld a,(de)			;59e6
	cp 001h		;59e7   ; y con el tramo final puesto
	jr nz,MUEVE_LAS_PIERNAS		;59e9
	set 2,(hl)		;59eb   ; bit 2: llegada
MUEVE_LAS_PIERNAS:
	pop de			;59ed
	pop hl			;59ee
	push hl			;59ef
	xor a			;59f0
	cp (hl)			;59f1   ; sin velocidad no se mueve
	jr z,PINTA_LA_ZANCADA		;59f2
	ld a,(de)			;59f4   ; mientras quede cuenta de paso, se gasta
	or a			;59f5
	jr nz,GASTA_LA_CUENTA_DE_PASO		;59f6
	ld a,016h		;59f8   ; 0x16 menos la velocidad da los cuadros por paso
	sub (hl)			;59fa
	daa			;59fb
	cp 010h		;59fc   ; en BCD
	jr c,CUADROS_POR_PASO		;59fe
AJUSTA_EL_PASO:
	sub 006h		;5a00
CUADROS_POR_PASO:
	srl a		;5a02   ; dividido por ocho
	srl a		;5a04
	srl a		;5a06
	ld (de),a			;5a08   ; y se guarda como cuenta
	ld a,(0e016h)		;5a09   ; en las de distancia la postura va en otro sitio
	bit 1,a		;5a0c
	jr z,SALTA_A_LA_POSTURA_DE_TIEMPO		;5a0e
	call POSTURA_DEL_QUE_JUEGA		;5a10
	jr SUBE_LA_POSTURA		;5a13
SALTA_A_LA_POSTURA_DE_TIEMPO:
	ld bc,00008h		;5a15   ; y en las de tiempo, ocho bytes mas alla
	add hl,bc			;5a18
SUBE_LA_POSTURA:
	inc (hl)			;5a19   ; postura siguiente
	ld a,00eh		;5a1a   ; las posturas de correr van de 9 a 0x0E
	ld b,009h		;5a1c
	cp (hl)			;5a1e
	jr nc,PINTA_LA_ZANCADA		;5a1f
	ld (hl),b			;5a21   ; al pasar de la 0x0E se vuelve a la 9
	ld a,048h		;5a22   ; sonido 0x48: la zancada
	call PIDE_UN_SONIDO		;5a24
PINTA_LA_ZANCADA:
	pop hl			;5a27
	push hl			;5a28
	ld a,(0e016h)		;5a29   ; la prueba
	bit 1,a		;5a2c
	jr z,PINTA_LA_ZANCADA_DE_TIEMPO		;5a2e
	push hl			;5a30
	call FICHA_DEL_QUE_JUEGA		;5a31
	pop hl			;5a34
	jr PINTA_Y_MIRA_EL_FINAL		;5a35
PINTA_LA_ZANCADA_DE_TIEMPO:
	ld a,l			;5a37
	ld b,001h		;5a38   ; el 1 es el jugador 1
	cp 0aeh		;5a3a
	jr z,PINTA_Y_MIRA_EL_FINAL		;5a3c
	ld b,000h		;5a3e
PINTA_Y_MIRA_EL_FINAL:
	ld a,b			;5a40
	call PINTA_AL_ATLETA		;5a41
	pop hl			;5a44
	jr MIRA_EL_FINAL_DE_LA_PRUEBA		;5a45
GASTA_LA_CUENTA_DE_PASO:
	ld a,(de)			;5a47
	dec a			;5a48
	ld (de),a			;5a49
	jr PINTA_LA_ZANCADA		;5a4a
MIRA_EL_FINAL_DE_LA_PRUEBA:
	ld a,(0e016h)		;5a4c
	bit 1,a		;5a4f   ; solo en las de distancia
	ret z			;5a51
	ld bc,0fe2bh		;5a52   ; lo que falta para 0x1D5
	ld hl,(0e0e8h)		;5a55
	add hl,bc			;5a58
	ret nc			;5a59   ; aun no ha llegado a la tabla
	ld a,(0e016h)		;5a5a
	cp 003h		;5a5d   ; en el martillo
	jr nz,MIRA_EL_ANGULO_DEL_TIRO		;5a5f
	dec de			;5a61
	dec de			;5a62
	dec de			;5a63
	ld a,(de)			;5a64   ; hace falta angulo
	cp 005h		;5a65
	ret c			;5a67
MIRA_EL_ANGULO_DEL_TIRO:
	ld a,(0e0c5h)		;5a68   ; bit 1 de 0xE0C5
	bit 1,a		;5a6b
	ret z			;5a6d
	xor a			;5a6e
	ld (0e0c5h),a		;5a6f
	ld hl,0e020h		;5a72   ; bit 2 de 0xE020: la prueba se acaba
	set 2,(hl)		;5a75
	ret			;5a77
SUBE_UN_PATRON_DE_SPRITE:
	ld c,020h		;5a78   ; 32 bytes por patron
	call FIJA_ESCRITURA_CON_CANDADO		;5a7a   ; fija la direccion de VRAM
	exx			;5a7d
	push bc			;5a7e
	ld a,(00006h)		;5a7f   ; el puerto de datos
	ld c,a			;5a82
	exx			;5a83
UN_BYTE_DEL_PATRON:
	ld a,(hl)			;5a84
	or a			;5a85   ; el cero abre una racha
	jr nz,SUELTA_UN_BYTE		;5a86
	inc c			;5a88   ; la cuenta no gasta el byte de la racha
	inc hl			;5a89
	ld b,(hl)			;5a8a   ; cuantos ceros
SUELTA_CEROS:
	exx			;5a8b
	out (c),a		;5a8c   ; el puerto de datos del VDP
	exx			;5a8e
	dec c			;5a8f   ; la cuenta baja con cada cero
	djnz SUELTA_CEROS		;5a90
	jr SIGUIENTE_BYTE_DEL_PATRON		;5a92
SUELTA_UN_BYTE:
	exx			;5a94
	out (c),a		;5a95   ; el byte va tal cual
	exx			;5a97
SIGUIENTE_BYTE_DEL_PATRON:
	inc hl			;5a98
	dec c			;5a99   ; hasta completar los 32
	jr nz,UN_BYTE_DEL_PATRON		;5a9a
	exx			;5a9c
	pop bc			;5a9d
	exx			;5a9e
	ret			;5a9f
MUEVE_EL_DECORADO:
	ld (0e0fdh),a		;5aa0   ; el 1 es el jugador 1, el 0 el jugador 2
	ld de,0e153h		;5aa3   ; la columna del segundo objeto
	push de			;5aa6
	ld hl,0e0c4h		;5aa7   ; y la marca del jugador 1
	exx			;5aaa
	ld hl,0e0b2h		;5aab   ; su posicion
	pop de			;5aae
	exx			;5aaf
	or a			;5ab0
	jr nz,SUMA_EL_AVANCE_AL_DECORADO		;5ab1   ; con cero se pasa al jugador 2
	exx			;5ab3
	ld hl,0e0e8h		;5ab4   ; la posicion del jugador 2
	ld de,0e143h		;5ab7   ; la columna del primer objeto
	push de			;5aba
	exx			;5abb
	pop de			;5abc
	ld hl,0e0fah		;5abd   ; y su marca
SUMA_EL_AVANCE_AL_DECORADO:
	exx			;5ac0
	ld a,(de)			;5ac1   ; el avance del cuadro
	add a,(hl)			;5ac2   ; se acumula en la posicion
	ld (hl),a			;5ac3
	inc hl			;5ac4
	ld a,000h		;5ac5
	adc a,(hl)			;5ac7
	ld (hl),a			;5ac8
	exx			;5ac9
	ld a,(0e016h)		;5aca   ; en el salto de longitud aqui se acaba
	cp 002h		;5acd
	ret z			;5acf
	ld a,(de)			;5ad0
	add a,(hl)			;5ad1
	ld c,a			;5ad2
	ld (hl),a			;5ad3
	sub 09ch		;5ad4   ; cada 0x9C de avance toca cambiar de tramo
	jr c,CORRE_LAS_MARCAS		;5ad6
	ld (hl),a			;5ad8
	push hl			;5ad9
	push de			;5ada
	push bc			;5adb
	call CORRE_LAS_MARCAS		;5adc   ; y se corre el decorado
	pop bc			;5adf
	pop de			;5ae0
	pop hl			;5ae1
	ld a,(0e0fdh)		;5ae2
	push de			;5ae5
	ld de,AJUSTA_EL_PASO		;5ae6   ; la fila de sprites del decorado
	ld hl,0e0b8h		;5ae9
	push bc			;5aec
	ld b,003h		;5aed
	ld c,0b7h		;5aef   ; tres marcas por fila
	or a			;5af1
	jr nz,BUSCA_UNA_MARCA_LIBRE		;5af2
	ld c,087h		;5af4   ; el jugador 2 usa la 0x87
	ld a,(0e016h)		;5af6
	bit 1,a		;5af9
	jr z,MARCAS_DEL_JUGADOR_1		;5afb
	ld c,0a0h		;5afd   ; o la 0xA0 en las de distancia
MARCAS_DEL_JUGADOR_1:
	ld de,05a80h		;5aff
	ld hl,0e0eeh		;5b02
BUSCA_UNA_MARCA_LIBRE:
	push hl			;5b05
	ex de,hl			;5b06
	ld de,00040h		;5b07   ; cuatro bytes por sprite
	add hl,de			;5b0a
	ex de,hl			;5b0b
	pop hl			;5b0c
	inc hl			;5b0d   ; y cuatro por marca
	inc hl			;5b0e
	inc hl			;5b0f
	inc hl			;5b10
	dec b			;5b11
	jr z,PONE_LA_MARCA_EN_SU_SITIO		;5b12
	ld a,0cfh		;5b14   ; 0xCF es fila libre
	cp (hl)			;5b16
	jr nz,BUSCA_UNA_MARCA_LIBRE		;5b17
PONE_LA_MARCA_EN_SU_SITIO:
	ld (hl),c			;5b19   ; el patron de la marca
	inc hl			;5b1a
	pop bc			;5b1b
	ld a,c			;5b1c
	sub 09ch		;5b1d   ; lo que sobra del tramo
	ld b,a			;5b1f
	ld a,0e0h		;5b20   ; da la columna
	sub b			;5b22
	ld (hl),a			;5b23
	xor a			;5b24
	pop bc			;5b25
	ld (bc),a			;5b26   ; y el avance se da por gastado
	inc hl			;5b27
	push hl			;5b28
	push de			;5b29
	push bc			;5b2a
	call PINTA_LA_CIFRA_DE_LA_MARCA		;5b2b   ; pinta la cifra de la marca
	pop bc			;5b2e
	pop de			;5b2f
	pop hl			;5b30
	ld a,020h		;5b31   ; la marca sube 0x20 en BCD
	add a,(hl)			;5b33
	daa			;5b34
	ld (hl),a			;5b35
	inc hl			;5b36
	ld a,000h		;5b37
	adc a,(hl)			;5b39
	daa			;5b3a
	ld (hl),a			;5b3b
	ret			;5b3c
CORRE_LAS_MARCAS:
	ld b,002h		;5b3d   ; dos marcas
	ld a,(de)			;5b3f   ; lo que hay que correr
	ld c,a			;5b40
	xor a			;5b41
	ld (de),a			;5b42   ; y se da por gastado
	ld a,(0e0fdh)		;5b43
	ld hl,0e0bdh		;5b46   ; las marcas del jugador 1
	or a			;5b49
	jr nz,CORRE_UNA_MARCA		;5b4a
	ld hl,0e0f3h		;5b4c   ; o las del 2
CORRE_UNA_MARCA:
	ld a,(hl)			;5b4f
	sub c			;5b50   ; se le resta el avance
	ld (hl),a			;5b51
	push hl			;5b52
	sub 010h		;5b53   ; y si se sale por la izquierda
	jr nc,SIGUIENTE_MARCA		;5b55
	dec hl			;5b57
	ld (hl),0cfh		;5b58   ; se esconde en la fila 0xCF
SIGUIENTE_MARCA:
	pop hl			;5b5a
	inc hl			;5b5b   ; cuatro bytes por sprite
	inc hl			;5b5c
	inc hl			;5b5d
	inc hl			;5b5e
	djnz CORRE_UNA_MARCA		;5b5f
	ld bc,0fff7h		;5b61   ; nueve atras
	add hl,bc			;5b64
	jp CORRE_LAS_CIFRAS		;5b65
PINTA_LA_CIFRA_DE_LA_MARCA:
	push hl			;5b68
	ld a,(hl)			;5b69   ; la cifra de arriba
	and 0f0h		;5b6a
	rrca			;5b6c   ; en la fuente
	ld hl,06002h		;5b6d
	call SUMA_A_A_HL		;5b70
	ld b,008h		;5b73   ; sus ocho bytes al patron del sprite
	call SUBE_BYTES_CON_DIRECCION		;5b75
	pop hl			;5b78
	inc hl			;5b79
	ld a,(hl)			;5b7a   ; con la cifra de abajo a cero se acaba
	cp 000h		;5b7b
	ret z			;5b7d
	and 00fh		;5b7e   ; la cifra de abajo
	rlca			;5b80
	rlca			;5b81
	rlca			;5b82
	push hl			;5b83
	ld hl,00030h		;5b84   ; tres filas mas abajo
	add hl,de			;5b87
	ex de,hl			;5b88
	ld hl,06002h		;5b89   ; en la fuente
	call SUMA_A_A_HL		;5b8c
	ld b,008h		;5b8f
	call SUBE_BYTES_CON_DIRECCION		;5b91
	pop hl			;5b94
	bit 4,(hl)		;5b95   ; bit 4: hace falta un cero delante
	ret z			;5b97
	ld hl,0fff0h		;5b98   ; dieciseis atras
	add hl,de			;5b9b
	ex de,hl			;5b9c
	ld hl,0600ah		;5b9d   ; el glifo del uno
	ld b,008h		;5ba0
	call SUBE_BYTES_CON_DIRECCION		;5ba2
	ret			;5ba5
CORRE_LAS_CIFRAS:
	push hl			;5ba6
	push de			;5ba7
	ld de,07b48h		;5ba8   ; la fila de las cifras del jugador 1
	ld a,0bch		;5bab
	cp l			;5bad   ; segun de quien sean
	jr z,DOS_CIFRAS		;5bae
	ld de,07b58h		;5bb0   ; o la del 2
DOS_CIFRAS:
	ld c,002h		;5bb3
UNA_CIFRA:
	ld b,002h		;5bb5
	call SUBE_BYTES_CON_DIRECCION		;5bb7   ; fila y columna
	dec hl			;5bba
	dec hl			;5bbb
	inc de			;5bbc
	inc de			;5bbd
	inc de			;5bbe
	inc de			;5bbf
	ld a,(hl)			;5bc0   ; la fila
	ld (0e0fbh),a		;5bc1
	inc hl			;5bc4
	ld a,(hl)			;5bc5
	sub 010h		;5bc6   ; y la columna menos 0x10
	ld (0e0fch),a		;5bc8
	push hl			;5bcb
	ld hl,0e0fbh		;5bcc
	ld b,002h		;5bcf
	call SUBE_BYTES_CON_DIRECCION		;5bd1   ; al sprite de al lado
	pop hl			;5bd4
	inc hl			;5bd5
	inc hl			;5bd6
	inc hl			;5bd7
	inc de			;5bd8
	inc de			;5bd9
	inc de			;5bda
	inc de			;5bdb
	dec c			;5bdc
	jr nz,UNA_CIFRA		;5bdd
	pop de			;5bdf
	pop hl			;5be0
	ret			;5be1
PINTA_A_LOS_DOS_ATLETAS:
	ld a,(0e000h)		;5be2
	bit 0,a		;5be5   ; en los cuadros pares
	jr nz,PINTA_LOS_OBJETOS		;5be7
	call AVANZA_EL_QUE_JUEGA		;5be9   ; mueve el decorado
	ld hl,0e130h		;5bec   ; y las dos fichas
	call MUEVE_Y_PINTA_UN_ACTOR		;5bef
	ld hl,0e120h		;5bf2
	jp MUEVE_Y_PINTA_UN_ACTOR		;5bf5
PINTA_LOS_OBJETOS:
	ld a,(0e016h)		;5bf8
	cp 003h		;5bfb   ; en el martillo no hay tope
	jr z,PINTA_LAS_MARCAS		;5bfd
	ld hl,(0e0e8h)		;5bff   ; la posicion del jugador 2
	ld bc,0fd6dh		;5c02   ; hasta 0x293 no se pintan
	add hl,bc			;5c05
	ret c			;5c06
PINTA_LAS_MARCAS:
	ld hl,0e140h		;5c07   ; la ficha del primer objeto
	call MUEVE_Y_PINTA_UN_ACTOR		;5c0a   ; y la del segundo
	ld hl,0e150h		;5c0d
	call MUEVE_Y_PINTA_UN_ACTOR		;5c10
	xor a			;5c13
	call MUEVE_EL_DECORADO		;5c14   ; corre el decorado del jugador 2
	xor a			;5c17   ; y le borra el avance
	ld (0e143h),a		;5c18
	ret			;5c1b
AVANZA_EL_QUE_JUEGA:
	call COLUMNA_DEL_QUE_JUEGA		;5c1c   ; la ficha del que juega
	ex de,hl			;5c1f
	ld hl,0e02ch		;5c20
	ld a,(0e020h)		;5c23   ; bit 2 de 0xE020: la prueba ya acabo
	bit 2,a		;5c26
	jr nz,QUITA_CUATRO_SPRITES		;5c28
	bit 1,(hl)		;5c2a   ; bit 1 de 0xE02C: ya esta en el tramo final
	jr nz,TRAMO_FINAL		;5c2c
	ld a,(de)			;5c2e   ; la columna del atleta
	cp 070h		;5c2f   ; hasta 0x70 avanza el atleta
	jr c,AVANZA_EL_ATLETA_SOLO		;5c31
	set 1,(hl)		;5c33   ; y a partir de ahi, el decorado
AVANZA_EL_DECORADO:
	ld a,(0e0b9h)		;5c35
	ld hl,0e141h		;5c38   ; el avance del cuadro
	add a,(hl)			;5c3b   ; al decorado
	ld (hl),a			;5c3c
GASTA_EL_AVANCE:
	ld hl,0e0b9h		;5c3d
	ld (hl),000h		;5c40   ; el avance se da por gastado
	ld a,(0e020h)		;5c42
	bit 2,a		;5c45   ; bit 2 de 0xE020
	jr nz,QUITA_CUATRO_SPRITES		;5c47
	ld hl,(0e0e8h)		;5c49   ; la posicion del jugador 2
	ld bc,0fd6fh		;5c4c   ; lo que falta para 0x291
	add hl,bc			;5c4f
	jr nc,QUITA_CUATRO_SPRITES		;5c50
	ld hl,0e02ch		;5c52
	set 0,(hl)		;5c55   ; bit 0 de 0xE02C: ha llegado
QUITA_CUATRO_SPRITES:
	dec de			;5c57
	dec de			;5c58
	dec de			;5c59
	dec de			;5c5a
	ld hl,0e0aeh		;5c5b   ; la ficha del atleta del jugador 1
	jp CORRE_EL_ATLETA		;5c5e
AVANZA_EL_ATLETA_SOLO:
	ld hl,0e0b9h		;5c61
	add a,(hl)			;5c64   ; el avance del cuadro
	ld (de),a			;5c65   ; a la columna
	jr GASTA_EL_AVANCE		;5c66
TRAMO_FINAL:
	ld hl,(0e0e8h)		;5c68
	ld bc,0fed4h		;5c6b   ; lo que falta para 0x12C
	add hl,bc			;5c6e
	jr nc,AVANZA_EL_DECORADO		;5c6f   ; antes de eso, avanza el decorado
	ld hl,(0e0e8h)		;5c71
	ld bc,0fd88h		;5c74   ; lo que falta para 0x278
	add hl,bc			;5c77
	jr nc,TIRA_DEL_ATLETA_ATRAS		;5c78
	ld a,(de)			;5c7a   ; la columna del atleta
	ld hl,0e0b9h		;5c7b
	add a,(hl)			;5c7e
	ld (de),a			;5c7f   ; mas el avance
	cp 060h		;5c80   ; hasta 0x60
	jr c,GASTA_EL_AVANCE		;5c82
	ld hl,0e02ch		;5c84
	set 0,(hl)		;5c87   ; y a partir de ahi, llegada
	jr GASTA_EL_AVANCE		;5c89
TIRA_DEL_ATLETA_ATRAS:
	ld a,(de)			;5c8b
	cp 008h		;5c8c   ; por debajo de 8 no se le tira mas
	jr c,AVANZA_EL_DECORADO		;5c8e
	dec a			;5c90   ; se le quitan dos columnas
	dec a			;5c91
	ld (de),a			;5c92
	jp AVANZA_EL_DECORADO		;5c93

; ----------------------------------------------------------------------
; DATOS pantalla_del_titulo: El guion largo entero de la presentacion:
;   logotipo, el copyright de Konami y el menu. Nueve ordenes.
;   0x5c96..0x5ff2  (860 bytes)
DATA_pantalla_del_titulo:
	defb 009h,000h,00eh,065h,0a0h,038h,000h,000h	; 5c96  ...e.8..
	defb 002h,000h,08ah,0aah,0aah,0dah,000h,000h	; 5c9e  ........
	defb 008h,048h,0eeh,04ah,04ah,06ah,000h,00fh	; 5ca6  .H.JJj..
	defb 0bfh,0ffh,0ffh,0ffh,0bfh,00fh,000h,000h	; 5cae  ........
	defb 0fch,0c0h,0c0h,080h,080h,000h,011h,008h	; 5cb6  ........
	defb 000h,081h,042h,024h,018h,018h,024h,042h	; 5cbe  ..B$..$B
	defb 081h,03ch,042h,099h,0bdh,0bdh,099h,042h	; 5cc6  .<B....B
	defb 03ch,067h,050h,030h,03ch,042h,099h,0a1h	; 5cce  <gP0<B..
	defb 0a1h,099h,042h,03ch,003h,067h,06eh,07ch	; 5cd6  ..B<.gn|
	defb 079h,079h,07fh,06fh,080h,000h,000h,03dh	; 5cde  yy.o...=
	defb 0adh,0adh,0adh,03dh,000h,000h,000h,0ceh	; 5ce6  ...=....
	defb 063h,06fh,06bh,06fh,000h,000h,000h,07ch	; 5cee  coko...|
	defb 056h,056h,056h,056h,000h,000h,0c0h,000h	; 5cf6  VVVV....
	defb 011h,004h,0c0h,063h,0d8h,0e8h,011h,00ah	; 5cfe  ...c....
	defb 0f0h,0f8h,0fch,07fh,03fh,00fh,003h,011h	; 5d06  ....?...
	defb 00ah,00fh,01fh,03fh,0feh,0fch,0f0h,0c0h	; 5d0e  ...?....
	defb 000h,080h,011h,006h,0ffh,000h,001h,011h	; 5d16  ........
	defb 006h,0ffh,000h,000h,011h,006h,0ffh,000h	; 5d1e  ........
	defb 000h,000h,0ffh,000h,0ffh,000h,0ffh,000h	; 5d26  ........
	defb 000h,000h,003h,007h,00fh,01eh,011h,00bh	; 5d2e  ........
	defb 01ch,01eh,00fh,007h,003h,011h,005h,000h	; 5d36  ........
	defb 0ffh,0ffh,0ffh,011h,005h,000h,0e0h,0f0h	; 5d3e  ........
	defb 0f8h,03ch,011h,00bh,01ch,03ch,0f8h,0f0h	; 5d46  .<...<..
	defb 0e0h,011h,007h,000h,001h,011h,00ch,003h	; 5d4e  ........
	defb 001h,011h,008h,000h,07fh,0ffh,0ffh,0c0h	; 5d56  ........
	defb 011h,00ah,080h,0c0h,0ffh,0ffh,07fh,011h	; 5d5e  ........
	defb 006h,000h,0ffh,0ffh,0ffh,011h,004h,000h	; 5d66  ........
	defb 0ffh,0ffh,0ffh,011h,006h,000h,0feh,0ffh	; 5d6e  ........
	defb 0ffh,003h,011h,00ah,001h,003h,0ffh,0ffh	; 5d76  ........
	defb 0feh,011h,008h,000h,080h,011h,00ch,0c0h	; 5d7e  ........
	defb 080h,011h,005h,000h,060h,00eh,002h,007h	; 5d86  ....`...
	defb 00fh,060h,016h,01ah,0f8h,0f0h,011h,004h	; 5d8e  .`......
	defb 03eh,011h,004h,03fh,01fh,03fh,07fh,0ffh	; 5d96  >..?.?..
	defb 0feh,0fch,0f8h,0f0h,0e0h,0c0h,080h,000h	; 5d9e  ........
	defb 000h,000h,03eh,03eh,060h,035h,003h,01fh	; 5da6  ..>>`5..
	defb 07fh,0fbh,060h,03dh,003h,00fh,0cfh,0efh	; 5dae  ..`=....
	defb 060h,045h,003h,078h,0fch,0bch,060h,04dh	; 5db6  `E.x..`M
	defb 003h,03fh,07fh,0f3h,060h,055h,003h,087h	; 5dbe  .?..`U..
	defb 0c7h,0c7h,060h,05dh,003h,0bch,0feh,0dfh	; 5dc6  ..`]....
	defb 060h,065h,06bh,078h,0fch,0bch,060h,0f0h	; 5dce  `ekx..`.
	defb 0f0h,060h,000h,0f0h,0f0h,0f0h,03fh,03fh	; 5dd6  .`....??
	defb 011h,006h,03eh,0f8h,0fch,0feh,07fh,03fh	; 5dde  ..>....?
	defb 01fh,00fh,007h,03eh,03eh,03eh,07eh,0fch	; 5de6  ...>>>~.
	defb 0fch,0f8h,0e0h,011h,005h,0f1h,0fbh,07fh	; 5dee  ........
	defb 01fh,011h,006h,0efh,0cfh,00fh,011h,008h	; 5df6  ........
	defb 01eh,0e1h,003h,03fh,0f1h,0e1h,0f3h,07fh	; 5dfe  ...?....
	defb 01eh,011h,008h,0e7h,011h,008h,08fh,011h	; 5e06  ........
	defb 008h,01eh,0f1h,0f2h,011h,004h,0f5h,0f2h	; 5e0e  ........
	defb 0f1h,0e0h,010h,0c8h,068h,0c8h,028h,010h	; 5e16  ....h.(.
	defb 0e0h,061h,000h,000h,011h,004h,00fh,01eh	; 5e1e  .a......
	defb 01eh,01eh,03fh,09eh,03eh,03eh,03ch,07ch	; 5e26  ..?.>><|
	defb 078h,0f8h,0f0h,000h,0e7h,0e7h,0eeh,0eeh	; 5e2e  x.......
	defb 0fch,0dch,0f8h,000h,0bfh,03fh,03fh,073h	; 5e36  .....??s
	defb 077h,077h,0ffh,000h,00fh,08fh,09fh,09ch	; 5e3e  ww......
	defb 09ch,038h,03fh,000h,0e7h,0c7h,0c7h,00eh	; 5e46  .8?.....
	defb 00eh,00eh,09fh,000h,0e0h,0f0h,0f0h,070h	; 5e4e  .......p
	defb 0f0h,0f0h,0e0h,000h,007h,00fh,00fh,01eh	; 5e56  ........
	defb 01eh,01ch,03dh,000h,0f0h,0f8h,0f8h,071h	; 5e5e  ..=....q
	defb 0f1h,0f1h,0e3h,000h,0f8h,0f0h,0f0h,0e0h	; 5e66  ........
	defb 0e0h,0e0h,0c0h,000h,0bch,03ch,03ch,07ch	; 5e6e  .....<<|
	defb 07dh,07dh,0ffh,000h,07eh,07ch,0fch,0f8h	; 5e76  }}..~|..
	defb 0f8h,0f8h,0f0h,000h,03fh,03fh,03fh,073h	; 5e7e  ....???s
	defb 077h,077h,0ffh,000h,00fh,08eh,09eh,09ch	; 5e86  ww......
	defb 09ch,03ch,038h,000h,00fh,03fh,03fh,073h	; 5e8e  .<8..??s
	defb 073h,0e0h,0e0h,000h,000h,080h,080h,080h	; 5e96  s.......
	defb 080h,000h,000h,03fh,03ch,079h,079h,079h	; 5e9e  ...?<yyy
	defb 0f3h,0f3h,0f3h,0f0h,0f0h,0f0h,0e0h,0e1h	; 5ea6  ........
	defb 0e1h,0c3h,0c3h,0f8h,0f0h,0f1h,0e1h,0e1h	; 5eae  ........
	defb 0c3h,0c3h,0c7h,0feh,0feh,0fch,0c0h,0c0h	; 5eb6  ........
	defb 080h,080h,081h,03fh,07fh,070h,070h,0e0h	; 5ebe  ...?.pp.
	defb 0feh,0fch,0fch,01fh,01fh,03bh,03bh,03bh	; 5ec6  .....;;;
	defb 073h,073h,0f3h,011h,008h,080h,03dh,039h	; 5ece  ss....=9
	defb 07bh,07bh,0e3h,0ffh,0ffh,07fh,0e3h,0e3h	; 5ed6  {{......
	defb 0c7h,0c7h,0c7h,08fh,08fh,01fh,0c0h,0c0h	; 5ede  ........
	defb 080h,080h,001h,0f9h,0f3h,0f3h,0ffh,0deh	; 5ee6  ........
	defb 0deh,0dch,09dh,099h,099h,013h,0f0h,0f0h	; 5eee  ........
	defb 0f1h,0e1h,0e1h,0e3h,0c3h,0c7h,0feh,0feh	; 5ef6  ........
	defb 0fch,0c0h,0c0h,080h,080h,081h,039h,079h	; 5efe  ......9y
	defb 071h,073h,0f3h,0e3h,0e3h,0e1h,0c0h,0c0h	; 5f06  qs......
	defb 0c0h,08eh,08eh,0dch,0fch,0f8h,000h,000h	; 5f0e  ........
	defb 000h,001h,007h,001h,001h,003h,062h,000h	; 5f16  ......b.
	defb 018h,07ch,0f8h,0f8h,0f8h,0f0h,0f0h,0f0h	; 5f1e  .|......
	defb 0e0h,003h,003h,007h,007h,007h,00fh,03fh	; 5f26  .......?
	defb 03fh,0e0h,0e0h,0c0h,0c0h,0c0h,080h,0f0h	; 5f2e  ?.......
	defb 0f0h,001h,006h,065h,008h,001h,002h,003h	; 5f36  ...e....
	defb 004h,00ch,00eh,014h,019h,01dh,013h,00dh	; 5f3e  ........
	defb 015h,01ah,016h,00bh,021h,00fh,01bh,01ch	; 5f46  ....!...
	defb 0ffh,065h,0d8h,028h,029h,029h,02ah,02ah	; 5f4e  .e.())**
	defb 00bh,00ch,00dh,00eh,00fh,010h,011h,012h	; 5f56  ........
	defb 013h,014h,015h,016h,017h,018h,019h,01ah	; 5f5e  ........
	defb 01bh,01ch,01dh,01eh,01fh,020h,021h,0ffh	; 5f66  ..... !.
	defb 066h,0e0h,026h,027h,024h,025h,022h,023h	; 5f6e  f.&'$%"#
	defb 0ffh,067h,080h,000h,001h,002h,003h,004h	; 5f76  .g......
	defb 005h,006h,007h,008h,009h,0ffh,067h,010h	; 5f7e  ......g.
	defb 02bh,02ch,01eh,00bh,016h,013h,010h,021h	; 5f86  +,.....!
	defb 0ffh,064h,0c0h,00eh,016h,020h,01ch,00dh	; 5f8e  .d... ..
	defb 019h,01bh,00fh,0ffh,003h,009h,045h,008h	; 5f96  ......E.
	defb 0a8h,070h,018h,0f0h,010h,060h,010h,0f0h	; 5f9e  .p...`..
	defb 010h,060h,0c0h,0f0h,060h,070h,038h,060h	; 5fa6  .`..`p8`
	defb 088h,0f0h,003h,001h,040h,008h,000h,0f0h	; 5fae  ....@...
	defb 003h,001h,041h,000h,0a8h,050h,003h,010h	; 5fb6  ..A..P..
	defb 043h,0d8h,00ch,06ah,004h,067h,00ch,06ah	; 5fbe  C..j.g.j
	defb 004h,067h,004h,0a0h,004h,066h,004h,0a0h	; 5fc6  .g...f..
	defb 004h,066h,004h,0a0h,004h,060h,002h,011h	; 5fce  .f...`..
	defb 006h,0feh,038h,0a0h,070h,050h,040h,070h	; 5fd6  ..8.pP@p
	defb 008h,077h,004h,041h,000h,010h,0f2h,05fh	; 5fde  .w.A..._
	defb 004h,041h,080h,00fh,0fah,05fh,003h,001h	; 5fe6  .A..._..
	defb 041h,0f8h,020h,0a0h	; 5fee

; ----------------------------------------------------------------------
; DATOS patrones_de_relleno: Dos patrones de ocho bytes que la orden 4 del
;   guion del titulo repite para rellenar tramos de la tabla de patrones.
;   0x5ff2..0x6002  (16 bytes)
DATA_patrones_de_relleno:
	defb 060h,060h,060h,090h,060h,0f0h,060h,0f0h	; 5ff2  ```.`.`.
	defb 080h,0f0h,080h,0f0h,090h,0f0h,090h,0f0h	; 5ffa  ........

; ----------------------------------------------------------------------
; DATOS fuente: Los 51 glifos de 8x8 con los que se escribe TODO el cartucho.
;   El alfabeto va ordenado de la A (indice 0x0B) a la Y SALTANDOSE la Q, la X
;   y la Z, pero la Q SI existe: esta al final, en el indice 0x2C, fuera del
;   alfabeto, porque la necesita QUALIFY (la tira de 0x5F87). X y Z no salen
;   en ningun rotulo. Detras van "min", "SEC", "m", el punto, las flechas y
;   los dos puntos. Los leen 0x4C88, 0x4D5F y 0x5B68.
;   0x6002..0x619a  (408 bytes)
DATA_fuente:
	defb 000h,01ch,022h,063h,063h,063h,022h,01ch	; 6002  .."ccc".
	defb 000h,018h,038h,018h,018h,018h,018h,07eh	; 600a  ..8....~
	defb 000h,03eh,063h,003h,00eh,03ch,070h,07fh	; 6012  .>c..<p.
	defb 000h,03eh,063h,003h,00eh,003h,063h,03eh	; 601a  .>c...c>
	defb 000h,00eh,01eh,036h,066h,066h,07fh,006h	; 6022  ...6ff..
	defb 000h,07fh,060h,07eh,063h,003h,063h,03eh	; 602a  ..`~c.c>
	defb 000h,03eh,063h,060h,07eh,063h,063h,03eh	; 6032  .>c`~cc>
	defb 000h,07fh,063h,006h,00ch,018h,018h,018h	; 603a  ..c.....
	defb 000h,03eh,063h,063h,03eh,063h,063h,03eh	; 6042  .>cc>cc>
	defb 000h,03eh,063h,063h,03fh,003h,063h,03eh	; 604a  .>cc?.c>
	defb 000h,000h,000h,000h,000h,000h,000h,000h	; 6052  ........
	defb 000h,01ch,036h,063h,063h,07fh,063h,063h	; 605a  ..6cc.cc
	defb 000h,07eh,063h,063h,07eh,063h,063h,07eh	; 6062  .~cc~cc~
	defb 000h,03eh,063h,060h,060h,060h,063h,03eh	; 606a  .>c```c>
	defb 000h,07ch,066h,063h,063h,063h,066h,07ch	; 6072  .|fcccf|
	defb 000h,07fh,060h,060h,07eh,060h,060h,07fh	; 607a  ..``~``.
	defb 000h,07fh,060h,060h,07eh,060h,060h,060h	; 6082  ..``~```
	defb 000h,03eh,063h,060h,067h,063h,063h,03fh	; 608a  .>c`gcc?
	defb 000h,063h,063h,063h,07fh,063h,063h,063h	; 6092  .ccc.ccc
	defb 000h,03ch,018h,018h,018h,018h,018h,03ch	; 609a  .<.....<
	defb 000h,01fh,006h,006h,006h,006h,066h,03ch	; 60a2  ......f<
	defb 000h,063h,066h,06ch,078h,07ch,06eh,067h	; 60aa  .cflx|ng
	defb 000h,060h,060h,060h,060h,060h,060h,07fh	; 60b2  .``````.
	defb 000h,063h,077h,07fh,07fh,06bh,063h,063h	; 60ba  .cw..kcc
	defb 000h,063h,073h,07bh,07fh,06fh,067h,063h	; 60c2  .cs{.ogc
	defb 000h,03eh,063h,063h,063h,063h,063h,03eh	; 60ca  .>ccccc>
	defb 000h,07eh,063h,063h,063h,07eh,060h,060h	; 60d2  .~ccc~``
	defb 000h,07eh,063h,063h,062h,07ch,066h,063h	; 60da  .~ccb|fc
	defb 000h,03eh,063h,060h,03eh,003h,063h,03eh	; 60e2  .>c`>.c>
	defb 000h,07eh,018h,018h,018h,018h,018h,018h	; 60ea  .~......
	defb 000h,063h,063h,063h,063h,063h,063h,03eh	; 60f2  .cccccc>
	defb 000h,063h,063h,063h,063h,036h,01ch,008h	; 60fa  .cccc6..
	defb 000h,063h,063h,06bh,06bh,07fh,077h,022h	; 6102  .cckk.w"
	defb 000h,066h,066h,07eh,03ch,018h,018h,018h	; 610a  .ff~<...
	defb 000h,000h,000h,0d4h,07ch,054h,054h,056h	; 6112  ....|TTV
	defb 000h,000h,000h,0dch,00eh,0cah,0cah,0cbh	; 611a  ........
	defb 000h,07bh,04ah,062h,033h,00ah,04ah,07bh	; 6122  .{Jb3.J{
	defb 000h,0deh,012h,010h,0d0h,010h,012h,0deh	; 612a  ........
	defb 000h,06dh,036h,024h,024h,024h,024h,024h	; 6132  .m6$$$$$
	defb 000h,080h,080h,080h,080h,080h,0a0h,0c0h	; 613a  ........
	defb 010h,030h,07eh,0feh,0feh,07eh,030h,010h	; 6142  .0~..~0.
	defb 008h,00ch,07eh,07fh,07fh,07eh,00ch,008h	; 614a  ..~..~..
	defb 000h,038h,07ch,0feh,0feh,0feh,07ch,038h	; 6152  .8|...|8
	defb 000h,018h,018h,000h,000h,018h,018h,000h	; 615a  ........
	defb 000h,03eh,063h,063h,063h,06fh,066h,03dh	; 6162  .>cccof=
	defb 0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh,0ffh	; 616a  ........
	defb 000h,066h,0ebh,06bh,06bh,06bh,06bh,066h	; 6172  .f.kkkkf
	defb 000h,07bh,049h,041h,041h,041h,049h,079h	; 617a  .{IAAAIy
	defb 000h,06ch,0b4h,024h,024h,024h,025h,026h	; 6182  .l.$$$%&
	defb 001h,002h,004h,008h,010h,020h,040h,080h	; 618a  ..... @.
	defb 000h,000h,07eh,000h,000h,07eh,000h,000h	; 6192  ..~..~..

; ----------------------------------------------------------------------
; DATOS rotulo_619A: Rotulo de letra grande, formato de 0x4C63.
;   0x619a..0x61b5  (27 bytes)
DATA_rotulo_619A:
	defb 000h,020h,000h,000h,0ffh,0ffh,011h,006h,000h,0ffh,0ffh,078h,03ch,01eh,00fh,000h	; 619a  . .........x<...
	defb 000h,0ffh,0ffh,011h,006h,000h,0ffh,0ffh,011h,004h,000h	; 61aa  ...........

; ----------------------------------------------------------------------
; DATOS rotulo_61B5: Rotulo de letra grande.
;   0x61b5..0x61cb  (22 bytes)
DATA_rotulo_61B5:
	defb 000h,020h,011h,008h,000h,007h,003h,001h,011h,005h,000h,080h,0c0h,0e0h,0f0h,078h	; 61b5  . .............x
	defb 03ch,01eh,00fh,011h,008h,000h	; 61c5

; ----------------------------------------------------------------------
; DATOS rotulo_61CB: Rotulo de letra grande.
;   0x61cb..0x61ea  (31 bytes)
DATA_rotulo_61CB:
	defb 000h,020h,000h,000h,000h,0ffh,0ffh,000h,000h,000h,007h,003h,001h,0ffh,0ffh,000h	; 61cb  . ..............
	defb 000h,000h,080h,0c0h,0e0h,0ffh,0ffh,011h,006h,000h,0ffh,0ffh,000h,000h,000h	; 61db  ...............

; ----------------------------------------------------------------------
; DATOS rotulo_61EA: Rotulo de letra grande.
;   0x61ea..0x61fb  (17 bytes)
DATA_rotulo_61EA:
	defb 000h,018h,011h,008h,000h,011h,005h,000h,0ffh,07fh,03fh,011h,005h,000h,0ffh,0ffh	; 61ea  ..........?.....
	defb 0ffh	; 61fa

; ----------------------------------------------------------------------
; DATOS rotulo_61FB: Rotulo de letra grande.
;   0x61fb..0x6210  (21 bytes)
DATA_rotulo_61FB:
	defb 000h,020h,011h,008h,000h,01fh,00fh,007h,003h,001h,000h,000h,000h,011h,006h,0ffh	; 61fb  . ..............
	defb 07fh,03fh,011h,008h,0ffh	; 620b

; ----------------------------------------------------------------------
; DATOS rotulo_6210: Rotulo de letra grande.
;   0x6210..0x6222  (18 bytes)
DATA_rotulo_6210:
	defb 000h,018h,011h,008h,000h,01fh,00fh,007h,003h,011h,004h,000h,011h,004h,0ffh,011h	; 6210  ................
	defb 004h,000h	; 6220

; ----------------------------------------------------------------------
; DATOS patrones_6222: Dos patrones de ocho bytes que SE PISAN EN UN BYTE: el
;   segundo empieza en el ultimo del primero.
;   0x6222..0x6231  (15 bytes)
DATA_patrones_6222:
	defb 0e9h,0e9h,0efh,0efh,0e9h,0e9h,0e9h,0e9h	; 6222  ........
	defb 0e9h,0e9h,0efh,0efh,0e9h,0e9h,0e9h	; 622a

; ----------------------------------------------------------------------
; DATOS rotulo_6231: Rotulo de letra grande.
;   0x6231..0x623f  (14 bytes)
DATA_rotulo_6231:
	defb 000h,010h,002h,011h,007h,000h,002h,000h,000h,080h,000h,004h,000h,000h	; 6231  ..............

; ----------------------------------------------------------------------
; DATOS patrones_623F: Dos patrones de ocho bytes.
;   0x623f..0x624f  (16 bytes)
DATA_patrones_623F:
	defb 089h,089h,0ffh,0ffh,089h,089h,089h,089h	; 623f  ........
	defb 089h,089h,089h,0ffh,0ffh,089h,089h,089h	; 6247  ........

; ----------------------------------------------------------------------
; DATOS rotulo_624F: Rotulo de letra grande.
;   0x624f..0x6260  (17 bytes)
DATA_rotulo_624F:
	defb 000h,010h,000h,001h,000h,001h,011h,004h,000h,008h,001h,000h,009h,000h,000h,004h	; 624f  ................
	defb 000h	; 625f

; ----------------------------------------------------------------------
; DATOS patron_6260: Un patron de ocho bytes.
;   0x6260..0x6268  (8 bytes)
DATA_patron_6260:
	defb 032h,0a2h,022h,032h,022h,022h,0a2h,022h	; 6260  2."2""."

; ----------------------------------------------------------------------
; DATOS rotulo_6268: Rotulo de letra grande.
;   0x6268..0x6276  (14 bytes)
DATA_rotulo_6268:
	defb 000h,010h,000h,001h,011h,007h,000h,001h,000h,080h,000h,000h,004h,000h	; 6268  ..............

; ----------------------------------------------------------------------
; DATOS rotulo_6276: Rotulo de letra grande.
;   0x6276..0x629e  (40 bytes)
DATA_rotulo_6276:
	defb 000h,030h,000h,011h,007h,003h,01ch,038h,070h,0e1h,0cdh,0cdh,0fdh,079h,000h,000h	; 6276  .0.....8p....y..
	defb 000h,0eeh,06bh,06bh,06bh,0ebh,000h,000h,000h,073h,01ah,07ah,05ah,07ah,000h,003h	; 6286  ..kkk....s.zZz..
	defb 000h,0f3h,011h,004h,05bh,011h,008h,000h	; 6296  ....[...

; ----------------------------------------------------------------------
; DATOS rotulo_629E: Rotulo de tipo 0: DECLARA 24 bytes y solo lleva 16 suyos;
;   los ocho que faltan los toma del bloque de detras, que es de donde 0x4CAB
;   saca los bits al estirar las letras.
;   0x629e..0x62b0  (18 bytes)
DATA_rotulo_629E:
	defb 000h,018h,0ffh,033h,033h,033h,0f0h,09ch,09ch,09ch,0ffh,033h,033h,033h,0f0h,09ch	; 629e  ...333.....333..
	defb 09ch,09ch	; 62ae

; ----------------------------------------------------------------------
; DATOS rotulo_62B0: Rotulo de tipo 0, con el mismo prestamo de ocho bytes.
;   0x62b0..0x62be  (14 bytes)
DATA_rotulo_62B0:
	defb 000h,018h,073h,073h,011h,005h,07ch,038h,073h,073h,011h,005h,07ch,038h	; 62b0  ..ss..|8ss..|8

; ----------------------------------------------------------------------
; DATOS rotulo_62BE: Rotulo de tipo 0, con el mismo prestamo de ocho bytes.
;   0x62be..0x62cc  (14 bytes)
DATA_rotulo_62BE:
	defb 000h,018h,0e3h,011h,005h,0c3h,081h,0ffh,0e3h,011h,005h,0c3h,081h,0ffh	; 62be  ..............

; ----------------------------------------------------------------------
; DATOS patrones_62CC: Tres patrones de ocho bytes que la orden 4 del guion
;   del marcador repite.
;   0x62cc..0x62e4  (24 bytes)
DATA_patrones_62CC:
	defb 0e0h,041h,04fh,04fh,097h,051h,05fh,05fh	; 62cc  .AOO.Q__
	defb 095h,095h,0f1h,07fh,07fh,07fh,074h,074h	; 62d4  ......tt
	defb 0f1h,071h,07bh,07bh,07bh,0edh,0edh,0b0h	; 62dc  .q{{{...

; ----------------------------------------------------------------------
; DATOS rotulo_62E4: Rotulo de letra grande.
;   0x62e4..0x62f8  (20 bytes)
DATA_rotulo_62E4:
	defb 011h,02dh,00ah,004h,00ah,005h,00ah,006h,00ah,007h,00ah,008h,00ah,009h,00ah,02eh	; 62e4  .-..............
	defb 00ah,02dh,02dh,0ffh	; 62f4

; ----------------------------------------------------------------------
; DATOS rotulo_62F8: Rotulo de tipo 0 que si cabe entero: ocho ceros y
;   dieciseis 0xFF, justo los 24 bytes que declara.
;   0x62f8..0x6300  (8 bytes)
DATA_rotulo_62F8:
	defb 000h,018h,011h,008h,000h,011h,010h,0ffh	; 62f8  ........

; ----------------------------------------------------------------------
; DATOS patrones_6300: Cuatro patrones de ocho bytes.
;   0x6300..0x6320  (32 bytes)
DATA_patrones_6300:
	defb 0c6h,039h,039h,039h,039h,028h,039h,028h	; 6300  .9999(9(
	defb 039h,028h,028h,039h,028h,028h,039h,028h	; 6308  9((9((9(
	defb 0c6h,028h,028h,028h,0c6h,0c6h,028h,0c6h	; 6310  .(((..(.
	defb 028h,0c6h,0c6h,0c6h,0c6h,0c6h,0c6h,0c6h	; 6318  (.......

; ----------------------------------------------------------------------
; DATOS rotulo_100_metros: "100 METER DASH" en letra grande, glifo a glifo.
;   0x6320..0x6332  (18 bytes)
DATA_rotulo_100_metros:
	defb 011h,00ah,001h,000h,000h,00ah,017h,00fh,01dh,00fh,01bh,00ah,00eh,00bh,01ch,012h	; 6320  ................
	defb 00ah,0ffh	; 6330

; ----------------------------------------------------------------------
; DATOS rotulo_400_metros: "400 METER DASH". Es el rotulo de arriba con el
;   primer glifo cambiado de 1 a 4: por eso la prueba 4 comparte decorado y
;   marcador con la 1.
;   0x6332..0x6344  (18 bytes)
DATA_rotulo_400_metros:
	defb 011h,00ah,004h,000h,000h,00ah,017h,00fh,01dh,00fh,01bh,00ah,00eh,00bh,01ch,012h	; 6332  ................
	defb 00ah,0ffh	; 6342

; ----------------------------------------------------------------------
; DATOS rotulo_salto_de_longitud: "LONG JUMP" en letra grande.
;   0x6344..0x6351  (13 bytes)
DATA_rotulo_salto_de_longitud:
	defb 011h,00ah,016h,019h,018h,011h,00ah,014h,01eh,017h,01ah,00ah,0ffh	; 6344  .............

; ----------------------------------------------------------------------
; DATOS rotulo_lanzamiento_de_martillo: "HAMMER THROW" en letra grande.
;   0x6351..0x6362  (17 bytes)
DATA_rotulo_lanzamiento_de_martillo:
	defb 011h,00ah,00ah,012h,00bh,017h,017h,00fh,01bh,00ah,01dh,012h,01bh,019h,020h,00ah	; 6351  .............. .
	defb 0ffh	; 6361

; ----------------------------------------------------------------------
; DATOS marco_del_marcador_grande: Guion largo de nueve ordenes que dibuja el
;   marco del marcador y sube los rotulos grandes de arriba.
;   0x6362..0x63c9  (103 bytes)
DATA_marco_del_marcador_grande:
	defb 009h,003h,008h,077h,000h,008h,001h,008h	; 6362  ...w....
	defb 080h,008h,0c0h,008h,0e0h,008h,0f0h,008h	; 636a  ........
	defb 0f8h,008h,0fch,008h,0feh,001h,002h,077h	; 6372  .......w
	defb 040h,01ch,01ah,00fh,00eh,02fh,030h,031h	; 637a  @..../01
	defb 032h,0ffh,077h,0d0h,024h,025h,01eh,0ffh	; 6382  2.w.$%..
	defb 002h,003h,068h,020h,09eh,062h,0b0h,062h	; 638a  ..h .b.b
	defb 0beh,062h,001h,001h,06fh,020h,01ah,016h	; 6392  .b..o ..
	defb 00bh,021h,00fh,01bh,011h,017h,019h,01fh	; 639a  .!......
	defb 02ah,02ah,0ffh,003h,002h,057h,000h,040h	; 63a2  **...W.@
	defb 0a4h,0c0h,0f0h,004h,048h,020h,008h,0cch	; 63aa  ....H ..
	defb 062h,004h,048h,060h,008h,0d4h,062h,004h	; 63b2  b.H`..b.
	defb 048h,0a0h,008h,0dch,062h,003h,003h,04fh	; 63ba  H...b..O
	defb 000h,070h,0f0h,008h,0f4h,008h,064h	; 63c2

; ----------------------------------------------------------------------
; DATOS pantallas_de_los_100_metros: Lista de nueve guiones largos: la pista,
;   las calles y el fondo de los 100 y los 400 metros.
;   0x63c9..0x6443  (122 bytes)
DATA_pantallas_de_los_100_metros:
	defb 009h,002h,002h,001h,068h,0e0h,09ah,061h	; 63c9  ....h..a
	defb 002h,002h,06ah,0a0h,04fh,062h,031h,062h	; 63d1  ..j.Ob1b
	defb 001h,002h,001h,06ch,0a0h,076h,062h,001h	; 63d9  ...l.vb.
	defb 003h,001h,048h,0e0h,060h,0f9h,003h,004h	; 63e1  ..H.`...
	defb 04ah,0a0h,004h,060h,062h,004h,04ah,0c0h	; 63e9  J..`b.J.
	defb 004h,03fh,062h,003h,003h,04ah,0e0h,060h	; 63f1  .?b..J.`
	defb 0f4h,060h,0f2h,000h,0f9h,001h,003h,003h	; 63f9  .`......
	defb 04ch,0a0h,000h,0f4h,000h,0f4h,080h,0f4h	; 6401  L.......
	defb 001h,002h,003h,070h,020h,09ah,061h,0b5h	; 6409  ...p .a.
	defb 061h,0cbh,061h,001h,002h,004h,076h,070h	; 6411  a.a...vp
	defb 031h,062h,031h,062h,031h,062h,04fh,062h	; 6419  1b1b1bOb
	defb 001h,003h,002h,050h,020h,000h,0f9h,020h	; 6421  ...P .. 
	defb 0f9h,004h,004h,056h,070h,004h,03fh,062h	; 6429  ...Vp.?b
	defb 003h,001h,056h,090h,020h,089h,004h,056h	; 6431  ..V. ..V
	defb 0b0h,004h,047h,062h,004h,056h,0d0h,004h	; 6439  ..Gb.V..
	defb 060h,062h	; 6441

; ----------------------------------------------------------------------
; DATOS marcador_de_los_100_metros: Guion corto del marcador de las pruebas de
;   tiempo.
;   0x6443..0x648d  (74 bytes)
DATA_marcador_de_los_100_metros:
	defb 079h,060h,0feh,021h,0a8h,0eeh,0eeh,0eeh	; 6443  y`.!....
	defb 0feh,03ch,0a8h,0feh,020h,057h,0feh,020h	; 644b  .<.. W. 
	defb 05bh,0d5h,0d5h,0f2h,0fch,0e9h,0feh,01bh	; 6453  [.......
	defb 0d5h,0feh,020h,0d9h,000h,0f2h,0fch,0e9h	; 645b  .. .....
	defb 0feh,005h,000h,0ech,0edh,0eeh,0fah,0fbh	; 6463  ........
	defb 0feh,004h,000h,0f1h,0fch,0e9h,0feh,005h	; 646b  ........
	defb 000h,0ech,0edh,0eeh,0fah,0fbh,000h,0feh	; 6473  ........
	defb 040h,0ddh,0feh,020h,0d1h,0d5h,0d5h,0f1h	; 647b  @.. ....
	defb 0fch,0e9h,0feh,01bh,0d5h,0feh,020h,0d9h	; 6483  ...... .
	defb 0ffh,0ffh	; 648b

; ----------------------------------------------------------------------
; DATOS pantallas_de_longitud_y_martillo: Lista de trece guiones largos: el
;   foso, el circulo y el fondo de las dos pruebas de distancia.
;   0x648d..0x65ba  (301 bytes)
DATA_pantallas_de_longitud_y_martillo:
	defb 00dh,002h,002h,002h,068h,0e0h,04fh,062h	; 648d  ....h.Ob
	defb 076h,062h,001h,001h,06eh,0e0h,010h,019h	; 6495  vb..n...
	defb 01eh,016h,0ffh,003h,004h,048h,0e0h,004h	; 649d  .....H..
	defb 060h,062h,003h,009h,049h,000h,000h,0f4h	; 64a5  `b..I...
	defb 000h,0f4h,001h,099h,001h,0ffh,001h,099h	; 64ad  ........
	defb 001h,0ffh,001h,099h,001h,0ffh,002h,099h	; 64b5  ........
	defb 003h,001h,04eh,0e0h,020h,091h,001h,002h	; 64bd  ..N. ...
	defb 008h,070h,020h,09ah,061h,0b5h,061h,0cbh	; 64c5  .p .a.a.
	defb 061h,0eah,061h,0fbh,061h,0fbh,061h,0fbh	; 64cd  a.a.a.a.
	defb 061h,010h,062h,001h,002h,001h,072h,0e0h	; 64d5  a.b...r.
	defb 0e4h,062h,001h,002h,005h,075h,008h,031h	; 64dd  .b...u.1
	defb 062h,031h,062h,031h,062h,04fh,062h,068h	; 64e5  b1b1bObh
	defb 062h,002h,002h,001h,075h,068h,04fh,062h	; 64ed  b...uhOb
	defb 002h,004h,076h,000h,0f8h,062h,0f8h,062h	; 64f5  ..v..b.b
	defb 0f8h,062h,0f8h,062h,001h,000h,001h,075h	; 64fd  .b.b...u
	defb 0b0h,040h,011h,004h,000h,07fh,0ffh,011h	; 6505  .@......
	defb 00ch,0c0h,0ffh,07fh,011h,008h,000h,0ffh	; 650d  ........
	defb 0ffh,011h,004h,000h,0ffh,0ffh,011h,008h	; 6515  ........
	defb 000h,0feh,0ffh,003h,003h,063h,093h,093h	; 651d  .....c..
	defb 063h,011h,006h,003h,0ffh,0feh,011h,004h	; 6525  c.......
	defb 000h,001h,003h,003h,050h,020h,000h,0f9h	; 652d  ....P ..
	defb 020h,0f9h,040h,0f2h,004h,004h,051h,080h	; 6535   .@...Q.
	defb 00ch,022h,062h,003h,001h,051h,0e0h,060h	; 653d  ."b..Q.`
	defb 0e9h,004h,052h,040h,00ch,029h,062h,003h	; 6545  ..R@.)b.
	defb 001h,052h,0a0h,040h,0f2h,001h,003h,009h	; 654d  .R.@....
	defb 052h,0e0h,008h,02fh,070h,07fh,018h,02fh	; 6555  R../p../
	defb 070h,07fh,018h,02fh,070h,07fh,018h,02fh	; 655d  p../p../
	defb 070h,07fh,010h,02fh,005h,004h,055h,008h	; 6565  p../..U.
	defb 004h,03fh,062h,003h,001h,055h,028h,020h	; 656d  .?b..U( 
	defb 089h,004h,055h,048h,004h,047h,062h,004h	; 6575  ..UH.Gb.
	defb 055h,068h,004h,060h,062h,003h,001h,055h	; 657d  Uh.`b..U
	defb 088h,020h,05eh,004h,004h,056h,000h,008h	; 6585  . ^..V..
	defb 000h,063h,004h,056h,040h,008h,008h,063h	; 658d  .c.V@..c
	defb 004h,056h,080h,008h,010h,063h,004h,056h	; 6595  .V...c.V
	defb 0c0h,008h,018h,063h,001h,003h,00ah,055h	; 659d  ...c...U
	defb 0a8h,008h,055h,006h,079h,00ch,070h,006h	; 65a5  ..U.y.p.
	defb 072h,006h,079h,004h,000h,006h,072h,006h	; 65ad  r.y...r.
	defb 079h,00ch,070h,006h,072h	; 65b5

; ----------------------------------------------------------------------
; DATOS marcador_del_salto_de_longitud: Guion corto con la columna de intentos
;   y el rotulo de metros.
;   0x65ba..0x6603  (73 bytes)
DATA_marcador_del_salto_de_longitud:
	defb 079h,060h,0feh,060h,038h,0feh,020h,01fh	; 65ba  y`.`8. .
	defb 0feh,020h,060h,0feh,020h,0b0h,0feh,020h	; 65c2  . `. .. 
	defb 0b0h,0feh,020h,0a4h,0feh,020h,0a8h,0feh	; 65ca  .. .. ..
	defb 004h,0ach,0b6h,0b9h,0b9h,0bbh,0feh,018h	; 65d2  ........
	defb 0ach,0feh,004h,0b0h,0b7h,0f2h,0f0h,0bch	; 65da  ........
	defb 0feh,018h,0b0h,0feh,004h,0b0h,0b8h,0bah	; 65e2  ........
	defb 0bah,0bdh,0feh,018h,0b0h,0ffh,07ah,0e0h	; 65ea  ......z.
	defb 000h,0e8h,0e9h,0eah,0eah,0ebh,0efh,0feh	; 65f2  ........
	defb 014h,000h,0ech,0edh,0eeh,0fah,0fbh,0ffh	; 65fa  ........
	defb 0ffh	; 6602

; ----------------------------------------------------------------------
; DATOS marcador_del_martillo: Guion corto del marcador del lanzamiento.
;   0x6603..0x6657  (84 bytes)
DATA_marcador_del_martillo:
	defb 079h,060h,0feh,0a0h,038h,0feh,014h,0b5h	; 6603  y`..8...
	defb 0b6h,0b9h,0b9h,0bbh,0feh,008h,0b5h,0feh	; 660b  ........
	defb 014h,0b5h,0b7h,0f2h,0f0h,0bch,0feh,008h	; 6613  ........
	defb 0b5h,0feh,014h,0b5h,0b8h,0bah,0bah,0bdh	; 661b  ........
	defb 0feh,008h,0b5h,0feh,00ah,0c0h,0c0h,0c1h	; 6623  ........
	defb 0feh,014h,0c1h,0feh,00ah,0c8h,0c8h,0c9h	; 662b  ........
	defb 0feh,014h,0c9h,0feh,00ah,0d0h,0d0h,0d1h	; 6633  ........
	defb 0feh,014h,0d1h,0feh,00ah,0d8h,0d8h,0d9h	; 663b  ........
	defb 0feh,014h,0d9h,000h,0e8h,0e9h,0eah,0eah	; 6643  ........
	defb 0ebh,0efh,0feh,014h,000h,0ech,0edh,0eeh	; 664b  ........
	defb 0fah,0fbh,0ffh,0ffh	; 6653

; ----------------------------------------------------------------------
; DATOS pizarra_de_los_100_metros: Guion largo de una orden: pone "100 METER
;   DASH" en la pizarra.
;   0x6657..0x665e  (7 bytes)
DATA_pizarra_de_los_100_metros:
	defb 001h,002h,001h,06dh,040h,020h,063h	; 6657

; ----------------------------------------------------------------------
; DATOS pizarra_del_salto_de_longitud: Guion largo de una orden: "LONG JUMP".
;   0x665e..0x6665  (7 bytes)
DATA_pizarra_del_salto_de_longitud:
	defb 001h,002h,001h,069h,0c0h,044h,063h	; 665e

; ----------------------------------------------------------------------
; DATOS pizarra_del_martillo: Guion largo de tres ordenes: "HAMMER THROW" y
;   dos rellenos.
;   0x6665..0x6688  (35 bytes)
DATA_pizarra_del_martillo:
	defb 003h,002h,001h,069h,0c0h,051h,063h,003h,003h,049h,000h,000h,0f5h,000h,0f5h,000h	; 6665  ...i.Qc..I......
	defb 0f5h,003h,007h,055h,0b0h,006h,075h,00ch,070h,00ch,075h,004h,000h,00ch,075h,00ch	; 6675  ...U..u.p.u...u.
	defb 070h,006h,075h	; 6685

; ----------------------------------------------------------------------
; DATOS pizarra_de_los_400_metros: Guion largo de una orden: "400 METER DASH".
;   0x6688..0x668f  (7 bytes)
DATA_pizarra_de_los_400_metros:
	defb 001h,002h,001h,06dh,040h,032h,063h	; 6688

; ======================================================================
; CODIGO 0x668f..0x6a6a  (987 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  MOTOR DEL SALTO DE LONGITUD  ==========
; Aqui el atleta corre, salta y cae. La carrera reaprovecha el motor de
; los 100 metros; lo propio de la prueba es el tiro, que sale del trozo
; de 0x7D2C, y la caida.
; ----------------------------------------------------------------------
MOTOR_DEL_SALTO:
	ld a,(0e02eh)		;668f
	bit 1,a		;6692   ; bit 1 de 0xE02E: la prueba ya acabo
	ret nz			;6694
	ld a,(0e020h)		;6695   ; bit 2 de 0xE020: el salto esta en el aire
	bit 2,a		;6698
	jr nz,SALTO_EN_EL_AIRE		;669a
	ld a,(0e02ch)		;669c   ; bit 0 de 0xE02C: el intento ha terminado
	rrca			;669f
	jp c,MARCA_EL_FIN_DEL_VUELO		;66a0
	call BOTON_DEL_QUE_JUEGA		;66a3   ; el boton del que juega
	ld a,(0e017h)		;66a6   ; en la demo no se hace caso al boton
	or a			;66a9
	ld a,000h		;66aa
	jr nz,GUARDA_LA_PULSACION		;66ac
	ld a,(hl)			;66ae
GUARDA_LA_PULSACION:
	ld (0e0c5h),a		;66af   ; queda apuntado
	ld hl,0e0adh		;66b2   ; gasta la velocidad
	call GASTA_Y_APUNTA		;66b5
	ld de,0e0b8h		;66b8   ; y la convierte en avance
	call MULTIPLICA_LA_VELOCIDAD		;66bb
	call PINTA_A_LOS_DOS_ATLETAS		;66be   ; pinta a los dos atletas
	call MUEVE_LA_TABLA_DE_BATIDA		;66c1   ; mueve la tabla de batida
	ld hl,02014h		;66c4   ; sonido de fondo 0x14/0x20
	ld (0e032h),hl		;66c7
	ld a,(0e020h)		;66ca
	bit 2,a		;66cd   ; sin salto en el aire se acaba aqui
	ret z			;66cf
	ld de,0e206h		;66d0   ; la posicion del objeto que vuela
	call FICHA_DEL_QUE_JUEGA		;66d3
	ld a,(hl)			;66d6
	ld (de),a			;66d7
	inc hl			;66d8
	inc de			;66d9
	ld a,(hl)			;66da
	ld (de),a			;66db
	ld de,07b78h		;66dc   ; la fila de sprites del salto
	call FIJA_ESCRITURA_CON_CANDADO		;66df
	ld a,(00006h)		;66e2
	ld c,a			;66e5
	ld a,09ch		;66e6   ; fila 0x9C
	out (c),a		;66e8
	ld a,(hl)			;66ea
	add a,004h		;66eb   ; y la columna, cuatro mas alla
	out (c),a		;66ed
	ld b,a			;66ef
	ld a,(0e15ch)		;66f0   ; la columna del segundo objeto
	cp b			;66f3
	call c,ACABA_EL_INTENTO		;66f4   ; si se pasa, se acabo el salto
	ld hl,07992h		;66f7   ; el patron en blanco
	ld de,05bc0h		;66fa   ; al sprite de 0x1BC0
	call SUBE_UN_PATRON_DE_SPRITE		;66fd
	ld a,001h		;6700   ; sonido 1
	jp PIDE_UN_SONIDO		;6702
SALTO_EN_EL_AIRE:
	ld hl,0e200h		;6705
	bit 2,(hl)		;6708   ; bit 2 de 0xE200: ya se ha contado
	jr nz,MIRA_SI_YA_CAYO		;670a
	push hl			;670c
	call CUENTA_EL_ANGULO		;670d   ; cuenta el angulo
	pop hl			;6710
	jr nz,MIRA_SI_YA_CAYO		;6711
	set 2,(hl)		;6713   ; y se marca
MIRA_SI_YA_CAYO:
	bit 0,(hl)		;6715   ; bit 0 de 0xE200: ya ha caido
	jp nz,ESPERA_TRAS_LA_CAIDA		;6717
	exx			;671a
	ld bc,06415h		;671b   ; patron 0x15 y color 0x64
	ld d,057h		;671e   ; columna 0x57
	ld a,(0e02ch)		;6720
	rrca			;6723
	jr nc,CUENTA_LOS_CUADROS_DEL_VUELO		;6724
	ld d,05bh		;6726   ; o 0x5B en las pruebas impares
CUENTA_LOS_CUADROS_DEL_VUELO:
	exx			;6728
	ld hl,0e201h		;6729   ; el contador del vuelo
	inc (hl)			;672c
	bit 1,(hl)		;672d   ; uno de cada dos cuadros
	ret z			;672f
	ld (hl),000h		;6730
	call AVANZA_EL_TIRO		;6732   ; avanza el tiro
	call COLUMNA_DEL_QUE_JUEGA		;6735   ; la columna del atleta
	ld a,(hl)			;6738
	add a,004h		;6739   ; cuatro columnas mas
	ld b,a			;673b
	ld a,(0e15ch)		;673c   ; contra la del objeto
	sub b			;673f
	jr c,PINTA_EL_VUELO		;6740
	xor a			;6742
	ld h,a			;6743   ; y si lo pasa, se para el tiro
	ld l,a			;6744
	ld (0e110h),hl		;6745
	ld (0e112h),a		;6748
PINTA_EL_VUELO:
	ld hl,(0e11ah)		;674b   ; la posicion del vuelo
	ld (0e030h),hl		;674e
	call FICHA_DEL_QUE_JUEGA		;6751   ; la ficha del que juega
	ex de,hl			;6754
	ld hl,0e206h		;6755
	ld a,(0e116h)		;6758   ; la altura, cambiada de signo
	neg		;675b
	add a,(hl)			;675d
	ld (de),a			;675e
	inc hl			;675f
	inc de			;6760
	ld a,(0e114h)		;6761   ; y el avance
	add a,(hl)			;6764
	ld (de),a			;6765
	ld hl,0e106h		;6766   ; la velocidad vertical
	ld d,(hl)			;6769
	inc hl			;676a
	ld e,(hl)			;676b
	ld c,012h		;676c   ; color 0x12
	ld hl,0fc00h		;676e   ; por debajo de 0xFC00
	sbc hl,de		;6771
	jr nc,MIRA_SI_EL_TIRO_SUBE		;6773
	ld a,002h		;6775   ; modo 2 de la musica: el silbido de bajada
	ld (0e190h),a		;6777
	jr PINTA_Y_MIRA_LA_CAIDA		;677a
MIRA_SI_EL_TIRO_SUBE:
	ld hl,00400h		;677c   ; y por encima de 0x400
	sbc hl,de		;677f
	jr nc,PINTA_Y_MIRA_LA_CAIDA		;6781
	inc c			;6783   ; color 0x13 si sube
	bit 7,d		;6784
	jr nz,PINTA_Y_MIRA_LA_CAIDA		;6786
	dec c			;6788   ; o 0x11 si baja
	dec c			;6789
PINTA_Y_MIRA_LA_CAIDA:
	call PINTA_EL_OBJETO_QUE_VUELA		;678a   ; pinta el objeto
	ld a,(0e116h)		;678d
	cp 0f5h		;6790   ; por encima de 0xF5 de altura, aun vuela
	ret c			;6792
	ld a,04fh		;6793   ; sonido 0x4F: el aterrizaje
	call PIDE_UN_SONIDO		;6795
	xor a			;6798
	ld (0e190h),a		;6799   ; musica normal otra vez
	call COLUMNA_DEL_QUE_JUEGA		;679c
	ld a,(hl)			;679f   ; la columna del atleta
	add a,010h		;67a0
	ld b,a			;67a2   ; mas 0x10
	ld a,(0e15ch)		;67a3
	sub b			;67a6
	jr nc,SE_ACABO_EL_SALTO		;67a7   ; contra la del objeto
	cp 0e0h		;67a9
	jr c,MARCA_EL_FIN_DEL_VUELO		;67ab
SE_ACABO_EL_SALTO:
	call ACABA_EL_INTENTO		;67ad
MARCA_EL_FIN_DEL_VUELO:
	ld hl,0e200h		;67b0
	bit 0,(hl)		;67b3   ; bit 0 de 0xE200: ya estaba marcado
	jr nz,ESPERA_TRAS_LA_CAIDA		;67b5
	set 0,(hl)		;67b7
	inc hl			;67b9
	ld (hl),010h		;67ba   ; 0x10 cuadros de espera
	ret			;67bc
PINTA_EL_OBJETO_QUE_VUELA:
	call POSTURA_DEL_QUE_JUEGA		;67bd   ; la casilla del color
	ld (hl),c			;67c0
	ld a,b			;67c1
	jp PINTA_AL_ATLETA		;67c2
ESPERA_TRAS_LA_CAIDA:
	ld hl,0e200h		;67c5
	bit 3,(hl)		;67c8   ; bit 3 de 0xE200: ya se espero
	jp nz,ANIMACION_FINAL		;67ca
	inc hl			;67cd
	dec (hl)			;67ce   ; la cuenta
	ret nz			;67cf
	dec hl			;67d0
	set 3,(hl)		;67d1   ; se marca
	call ACABA_EL_INTENTO_Y_ANIMA		;67d3   ; la casilla de la animacion
	ld (hl),080h		;67d6   ; 0x80: la cuenta de la animacion final
	ret			;67d8
CUENTA_EL_ANGULO:
	call BOTON_DEL_QUE_JUEGA		;67d9   ; el boton del que juega
	bit 1,(hl)		;67dc   ; sin pulsar no sube
	ret z			;67de
	ld hl,0e033h		;67df   ; el angulo en BCD
	ld a,(hl)			;67e2
	inc a			;67e3
	daa			;67e4
	ld (hl),a			;67e5
	dec hl			;67e6
	inc (hl)			;67e7   ; y su cuenta en binario
	ld a,(hl)			;67e8
	cp 050h		;67e9   ; el tope son 50 grados
	ret			;67eb
MUEVE_LA_TABLA_DE_BATIDA:
	ld a,(0e000h)		;67ec
	rrca			;67ef   ; solo en los cuadros pares
	ret c			;67f0
	call BOTON_DEL_QUE_JUEGA		;67f1   ; el boton del que juega
	ld a,(hl)			;67f4
	ld hl,0e21eh		;67f5   ; la cuenta de la tabla
	or a			;67f8
	jr z,GASTA_LA_CUENTA		;67f9   ; con el boton pulsado se reinicia
	xor a			;67fb
	ld (hl),a			;67fc
	inc hl			;67fd
	ld (hl),a			;67fe
	dec hl			;67ff
GASTA_LA_CUENTA:
	dec (hl)			;6800
	ret nz			;6801   ; mientras quede, nada
	inc hl			;6802
	ld a,(hl)			;6803   ; la fase de la tabla
	or a			;6804
	jr nz,SE_ACABO_LA_TABLA		;6805
	ld (hl),001h		;6807   ; primera fase
	dec hl			;6809
	ld (hl),040h		;680a   ; 0x40 cuadros
	ld a,004h		;680c   ; sonido 4: el crujido de la tabla
	jp PIDE_UN_SONIDO		;680e
SE_ACABO_LA_TABLA:
	ld hl,0e02ch		;6811
	set 0,(hl)		;6814   ; bit 0 de 0xE02C: intento acabado
	ret			;6816
SUBE_EL_PATRON_DEL_OBJETO:
	ld a,(0e106h)		;6817
	rlca			;681a   ; con el bit alto de la altura puesto
	jr nc,PATRON_4_DEL_OBJETO		;681b
	ld a,002h		;681d
	ld (0e190h),a		;681f   ; modo 2 de la musica
PATRON_4_DEL_OBJETO:
	ld a,004h		;6822   ; patron 4 del objeto
	ld (0e20ah),a		;6824
SUBE_UN_PATRON_DEL_OBJETO:
	ld a,(0e20ah)		;6827   ; que patron toca
	ld hl,0794dh		;682a   ; la tabla de patrones del objeto
	rlca			;682d
	call SUMA_A_A_HL		;682e
	ld e,(hl)			;6831   ; el puntero
	inc hl			;6832
	ld d,(hl)			;6833
	ld hl,05800h		;6834   ; al sprite de 0x1800
	ex de,hl			;6837
	call SUBE_UN_PATRON_DE_SPRITE		;6838   ; y se sube comprimido
	ld hl,0e208h		;683b   ; la fila y la columna del objeto
	ld de,07b00h		;683e   ; a la tabla de atributos
	ld b,002h		;6841
	call SUBE_BYTES_CON_DIRECCION		;6843
	ret			;6846
MUEVE_EL_SALTO:
	ld a,(0e200h)		;6847   ; con 0xE200 a cero aun no ha saltado
	or a			;684a
	jr nz,AVANZA_EL_VUELO		;684b
	call CUENTA_EL_ANGULO		;684d   ; cuenta el angulo con el boton
	jr nz,AVANZA_EL_VUELO		;6850
	ld a,001h		;6852   ; y a partir de ahi ya esta en el aire
	ld (0e200h),a		;6854
AVANZA_EL_VUELO:
	exx			;6857
	ld bc,06660h		;6858   ; sonido de fondo del vuelo
	ld d,01ch		;685b
	exx			;685d
	ld a,(0e000h)		;685e   ; solo en los cuadros impares
	rrca			;6861
	jr nc,MIRA_SI_TERMINA_EL_SALTO		;6862
	call AVANZA_EL_TIRO		;6864   ; avanza el tiro
	call FICHA_DEL_QUE_JUEGA		;6867   ; la ficha del que juega
	ex de,hl			;686a
	ld hl,0e117h		;686b
	ld a,(de)			;686e   ; con la fila en 0xCF ya esta en el suelo
	cp 0cfh		;686f
	jr z,SUMA_EL_AVANCE_DEL_VUELO		;6871
	inc de			;6873
	ld a,(de)			;6874
	sub (hl)			;6875   ; le resta la altura del cuadro
	ld (de),a			;6876
	jr nc,SUMA_EL_AVANCE_DEL_VUELO		;6877
	dec de			;6879
	ld a,0cfh		;687a   ; y si se pasa, se planta en el suelo
	ld (de),a			;687c
SUMA_EL_AVANCE_DEL_VUELO:
	ld de,0e141h		;687d   ; la columna del primer objeto
	ld a,(de)			;6880
	add a,(hl)			;6881
	ld (de),a			;6882
	ld hl,0e201h		;6883   ; el contador del vuelo
	ld a,(0e116h)		;6886   ; el avance acumulado
	sub (hl)			;6889
	neg		;688a
	ld (0e208h),a		;688c   ; da la columna del atleta
	cp 0f0h		;688f   ; fuera del tramo 0x98..0xEF
	jr nc,CAMBIA_EL_PATRON_DEL_OBJETO		;6891
	cp 098h		;6893
	jr nc,GUARDA_EL_AVANCE		;6895
CAMBIA_EL_PATRON_DEL_OBJETO:
	call SUBE_EL_PATRON_DEL_OBJETO		;6897   ; se cambia el patron del objeto
GUARDA_EL_AVANCE:
	ld a,(0e02ch)		;689a
	rrca			;689d   ; bit 0 de 0xE02C: intento acabado
	jr c,MIRA_SI_TERMINA_EL_SALTO		;689e
	ld hl,(0e11ah)		;68a0   ; el avance del cuadro
	ld (0e030h),hl		;68a3
MIRA_SI_TERMINA_EL_SALTO:
	call PINTA_A_LOS_DOS_ATLETAS		;68a6   ; pinta a los dos atletas
	ld a,(0e116h)		;68a9   ; el avance acumulado
	cp 0e0h		;68ac   ; por debajo de 0xE0 no ha caido
	ret c			;68ae
	cp 0eah		;68af   ; y por encima de 0xEA tampoco
	ccf			;68b1
	ret			;68b2

; ----------------------------------------------------------------------
; ==========  MOTOR DEL LANZAMIENTO DE MARTILLO  ==========
; El atleta da vueltas al martillo mientras se pulsa el boton, y al
; soltarlo lo suelta con el angulo que marque la flecha. El vuelo lo
; calcula el mismo trozo de 0x7D2C que el salto de longitud.
; ----------------------------------------------------------------------
MOTOR_DEL_MARTILLO:
	ld a,(0e02eh)		;68b3
	bit 1,a		;68b6   ; bit 1 de 0xE02E: la prueba ya acabo
	ret nz			;68b8
	ld a,(0e206h)		;68b9   ; con 0xE206 puesto ya esta lanzando
	or a			;68bc
	jr nz,MIRA_LA_FASE_DEL_LANZAMIENTO		;68bd
	call FICHA_DEL_QUE_JUEGA		;68bf   ; la ficha del que juega
	ld a,b			;68c2
	call PINTA_AL_ATLETA		;68c3   ; lo pinta
	ld hl,03088h		;68c6   ; el martillo empieza en fila 0x88, columna 0x30
	ld (0e208h),hl		;68c9
	ld a,001h		;68cc   ; patron 1 del objeto
	ld (0e20ah),a		;68ce
	call SUBE_UN_PATRON_DEL_OBJETO		;68d1   ; y se sube
	ld a,(0e017h)		;68d4   ; en la demo se acaba aqui
	or a			;68d7
	ret nz			;68d8
	call MUEVE_LA_TABLA_DE_BATIDA		;68d9   ; cuenta el angulo con el boton
	ld a,(0e02ch)		;68dc   ; bit 0 de 0xE02C: intento acabado
	rrca			;68df
	jr c,MIRA_LA_FASE_DEL_LANZAMIENTO		;68e0
	ld hl,02014h		;68e2   ; sonido de fondo del giro
	ld (0e032h),hl		;68e5
	ld hl,00405h		;68e8   ; fase 4 y cuenta 5 del giro
	ld (0e210h),hl		;68eb
	ld a,020h		;68ee   ; y 0x20 cuadros de giro
	ld (0e214h),a		;68f0
	call BOTON_DEL_QUE_JUEGA		;68f3   ; el boton del que juega
	bit 0,(hl)		;68f6   ; sin pulsar no se lanza
	ret z			;68f8
	ld a,001h		;68f9   ; a partir de aqui esta lanzando
	ld (0e206h),a		;68fb
	ld hl,0e0aeh		;68fe   ; velocidad inicial 0x05F4, distancia 1
	ld (hl),005h		;6901
	inc hl			;6903
	ld (hl),0f4h		;6904
	inc hl			;6906
	ld (hl),001h		;6907
MIRA_LA_FASE_DEL_LANZAMIENTO:
	ld a,(0e207h)		;6909   ; la fase
	cp 001h		;690c
	jp z,ESPERA_A_QUE_ACABE_EL_GOLPE		;690e   ; fase 1: el martillo vuela
	cp 002h		;6911
	jp z,ANIMACION_FINAL		;6913   ; fase 2: ya cayo
	ld a,(0e02ch)		;6916   ; bit 0 de 0xE02C
	rrca			;6919
	jp c,GIRA_UNA_VUELTA		;691a
	ld hl,0e020h		;691d
	bit 2,(hl)		;6920   ; bit 2 de 0xE020: el martillo esta en el aire
	jp nz,ANIMA_LA_CAIDA		;6922
	ld hl,0e212h		;6925   ; la vuelta que lleva
	ld a,(hl)			;6928
	cp 007h		;6929   ; con siete vueltas se acabo
	jp nz,GIRA_EL_MARTILLO		;692b
ACABA_EL_INTENTO:
	ld hl,0e02ch		;692e
	set 0,(hl)		;6931   ; bit 0 de 0xE02C
	ret			;6933
GIRA_EL_MARTILLO:
	call BOTON_DEL_QUE_JUEGA		;6934   ; el boton del que juega
	bit 1,(hl)		;6937
	jp z,CUENTA_LA_VUELTA		;6939   ; al soltarlo, se suelta el martillo
	ld hl,0e020h		;693c
	set 2,(hl)		;693f   ; bit 2 de 0xE020: el martillo sale despedido
	ld hl,0e211h		;6941   ; el giro que lleva
	ld a,(hl)			;6944
	inc hl			;6945
	cp 018h		;6946   ; por debajo de 0x18 el lanzamiento no vale
	jr c,ACABA_EL_INTENTO		;6948
	ld a,001h		;694a   ; sonido 1
	call PIDE_UN_SONIDO		;694c
	push hl			;694f
	ld hl,(0e208h)		;6950   ; la posicion del martillo
	ld l,07ch		;6953   ; fila 0x7C
	ld (0e201h),hl		;6955
	pop hl			;6958
	ld a,(hl)			;6959   ; la vuelta en la que se solto
	cp 006h		;695a   ; con seis vueltas
	ret nz			;695c
	inc hl			;695d
	ld (hl),001h		;695e   ; se pasa a la septima
	jr ACABA_EL_INTENTO		;6960
ANIMA_LA_CAIDA:
	call POSTURA_DEL_QUE_JUEGA		;6962   ; la casilla de la animacion
	ld (hl),018h		;6965   ; 0x18 cuadros
	call MUEVE_EL_SALTO		;6967   ; y a mover el vuelo
	ret c			;696a   ; mientras no caiga, se sigue
	ld a,04fh		;696b   ; sonido 0x4F: el impacto
	call PIDE_UN_SONIDO		;696d
	xor a			;6970
	ld (0e190h),a		;6971   ; musica normal
PASA_A_LA_FASE_1:
	ld a,001h		;6974
	ld (0e207h),a		;6976
ESPERA_A_QUE_ACABE_EL_GOLPE:
	ld a,(0e178h)		;6979   ; mientras el canal 3 suene, se espera
	or a			;697c
	ret nz			;697d
	ld a,002h		;697e   ; fase 2
	ld (0e207h),a		;6980
	call ACABA_EL_INTENTO_Y_ANIMA		;6983   ; la casilla de la animacion final
	ld (hl),080h		;6986   ; 0x80 cuadros
ANIMACION_FINAL:
	ld a,(0e02ah)		;6988
	or a			;698b   ; sin resultado no hay animacion
	ret z			;698c
	push af			;698d
	call CUENTA_DE_ANIMACION		;698e   ; la cuenta del jugador que juega
	pop af			;6991
	jp ANIMA_LA_LLEGADA		;6992   ; y a animarla
GIRA_UNA_VUELTA:
	ld a,(0e213h)		;6995   ; con 0xE213 puesto ya se solto
	or a			;6998
	jp nz,ANIMA_LA_CAIDA		;6999
	ld hl,0e215h		;699c   ; la cuenta del cambio de figura
	ld a,(hl)			;699f
	or a			;69a0
	jr nz,GASTA_LA_CUENTA_DEL_GIRO		;69a1
	ld (hl),001h		;69a3   ; se marca
	call FICHA_DEL_QUE_JUEGA		;69a5   ; la ficha del que juega
	ex de,hl			;69a8
	ld a,(0e211h)		;69a9   ; la fase del giro
	and 01ch		;69ac   ; tres bits
	rrca			;69ae
	rrca			;69af
	ld hl,06a8ah		;69b0   ; la tabla de desplazamientos del martillo
	call SUMA_A_A_HL		;69b3
	ld de,0e208h		;69b6
	ld a,(de)			;69b9   ; se suma a la fila
	add a,(hl)			;69ba
	ld (de),a			;69bb
	inc hl			;69bc
	inc de			;69bd
	ld a,(de)			;69be   ; y a la columna
	add a,(hl)			;69bf
	ld (de),a			;69c0
	inc de			;69c1
	ld a,001h		;69c2   ; patron 1
	ld (de),a			;69c4
	jp SUBE_UN_PATRON_DEL_OBJETO		;69c5
GASTA_LA_CUENTA_DEL_GIRO:
	dec hl			;69c8
	dec (hl)			;69c9   ; la cuenta
	ret nz			;69ca
	ld (hl),020h		;69cb   ; 0x20 cuadros por figura
	inc hl			;69cd
	ld a,(hl)			;69ce   ; la figura
	inc a			;69cf
	cp 003h		;69d0
	jp z,PASA_A_LA_FASE_1		;69d2   ; con tres se pasa a la fase 1
	ld (hl),a			;69d5
	ld hl,0e208h		;69d6   ; la posicion del martillo
	ld a,(hl)			;69d9
	add a,008h		;69da   ; ocho columnas
	ld (hl),a			;69dc
	inc hl			;69dd
	ld a,(hl)			;69de   ; y catorce filas menos
	sub 00eh		;69df
	ld (hl),a			;69e1
	inc hl			;69e2
	ld (hl),000h		;69e3
	jp SUBE_UN_PATRON_DEL_OBJETO		;69e5
CUENTA_LA_VUELTA:
	ld hl,0e210h		;69e8   ; la cuenta del giro
	dec (hl)			;69eb
	jr nz,CUENTA_LOS_ESCALONES		;69ec
	push hl			;69ee
	inc hl			;69ef
	inc (hl)			;69f0   ; la fase del giro
	ld a,(hl)			;69f1
	cp 020h		;69f2   ; con 0x20 se completa la vuelta
	jr nz,SUMA_LO_QUE_DA_LA_VUELTA		;69f4
	ld (hl),000h		;69f6
	ld a,045h		;69f8   ; sonido 0x45: el zumbido
	call PIDE_UN_SONIDO		;69fa
	inc hl			;69fd   ; y una vuelta mas
	inc (hl)			;69fe
SUMA_LO_QUE_DA_LA_VUELTA:
	ld hl,06a82h		;69ff   ; la tabla de figuras del paso
	pop de			;6a02
	ld a,(0e212h)		;6a03   ; la vuelta que lleva
	push af			;6a06
	call SUMA_A_A_HL		;6a07
	ld a,(hl)			;6a0a
	ld (de),a			;6a0b
	ld de,0e0adh		;6a0c   ; la marca del jugador 1
	ld hl,06a7ah		;6a0f   ; y la tabla de lo que suma
	pop af			;6a12
	call SUMA_A_A_HL		;6a13
	ex de,hl			;6a16
	ld a,(de)			;6a17   ; se suma en BCD
	add a,(hl)			;6a18
	daa			;6a19
	ld (hl),a			;6a1a
	inc hl			;6a1b
	ld a,(hl)			;6a1c
	adc a,000h		;6a1d
	daa			;6a1f
	ld (hl),a			;6a20
	inc hl			;6a21
	ld a,(de)			;6a22   ; y la distancia en binario
	add a,(hl)			;6a23
	ld (hl),a			;6a24
	inc hl			;6a25
	ld a,(hl)			;6a26
	adc a,000h		;6a27
	ld (hl),a			;6a29
CUENTA_LOS_ESCALONES:
	ld de,0e211h		;6a2a   ; la fase del giro
	ld c,000h		;6a2d
	ld a,(de)			;6a2f   ; con cero no hay escalon
	or a			;6a30
	jr z,CAMBIA_LA_FIGURA_DEL_GIRO		;6a31
UN_ESCALON:
	inc c			;6a33
	sub 008h		;6a34   ; de ocho en ocho
	jr z,CAMBIA_LA_FIGURA_DEL_GIRO		;6a36
	jr nc,UN_ESCALON		;6a38
	ret			;6a3a
CAMBIA_LA_FIGURA_DEL_GIRO:
	call COLUMNA_DEL_QUE_JUEGA		;6a3b   ; la ficha del que juega
	push hl			;6a3e
	inc (hl)			;6a3f
	ex de,hl			;6a40
	ld hl,06a6ah		;6a41   ; la tabla de escalones
	ld a,c			;6a44
	rlca			;6a45   ; cuatro bytes por escalon
	rlca			;6a46
	call SUMA_A_A_HL		;6a47
	ld a,(hl)			;6a4a
	ex de,hl			;6a4b
	inc hl			;6a4c
	ld (hl),a			;6a4d   ; la figura que toca
	ld a,b			;6a4e
	push de			;6a4f
	call PINTA_AL_ATLETA		;6a50   ; se pinta
	pop de			;6a53
	inc de			;6a54
	pop hl			;6a55
	dec hl			;6a56
	ld bc,0e208h		;6a57   ; la posicion del martillo
	ld a,(de)			;6a5a   ; fila
	add a,(hl)			;6a5b
	ld (bc),a			;6a5c
	inc hl			;6a5d
	inc de			;6a5e
	inc bc			;6a5f
	ld a,(de)			;6a60   ; columna
	add a,(hl)			;6a61
	ld (bc),a			;6a62
	inc de			;6a63
	inc bc			;6a64
	ld a,(de)			;6a65   ; y patron
	ld (bc),a			;6a66
	jp SUBE_UN_PATRON_DEL_OBJETO		;6a67

; ----------------------------------------------------------------------
; DATOS escalones_de_esfuerzo: Dos tiras de ocho que 0x6A41 lee con el nivel
;   de esfuerzo del atleta.
;   0x6a6a..0x6a7a  (16 bytes)
DATA_escalones_de_esfuerzo:
	defb 014h,009h,010h,005h,015h,000h,000h,002h	; 6a6a  ........
	defb 016h,00eh,005h,003h,017h,012h,00eh,004h	; 6a72  ........

; ----------------------------------------------------------------------
; DATOS suma_de_la_marca: Cuanto sube la marca en cada escalon (0x6A0F).
;   0x6a7a..0x6a82  (8 bytes)
DATA_suma_de_la_marca:
	defb 001h,003h,004h,006h,007h,007h,001h,001h	; 6a7a  ........

; ----------------------------------------------------------------------
; DATOS figura_del_paso: Que figura toca en cada escalon (0x69FF).
;   0x6a82..0x6a8a  (8 bytes)
DATA_figura_del_paso:
	defb 003h,002h,002h,001h,001h,001h,001h,001h	; 6a82  ........

; ----------------------------------------------------------------------
; DATOS salto_del_objeto: Los pares de desplazamiento que 0x69B0 suma a la
;   posicion del objeto que vuela.
;   0x6a8a..0x6a92  (8 bytes)
DATA_salto_del_objeto:
	defb 006h,004h	; 6a8a
	defb 004h,000h	; 6a8c
	defb 000h,002h	; 6a8e
	defb 006h,003h	; 6a90

; ======================================================================
; CODIGO 0x6a92..0x6bda  (328 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  EL REPRODUCTOR DE SONIDO  ==========
; Tres canales de once bytes en 0xE160, 0xE16B y 0xE176. La ficha de un
; canal es: +0 cuenta de la nota, +1 duracion base, +2 numero de sonido,
; +3/+4 puntero a la tira, +5 octava, +6 caida, +7 volumen, +8 cuenta de
; la caida, +9 repeticiones que quedan, +0x0A duracion.
; El numero de sonido lleva la informacion en sus bits altos: el bit 7
; dice que la nota va en UN byte, y el bit 6 que el canal 3 se usa como
; ruido. Los seis de abajo son la PRIORIDAD: un sonido no interrumpe a
; otro de prioridad mas alta.
; ----------------------------------------------------------------------
PIDE_UN_SONIDO:
	push af			;6a92
	ld a,(0e002h)		;6a93   ; en la demo no suena nada
	or a			;6a96
	jr z,PIDE_UN_SONIDO_DE_VERDAD		;6a97
	pop af			;6a99
	ret			;6a9a
PIDE_UN_SONIDO_DE_VERDAD:
	pop af			;6a9b
	push hl			;6a9c
	push de			;6a9d
	push bc			;6a9e
	push af			;6a9f
	ld d,000h		;6aa0   ; D a cero: hay que mirar la prioridad
	cp 002h		;6aa2   ; el sonido 2 son tres a la vez
	jr nz,PIDE_EL_ULTIMO		;6aa4
	call ENCHUFA_UN_SONIDO		;6aa6   ; el suyo
	ld a,047h		;6aa9   ; mas el 0x47
	call ENCHUFA_UN_SONIDO		;6aab
	ld a,049h		;6aae   ; y el 0x49
PIDE_EL_ULTIMO:
	call ENCHUFA_UN_SONIDO		;6ab0
	pop af			;6ab3   ; se devuelven los registros
	pop bc			;6ab4
	pop de			;6ab5
	pop hl			;6ab6
	ret			;6ab7
ENCHUFA_UN_SONIDO:
	ld c,a			;6ab8   ; el numero de sonido
	ld b,002h		;6ab9   ; dos voces de entrada
	ld hl,0e162h		;6abb   ; empezando por el canal 1
	cp 001h		;6abe   ; el sonido 1 es un caso aparte
	jr z,MIRA_LA_PRIORIDAD		;6ac0
	cp 081h		;6ac2   ; por debajo de 0x81 son efectos
	jr c,REPARTE_EL_EFECTO		;6ac4
	cp 096h		;6ac6   ; de 0x81 a 0x95, dos voces
	jr c,MIRA_LA_PRIORIDAD		;6ac8
TRES_VOCES:
	inc b			;6aca   ; de 0x96 en adelante, tres
	jr MIRA_LA_PRIORIDAD		;6acb
REPARTE_EL_EFECTO:
	and 03fh		;6acd   ; los seis bits de la prioridad
	cp 00ah		;6acf   ; por debajo de 10, una voz
	jr c,UNA_VOZ		;6ad1
	cp 00ch		;6ad3   ; de 10 a 11, dos
	jr c,AL_CANAL_2		;6ad5
	jr TRES_VOCES		;6ad7   ; y de 12 en adelante, tres
UNA_VOZ:
	dec b			;6ad9   ; una sola voz
	cp 006h		;6ada   ; los cinco primeros van al canal 1
	jr c,MIRA_LA_PRIORIDAD		;6adc
	ld hl,0e178h		;6ade   ; del 6 al 9, al canal 3
	cp 009h		;6ae1   ; el 9 tambien
	jr nc,MIRA_LA_PRIORIDAD		;6ae3
AL_CANAL_2:
	ld hl,0e16dh		;6ae5
MIRA_LA_PRIORIDAD:
	dec d			;6ae8   ; con D a uno se enchufa sin mirar
	jr z,ENCHUFA_LA_TIRA		;6ae9
	ld e,(hl)			;6aeb   ; el sonido que hay puesto
	ld a,e			;6aec
	and 03fh		;6aed   ; su prioridad
	ld (hl),a			;6aef
	ld a,c			;6af0   ; contra la del nuevo
	and 03fh		;6af1
	cp (hl)			;6af3
	ld (hl),e			;6af4   ; si el nuevo pierde, se queda como estaba
	ret c			;6af5
ENCHUFA_LA_TIRA:
	add a,a			;6af6   ; dos bytes por casilla; el acarreo se PIERDE, y por eso los sonidos de
	ld de,06d26h		;6af7   ; 0x81 en adelante caen en la casilla que da su numero sin el bit 7
	ex de,hl			;6afa
	call SUMA_A_A_HL		;6afb   ; la casilla de la tabla
	ex de,hl			;6afe
	dec hl			;6aff   ; la ficha del canal empieza dos bytes antes
	dec hl			;6b00
MONTA_UN_CANAL:
	ld (hl),001h		;6b01   ; cuenta y duracion a uno
	inc hl			;6b03
	ld (hl),001h		;6b04
	inc hl			;6b06
	ld (hl),c			;6b07   ; el numero de sonido
	inc hl			;6b08
	ld a,(de)			;6b09   ; y el puntero a su tira
	ld (hl),a			;6b0a
	inc hl			;6b0b
	inc de			;6b0c
	ld a,(de)			;6b0d
	ld (hl),a			;6b0e
	ld a,006h		;6b0f   ; seis bytes mas alla
	add a,l			;6b11
	ld l,a			;6b12
	ld (hl),000h		;6b13   ; va la cuenta de repeticiones, a cero
	inc hl			;6b15
	inc de			;6b16   ; y la voz siguiente se lleva la casilla siguiente
	djnz MONTA_UN_CANAL		;6b17
	ret			;6b19
MUEVE_EL_SONIDO:
	ld c,001h		;6b1a   ; el canal 1 escribe en los registros 0 y 1
	ld ix,0e160h		;6b1c   ; la ficha del canal 1
	exx			;6b20
	ld b,003h		;6b21   ; tres canales
	ld de,0000bh		;6b23   ; once bytes por ficha
MUEVE_UN_CANAL:
	exx			;6b26
	ld a,(ix+002h)		;6b27   ; el numero de sonido
	push af			;6b2a
	cp 001h		;6b2b
	call z,DOBLA_LA_MELODIA		;6b2d   ; el sonido 1 es la mezcla de tono y ruido
	pop af			;6b30
	or a			;6b31
	call nz,MUEVE_UNA_VOZ		;6b32   ; con sonido puesto, se mueve
	inc c			;6b35   ; dos registros por canal
	inc c			;6b36
	exx			;6b37
	add ix,de		;6b38
	djnz MUEVE_UN_CANAL		;6b3a
	exx			;6b3c
	ret			;6b3d
MIRA_LAS_REPETICIONES:
	inc hl			;6b3e
	ld a,(ix+009h)		;6b3f   ; las que lleva
	inc a			;6b42
	cp (hl)			;6b43   ; contra las que pide la tira
	jp z,APAGA_LA_VOZ		;6b44   ; al llegar, se apaga
	jp m,REPITE_LA_TIRA		;6b47   ; la primera vez viene con el bit alto puesto
	dec a			;6b4a
REPITE_LA_TIRA:
	ex af,af'			;6b4b
	ld a,(ix+002h)		;6b4c   ; el mismo sonido otra vez
	push bc			;6b4f
	call ENCHUFA_UN_SONIDO		;6b50   ; se vuelve a enchufar
	pop bc			;6b53
	ex af,af'			;6b54
	ld (ix+009h),a		;6b55   ; y se apunta una repeticion mas
	ret			;6b58
ENCIENDE_O_APAGA_LA_VOZ:
	ld a,007h		;6b59   ; el registro 7 del PSG, el mezclador
	call 00096h		;6b5b   ; BIOS RDPSG - Reads value from PSG-register
	ld e,a			;6b5e
	ld a,c			;6b5f   ; el canal
	cp 001h		;6b60   ; el 1 no se ajusta
	jr z,COLOCA_EL_BIT_DEL_CANAL		;6b62
	dec a			;6b64
COLOCA_EL_BIT_DEL_CANAL:
	rlca			;6b65   ; tres desplazamientos: los bits de ruido
	rlca			;6b66
	rlca			;6b67
	dec d			;6b68   ; con D a uno se apaga
	jr z,ENCIENDE_LA_VOZ		;6b69
	cpl			;6b6b   ; y si no, se enciende
	and e			;6b6c
	jr AJUSTA_EL_RUIDO		;6b6d
ENCIENDE_LA_VOZ:
	or e			;6b6f
AJUSTA_EL_RUIDO:
	set 2,a		;6b70   ; el canal 3 lleva el ruido
	bit 5,a		;6b72   ; salvo si ya estaba activo
	jr z,ESCRIBE_EL_MEZCLADOR		;6b74
	res 2,a		;6b76
ESCRIBE_EL_MEZCLADOR:
	ld e,a			;6b78
	ld a,007h		;6b79
	jp 00093h		;6b7b   ; BIOS WRTPSG - Writes data to PSG-register
DOBLA_LA_MELODIA:
	ld hl,0e193h		;6b7e   ; el trozo del canal 3
	ld de,06bddh		;6b81   ; y su tira de recambio
	ld a,c			;6b84
	cp 003h		;6b85   ; el canal 3
	jr z,MIRA_EL_MODO_DE_DOBLADO		;6b87
	ld hl,0e197h		;6b89   ; o el trozo del canal 2
	ld de,06be1h		;6b8c
MIRA_EL_MODO_DE_DOBLADO:
	ld a,(0e190h)		;6b8f   ; el modo de doblado
	cp 001h		;6b92
	jr z,BAJA_EL_DOBLADO		;6b94   ; modo 1: baja
	jr c,ENCHUFA_LA_TIRA_DE_RECAMBIO		;6b96   ; modo 0: se recupera
	dec hl			;6b98
	ld a,(hl)			;6b99   ; lo que lleva doblado
	or a			;6b9a
	jr nz,SUBE_EL_DOBLADO		;6b9b   ; si es cero, se enchufa la tira de recambio
	inc hl			;6b9d
	ld de,06be2h		;6b9e   ; la del canal 3
	ld a,c			;6ba1
	cp 003h		;6ba2
	jr z,ENCHUFA_LA_TIRA_DE_RECAMBIO		;6ba4
	ld de,06be6h		;6ba6   ; o la del 2
	jr ENCHUFA_LA_TIRA_DE_RECAMBIO		;6ba9
SUBE_EL_DOBLADO:
	inc hl			;6bab
	inc (hl)			;6bac   ; dos de golpe
	inc (hl)			;6bad
	dec hl			;6bae
	jr nz,GUARDA_EL_PUNTERO		;6baf
	inc (hl)			;6bb1
GUARDA_EL_PUNTERO:
	dec hl			;6bb2
	ld (ix+003h),l		;6bb3   ; el puntero de la tira, en la ficha
	ld (ix+004h),h		;6bb6
	ret			;6bb9
BAJA_EL_DOBLADO:
	dec hl			;6bba
	ld a,08fh		;6bbb   ; el byte de arriba
	cp (hl)			;6bbd   ; por debajo de 0x8F se planta
	jr c,BAJA_DE_DOS_EN_DOS		;6bbe
	xor a			;6bc0
	ld (hl),a			;6bc1
	jr GUARDA_EL_PUNTERO		;6bc2
BAJA_DE_DOS_EN_DOS:
	inc hl			;6bc4
	dec (hl)			;6bc5   ; dos de golpe
	dec (hl)			;6bc6
	dec hl			;6bc7
	jr nz,GUARDA_EL_PUNTERO		;6bc8   ; y con acarreo al byte de arriba
	dec (hl)			;6bca
	jr GUARDA_EL_PUNTERO		;6bcb
ENCHUFA_LA_TIRA_DE_RECAMBIO:
	push bc			;6bcd
	ex de,hl			;6bce
	ld bc,00004h		;6bcf   ; cuatro bytes hacia atras
	lddr		;6bd2
	ex de,hl			;6bd4
	pop bc			;6bd5
	inc hl			;6bd6
	inc hl			;6bd7
	jr GUARDA_EL_PUNTERO		;6bd8

; ----------------------------------------------------------------------
; DATOS trozos_de_melodia: Los cachos de tira que 0x6B7E enchufa a un canal
;   para doblar o quebrar la nota segun 0xE190.
;   0x6bda..0x6be7  (13 bytes)
DATA_trozos_de_melodia:
	defb 001h,021h,092h,0c0h	; 6bda
	defb 001h,021h,092h,0c8h	; 6bde
	defb 000h,002h,021h,090h	; 6be2
	defb 008h	; 6be6

; ======================================================================
; CODIGO 0x6be7..0x6d1c  (309 bytes)
; ======================================================================


MUEVE_UNA_VOZ:
	bit 6,a		;6be7   ; bit 6: el canal se usa para ruido
	ld d,001h		;6be9
	call z,ENCIENDE_O_APAGA_LA_VOZ		;6beb   ; entonces se enciende el tono
	ld a,(ix+002h)		;6bee   ; el numero de sonido
	or a			;6bf1
	jp m,GASTA_LA_NOTA		;6bf2   ; con el bit 7 puesto la nota va en un byte
	dec (ix+000h)		;6bf5   ; la cuenta de la nota
	ret nz			;6bf8   ; mientras quede, se deja sonando
LEE_LA_TIRA:
	ld l,(ix+003h)		;6bf9   ; el puntero de la tira
	ld h,(ix+004h)		;6bfc
	ld a,(hl)			;6bff   ; el byte que toca
	cp 0feh		;6c00   ; 0xFE pide repetir
	jp z,MIRA_LAS_REPETICIONES		;6c02
	jp nc,APAGA_LA_VOZ		;6c05   ; 0xFF acaba
	bit 7,(ix+002h)		;6c08   ; los sonidos con el bit 7 usan el formato de un byte
	jp nz,NOTA_DE_UN_BYTE		;6c0c
	and 0f0h		;6c0f
	cp 020h		;6c11   ; 0x2n cambia la duracion base
	jr nz,MIRA_EL_RUIDO		;6c13
	ld a,(hl)			;6c15
	and 00fh		;6c16
	ld (ix+001h),a		;6c18   ; y se guarda
	inc hl			;6c1b
MIRA_EL_RUIDO:
	ld a,(hl)			;6c1c
	and 0f0h		;6c1d
	cp 010h		;6c1f   ; 0x1n pide ruido
	jr nz,MIRA_EL_SILENCIO		;6c21
	ld a,(hl)			;6c23
	and 01fh		;6c24   ; los cinco bits del periodo
	ld e,a			;6c26
	ld a,006h		;6c27   ; al registro 6 del PSG
	call 00093h		;6c29   ; BIOS WRTPSG - Writes data to PSG-register
	ld d,000h		;6c2c
	call ENCIENDE_O_APAGA_LA_VOZ		;6c2e   ; y se enciende el canal de ruido
	inc hl			;6c31
	ld a,(hl)			;6c32
MIRA_EL_SILENCIO:
	ld b,(ix+002h)		;6c33   ; el numero de sonido
	bit 6,b		;6c36   ; bit 6: canal de ruido
	jr z,TOCA_LA_NOTA		;6c38
	ld a,c			;6c3a
	cp 005h		;6c3b   ; el canal 3
	ld a,(hl)			;6c3d
	jr nz,TOCA_LA_NOTA		;6c3e
	inc hl			;6c40
	ld (ix+003h),l		;6c41   ; se guarda el puntero
	ld (ix+004h),h		;6c44
	call ARRANCA_LA_NOTA		;6c47   ; y solo se toca el volumen
	ret			;6c4a
TOCA_LA_NOTA:
	and 0f0h		;6c4b   ; el nibble alto es la duracion
	ld b,a			;6c4d
	xor (hl)			;6c4e   ; y el bajo, la parte alta del periodo
	ld d,a			;6c4f
	inc hl			;6c50
	ld e,(hl)			;6c51   ; el byte siguiente es la parte baja
	inc hl			;6c52
	ld (ix+003h),l		;6c53   ; se guarda el puntero
	ld (ix+004h),h		;6c56
	ex de,hl			;6c59
	call ESCRIBE_EL_PERIODO		;6c5a   ; y se escribe el periodo en el PSG
	ld a,b			;6c5d   ; la duracion vuelve a la parte baja
	rrca			;6c5e
	rrca			;6c5f
	rrca			;6c60
	rrca			;6c61
ARRANCA_LA_NOTA:
	ld h,a			;6c62
	ld a,(ix+001h)		;6c63   ; la duracion base
	ld (ix+000h),a		;6c66   ; se copia a la cuenta
	add a,002h		;6c69   ; y la cuenta de caida sale dos por encima
	ld (ix+008h),a		;6c6b
	jr ESCRIBE_EL_VOLUMEN		;6c6e
APAGA_LA_VOZ:
	xor a			;6c70
	ld (ix+009h),a		;6c71   ; sin repeticiones pendientes
	ld d,001h		;6c74   ; apaga la voz
	call ENCIENDE_O_APAGA_LA_VOZ		;6c76
	xor a			;6c79
	ld (ix+002h),a		;6c7a   ; y borra el numero de sonido
	ld h,a			;6c7d
	jr ESCRIBE_EL_VOLUMEN		;6c7e
GASTA_LA_NOTA:
	dec (ix+000h)		;6c80   ; la cuenta de la nota
	jp z,LEE_LA_TIRA		;6c83   ; al llegar a cero se lee la siguiente
	dec (ix+008h)		;6c86   ; la cuenta de la caida
	ld a,(ix+008h)		;6c89
	cp (ix+000h)		;6c8c   ; mientras las dos vayan iguales, no se baja el volumen
	jr nz,ADELANTA_LA_CAIDA		;6c8f
	cp 002h		;6c91   ; salvo en los dos ultimos cuadros
	jr c,BAJA_EL_VOLUMEN		;6c93
	ret			;6c95
ADELANTA_LA_CAIDA:
	dec (ix+008h)		;6c96
BAJA_EL_VOLUMEN:
	ld a,(ix+007h)		;6c99   ; el volumen del canal
	dec a			;6c9c
	ret m			;6c9d   ; por debajo de cero no se baja
	ld (ix+007h),a		;6c9e
	ld h,a			;6ca1
ESCRIBE_EL_VOLUMEN:
	ld a,c			;6ca2   ; los registros 8, 9 y 10 del PSG
	rrca			;6ca3
	add a,088h		;6ca4
	ld e,h			;6ca6
	jp 00093h		;6ca7   ; BIOS WRTPSG - Writes data to PSG-register
NOTA_DE_UN_BYTE:
	and 0f0h		;6caa
	cp 0d0h		;6cac   ; 0xDn cambia la duracion
	ld a,(hl)			;6cae
	jr nz,MIRA_LA_CAIDA		;6caf
	and 00fh		;6cb1
	ld (ix+00ah),a		;6cb3   ; y se guarda
	inc hl			;6cb6
	ld a,(hl)			;6cb7
MIRA_LA_CAIDA:
	cp 0f0h		;6cb8   ; 0xFn cambia la caida
	jr c,MIRA_LA_OCTAVA		;6cba
	and 00fh		;6cbc
	ld (ix+006h),a		;6cbe   ; y se guarda
	inc hl			;6cc1
	ld a,(hl)			;6cc2
MIRA_LA_OCTAVA:
	cp 0e0h		;6cc3   ; 0xEn cambia la octava
	jr c,CALCULA_LA_DURACION		;6cc5
	and 00fh		;6cc7
	ld (ix+005h),a		;6cc9   ; y se guarda
	inc hl			;6ccc
	ld a,(hl)			;6ccd
CALCULA_LA_DURACION:
	and 00fh		;6cce   ; el nibble bajo dice cuantas duraciones
	ld b,a			;6cd0
	ld a,(ix+00ah)		;6cd1   ; la duracion de base
	jr z,ARRANCA_LA_NOTA_DE_UN_BYTE		;6cd4
SUMA_UNA_DURACION:
	add a,(ix+00ah)		;6cd6
	djnz SUMA_UNA_DURACION		;6cd9
ARRANCA_LA_NOTA_DE_UN_BYTE:
	ld (ix+001h),a		;6cdb   ; la duracion que sale
	ld a,(hl)			;6cde   ; el mismo byte otra vez
	inc hl			;6cdf
	ld (ix+003h),l		;6ce0   ; se guarda el puntero
	ld (ix+004h),h		;6ce3
	and 0f0h		;6ce6   ; el nibble alto es la nota
	rrca			;6ce8
	rrca			;6ce9
	rrca			;6cea
	rrca			;6ceb
	ld b,a			;6cec
	sub 00ch		;6ced   ; la nota 12 es el silencio
	ld (ix+007h),a		;6cef   ; y las demas, volumen
	jr z,TOCA_LA_NOTA_DE_UN_BYTE		;6cf2
	ld a,(ix+006h)		;6cf4   ; y si no, la caida de la ficha
	ld (ix+007h),a		;6cf7
TOCA_LA_NOTA_DE_UN_BYTE:
	call ARRANCA_LA_NOTA		;6cfa   ; arranca la nota
	ld a,b			;6cfd
	ld hl,06d1ch		;6cfe   ; la tabla de los doce periodos
	call SUMA_A_A_HL		;6d01
	ld l,(hl)			;6d04   ; el periodo de la nota
	ld h,000h		;6d05
	ld a,(ix+005h)		;6d07   ; la octava
	or a			;6d0a
	jr z,ESCRIBE_EL_PERIODO		;6d0b   ; la primera no desplaza
	ld b,a			;6d0d
BAJA_UNA_OCTAVA:
	add hl,hl			;6d0e   ; cada octava abajo dobla el periodo
	djnz BAJA_UNA_OCTAVA		;6d0f
ESCRIBE_EL_PERIODO:
	ld a,c			;6d11   ; el registro alto del canal
	ld e,h			;6d12
	call 00093h		;6d13   ; BIOS WRTPSG - Writes data to PSG-register
	ld a,c			;6d16   ; y el bajo
	dec a			;6d17
	ld e,l			;6d18
	jp 00093h		;6d19   ; BIOS WRTPSG - Writes data to PSG-register

; ----------------------------------------------------------------------
; DATOS periodos_de_las_notas: Los doce periodos de una octava, de 0x6A a
;   0x38. El reproductor los desplaza a la izquierda para bajar de octava
;   (0x6D0E).
;   0x6d1c..0x6d28  (12 bytes)
DATA_periodos_de_las_notas:
	defb 06ah,064h,05fh,059h,054h,050h,04bh,047h,043h,03fh,03ch,038h	; 6d1c  jd_YTPKGC?<8

; ----------------------------------------------------------------------
; DATOS punteros_de_melodia: Treinta y nueve punteros a tiras de melodia.
;   0x6AF6 los indexa desde uno -por eso registra 0x6D26, dos bytes antes- y
;   un sonido de varias voces se lleva entradas seguidas.
;   0x6d28..0x6d76  (78 bytes)
DATA_punteros_de_melodia:
	defw 06d76h	; 6d28  -> DATA_melodias
	defw 0700bh	; 6d2a
	defw 06d9ch	; 6d2c
	defw 06faeh	; 6d2e
	defw 06d77h	; 6d30
	defw 06ffah	; 6d32
	defw 06ffah	; 6d34
	defw 06fdeh	; 6d36
	defw 07006h	; 6d38
	defw 06da5h	; 6d3a
	defw 06dd4h	; 6d3c
	defw 06d76h	; 6d3e  -> DATA_melodias
	defw 06de6h	; 6d40
	defw 06e2dh	; 6d42
	defw 06d76h	; 6d44  -> DATA_melodias
	defw 06fe3h	; 6d46
	defw 06ff1h	; 6d48
	defw 06fd4h	; 6d4a
	defw 06fd9h	; 6d4c
	defw 06fdeh	; 6d4e
	defw 06fdeh	; 6d50
	defw 06e43h	; 6d52
	defw 06e66h	; 6d54
	defw 06e83h	; 6d56
	defw 06ec8h	; 6d58
	defw 06ee3h	; 6d5a
	defw 06efeh	; 6d5c
	defw 06f19h	; 6d5e
	defw 06f2ch	; 6d60
	defw 06f3fh	; 6d62
	defw 06f52h	; 6d64
	defw 06f73h	; 6d66
	defw 06f94h	; 6d68
	defw 06fd4h	; 6d6a
	defw 06fd4h	; 6d6c
	defw 06fd4h	; 6d6e
	defw 06d76h	; 6d70  -> DATA_melodias
	defw 06d76h	; 6d72  -> DATA_melodias
	defw 06d76h	; 6d74  -> DATA_melodias

; ----------------------------------------------------------------------
; DATOS melodias: Las tiras de notas. Los sonidos con el bit 7 puesto llevan
;   la nota en UN byte (nibble alto = nota, nibble bajo = cuantas duraciones);
;   los demas en DOS (nibble alto = duracion, los otros doce bits = periodo).
;   0xFF acaba y 0xFE vuelve a empezar.
;   0x6d76..0x702e  (696 bytes)
DATA_melodias:
	defb 0ffh,021h,011h,051h,0a0h,061h,0a0h,071h	; 6d76  .!.Q.a.q
	defb 0a0h,081h,0a0h,091h,0a0h,0a1h,0a0h,0b1h	; 6d7e  ........
	defb 0a0h,0c1h,0a0h,0d1h,0a0h,0e1h,0a0h,0d1h	; 6d86  ........
	defb 0a0h,0b1h,0a0h,091h,0a0h,081h,0a0h,071h	; 6d8e  .......q
	defb 0a0h,061h,0a0h,051h,0a0h,0ffh,021h,01ch	; 6d96  .a.Q..!.
	defb 0b0h,00ch,023h,000h,000h,0feh,0ffh,021h	; 6d9e  ..#....!
	defb 0f1h,050h,0f2h,040h,0f1h,000h,0e2h,010h	; 6da6  .P.@....
	defb 0e1h,0a0h,0d2h,040h,0d1h,050h,0c1h,0d0h	; 6dae  ...@.P..
	defb 0b1h,080h,0b1h,0c0h,0a2h,020h,0a1h,010h	; 6db6  ..... ..
	defb 091h,0d0h,091h,020h,081h,0a0h,023h,082h	; 6dbe  ... ..#.
	defb 030h,071h,050h,071h,0a0h,061h,0f0h,061h	; 6dc6  0qPq.a.a
	defb 0c0h,051h,0a0h,051h,0f0h,0ffh,023h,01fh	; 6dce  .Q.Q..#.
	defb 00ch,00bh,00ah,009h,008h,01dh,008h,01ch	; 6dd6  ........
	defb 007h,01bh,007h,01ah,006h,019h,006h,0ffh	; 6dde  ........
	defb 021h,0f1h,050h,0f2h,040h,0f1h,000h,0e2h	; 6de6  !.P.@...
	defb 010h,0e1h,0a0h,0d2h,040h,0d1h,050h,0c1h	; 6dee  ....@.P.
	defb 0d0h,0b1h,080h,0b1h,0c0h,0a2h,020h,0a1h	; 6df6  ...... .
	defb 010h,0f1h,050h,0f2h,040h,0f1h,000h,0e2h	; 6dfe  ..P.@...
	defb 010h,0e1h,0a0h,0d2h,040h,0d1h,050h,0c1h	; 6e06  ....@.P.
	defb 0d0h,0b1h,080h,0b1h,0c0h,0a2h,020h,0a1h	; 6e0e  ...... .
	defb 010h,091h,0d0h,091h,020h,081h,0a0h,023h	; 6e16  .... ..#
	defb 082h,030h,071h,050h,071h,0a0h,061h,0f0h	; 6e1e  .0qPq.a.
	defb 061h,0c0h,051h,0a0h,051h,0f0h,0ffh,023h	; 6e26  a.Q.Q..#
	defb 01fh,00ch,00bh,00ah,009h,00ch,00bh,00ah	; 6e2e  ........
	defb 009h,008h,01dh,008h,01ch,007h,01bh,007h	; 6e36  ........
	defb 01ah,006h,019h,006h,0ffh,0d5h,0fch,0e2h	; 6e3e  ........
	defb 0c3h,083h,0e1h,012h,032h,051h,037h,00bh	; 6e46  ....2Q7.
	defb 0e2h,083h,0e1h,012h,032h,051h,0dah,039h	; 6e4e  ....2Q.9
	defb 0d5h,0e2h,083h,0e1h,012h,032h,051h,037h	; 6e56  .....2Q7
	defb 00bh,003h,012h,002h,0e2h,081h,08fh,0ffh	; 6e5e  ........
	defb 0d5h,0fch,0e2h,0c3h,003h,052h,082h,011h	; 6e66  .....R..
	defb 007h,03bh,003h,052h,082h,011h,0dah,009h	; 6e6e  .;.R....
	defb 0d5h,003h,052h,082h,011h,007h,03bh,033h	; 6e76  ..R...;3
	defb 052h,032h,001h,00fh,0ffh,0d5h,0fbh,0e3h	; 6e7e  R2......
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6e86  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6e8e  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6e96  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6e9e  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6ea6  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6eae  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6eb6  ........
	defb 081h,081h,081h,081h,081h,081h,081h,081h	; 6ebe  ........
	defb 0feh,001h,0d4h,0fch,0e2h,021h,021h,021h	; 6ec6  .....!!!
	defb 075h,0e1h,001h,0e2h,0b1h,091h,0d3h,0b5h	; 6ece  u.......
	defb 071h,0d4h,0a1h,0a1h,0a1h,0e1h,035h,071h	; 6ed6  q.....5q
	defb 051h,031h,0d6h,02bh,0ffh,0d4h,0fch,0e3h	; 6ede  Q1.+....
	defb 0b1h,0b1h,0b1h,0b5h,0e2h,041h,041h,041h	; 6ee6  .....AAA
	defb 0d3h,055h,0e3h,0b1h,0d4h,0e2h,031h,031h	; 6eee  .U....11
	defb 031h,035h,031h,031h,051h,0d6h,07bh,0ffh	; 6ef6  1511Q.{.
	defb 0d4h,0fch,0e3h,071h,071h,071h,075h,0e2h	; 6efe  ...qqqu.
	defb 001h,001h,001h,0d3h,0e3h,075h,071h,0d4h	; 6f06  .....uq.
	defb 0e2h,071h,071h,071h,075h,0a1h,0a1h,091h	; 6f0e  .qqqu...
	defb 0d6h,0bbh,0ffh,0d2h,0fch,0e2h,053h,093h	; 6f16  ......S.
	defb 0e1h,003h,057h,001h,001h,023h,0e2h,0a1h	; 6f1e  ..W..#..
	defb 0e1h,021h,053h,0d6h,097h,0ffh,0d2h,0fch	; 6f26  .!S.....
	defb 0e2h,053h,093h,0e1h,003h,0e2h,097h,051h	; 6f2e  .S.....Q
	defb 051h,053h,021h,051h,0b3h,0d6h,0e1h,007h	; 6f36  QS!Q....
	defb 0ffh,0d2h,0fch,0e3h,053h,093h,0e2h,003h	; 6f3e  ....S...
	defb 057h,0e3h,091h,091h,0a3h,0a1h,0a1h,0e2h	; 6f46  W.......
	defb 023h,0d6h,057h,0ffh,0d4h,0fch,0e1h,041h	; 6f4e  #.W....A
	defb 091h,0e0h,011h,0e1h,0b1h,041h,091h,0e0h	; 6f56  .....A..
	defb 011h,0e1h,0b1h,041h,091h,0b1h,091h,081h	; 6f5e  ...A....
	defb 0b1h,0e0h,041h,0e1h,0b1h,0e0h,011h,001h	; 6f66  ..A.....
	defb 0e1h,0b1h,0a1h,093h,0ffh,0d4h,0fch,0e2h	; 6f6e  ........
	defb 041h,091h,0e1h,011h,0e2h,0b1h,041h,091h	; 6f76  A.....A.
	defb 0e1h,011h,0e2h,0b1h,041h,091h,0b1h,091h	; 6f7e  ....A...
	defb 081h,0b1h,0e1h,041h,0e2h,0b1h,0e1h,011h	; 6f86  ...A....
	defb 001h,0e2h,0b1h,0a1h,093h,0ffh,0d4h,0fch	; 6f8e  ........
	defb 0e4h,0c3h,091h,0e3h,041h,091h,091h,0e4h	; 6f96  ....A...
	defb 091h,0e3h,041h,091h,041h,041h,081h,0b1h	; 6f9e  ..A.AA..
	defb 081h,041h,031h,021h,011h,0e4h,093h,0ffh	; 6fa6  .A1!....
	defb 023h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h	; 6fae  #.......
	defb 0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h	; 6fb6  ........
	defb 0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h	; 6fbe  ........
	defb 0a0h,0d0h,08fh,0d0h,0a0h,0d0h,08fh,0d0h	; 6fc6  ........
	defb 0a0h,02fh,000h,000h,0feh,002h,0dah,0fdh	; 6fce  ./......
	defb 0e1h,075h,0ffh,0dah,0fdh,0e0h,005h,0ffh	; 6fd6  .u......
	defb 021h,01fh,0c1h,0f0h,0ffh,021h,0a1h,0b0h	; 6fde  !....!..
	defb 0b2h,0f0h,0b1h,0a0h,083h,0c0h,082h,070h	; 6fe6  .......p
	defb 072h,0b0h,0ffh,021h,01ah,00eh,00dh,00eh	; 6fee  r..!....
	defb 00ah,009h,00dh,0ffh,023h,014h,081h,070h	; 6ff6  ....#..p
	defb 000h,000h,081h,098h,000h,000h,0feh,013h	; 6ffe  ........
	defb 02fh,014h,00bh,0feh,00fh,024h,000h,000h	; 7006  /....$..
	defb 026h,080h,021h,080h,020h,080h,021h,080h	; 700e  &.!. .!.
	defb 020h,02fh,000h,000h,000h,000h,026h,080h	; 7016   /....&.
	defb 021h,080h,020h,080h,021h,080h,020h,02fh	; 701e  !. .!. /
	defb 000h,000h,000h,000h,000h,000h,0feh,002h	; 7026  ........

; ----------------------------------------------------------------------
; DATOS posturas_del_atleta: Veinticinco punteros, uno por postura, que 0x7FA1
;   indexa con 0xE0B6 o 0xE0EC.
;   0x702e..0x7060  (50 bytes)
DATA_posturas_del_atleta:
	defw 07088h	; 702e
	defw 07074h	; 7030
	defw 07060h	; 7032  -> DATA_registros_de_postura
	defw 07095h	; 7034
	defw 07081h	; 7036
	defw 0706dh	; 7038
	defw 070c3h	; 703a
	defw 070d2h	; 703c
	defw 070e1h	; 703e
	defw 070eeh	; 7040
	defw 070fbh	; 7042
	defw 07108h	; 7044
	defw 07119h	; 7046
	defw 0712ah	; 7048
	defw 07137h	; 704a
	defw 07144h	; 704c
	defw 07151h	; 704e
	defw 0709ch	; 7050
	defw 070a9h	; 7052
	defw 070b6h	; 7054
	defw 0715eh	; 7056
	defw 0716bh	; 7058
	defw 07178h	; 705a
	defw 07185h	; 705c
	defw 07192h	; 705e

; ----------------------------------------------------------------------
; DATOS registros_de_postura: Por postura: cuantos trozos de sprite lleva, un
;   puntero a cada uno y, al final, el puntero a su lista de atributos.
;   0x7060..0x719f  (319 bytes)
DATA_registros_de_postura:
	defw 0e005h	; 7060
	defw 0e373h	; 7062
	defw 0fa72h	; 7064
	defw 0b473h	; 7066
	defw 08273h	; 7068
	defw 0b775h	; 706a
	defw 00271h	; 706c
	defw 07319h	; 706e
	defw 075f2h	; 7070
	defw 071b7h	; 7072
	defw 03405h	; 7074
	defw 02673h	; 7076
	defw 0fa78h	; 7078
	defw 05673h	; 707a
	defw 0d073h	; 707c
	defw 0ab75h	; 707e
	defw 00271h	; 7080
	defw 0739ch	; 7082
	defw 07826h	; 7084
	defw 071abh	; 7086
	defw 0ac05h	; 7088
	defw 08472h	; 708a
	defw 0fa73h	; 708c
	defw 0fd73h	; 708e
	defw 02d72h	; 7090
	defw 09f75h	; 7092
	defw 00271h	; 7094
	defw 072c9h	; 7096
	defw 07384h	; 7098
	defw 0719fh	; 709a  -> DATA_atributos_de_las_posturas
	defw 08205h	; 709c
	defw 09876h	; 709e
	defw 0ac76h	; 70a0
	defw 01276h	; 70a2
	defw 0b275h	; 70a4
	defw 04c76h	; 70a6
	defw 00572h	; 70a8
	defw 07497h	; 70aa
	defw 075b2h	; 70ac
	defw 076bfh	; 70ae
	defw 076c6h	; 70b0
	defw 076cah	; 70b2
	defw 07258h	; 70b4
	defw 0d005h	; 70b6
	defw 07c76h	; 70b8
	defw 0e474h	; 70ba
	defw 03676h	; 70bc
	defw 0ed75h	; 70be
	defw 06476h	; 70c0
	defw 00672h	; 70c2
	defw 07349h	; 70c4
	defw 0736dh	; 70c6
	defw 0762ch	; 70c8
	defw 07593h	; 70ca
	defw 07525h	; 70cc
	defw 07635h	; 70ce
	defw 071c3h	; 70d0
	defw 0a406h	; 70d2
	defw 0f675h	; 70d4
	defw 0ff78h	; 70d6
	defw 06873h	; 70d8
	defw 0d674h	; 70da
	defw 00d75h	; 70dc
	defw 0d076h	; 70de
	defw 00571h	; 70e0
	defw 074f8h	; 70e2
	defw 0790eh	; 70e4
	defw 0763fh	; 70e6
	defw 07648h	; 70e8
	defw 0767ch	; 70ea
	defw 071ddh	; 70ec
	defw 04905h	; 70ee
	defw 00c74h	; 70f0
	defw 04378h	; 70f2
	defw 06474h	; 70f4
	defw 00175h	; 70f6
	defw 0e978h	; 70f8
	defw 00571h	; 70fa
	defw 074c7h	; 70fc
	defw 0780ch	; 70fe
	defw 07443h	; 7100
	defw 07838h	; 7102
	defw 0742dh	; 7104
	defw 071f5h	; 7106
	defw 0de07h	; 7108
	defw 00c74h	; 710a
	defw 04278h	; 710c
	defw 0b775h	; 710e
	defw 04a74h	; 7110
	defw 05175h	; 7112
	defw 01e75h	; 7114
	defw 00178h	; 7116
	defw 00772h	; 7118
	defw 078a1h	; 711a
	defw 0780ch	; 711c
	defw 07443h	; 711e
	defw 078c0h	; 7120
	defw 07619h	; 7122
	defw 00000h	; 7124
	defw 078d7h	; 7126
	defw 0720fh	; 7128
	defw 05a05h	; 712a
	defw 00c76h	; 712c
	defw 04378h	; 712e
	defw 0de74h	; 7130
	defw 05c78h	; 7132
	defw 01c75h	; 7134
	defw 00572h	; 7136
	defw 0786dh	; 7138
	defw 0780ch	; 713a
	defw 07443h	; 713c
	defw 0761eh	; 713e
	defw 07588h	; 7140
	defw 07228h	; 7142
	defw 0cd05h	; 7144
	defw 02673h	; 7146
	defw 0fa78h	; 7148
	defw 00873h	; 714a
	defw 03974h	; 714c
	defw 03474h	; 714e
	defw 00572h	; 7150
	defw 07710h	; 7152
	defw 0780ch	; 7154
	defw 07443h	; 7156
	defw 076f2h	; 7158
	defw 07672h	; 715a
	defw 07240h	; 715c
	defw 0ff05h	; 715e
	defw 0e076h	; 7160
	defw 0c975h	; 7162
	defw 05275h	; 7164
	defw 02778h	; 7166
	defw 07077h	; 7168
	defw 00572h	; 716a
	defw 07732h	; 716c
	defw 07749h	; 716e
	defw 07759h	; 7170
	defw 0775fh	; 7172
	defw 0776ch	; 7174
	defw 0727ch	; 7176
	defw 08905h	; 7178
	defw 07878h	; 717a
	defw 07277h	; 717c
	defw 0a877h	; 717e
	defw 07a77h	; 7180
	defw 08875h	; 7182
	defw 00572h	; 7184
	defw 0778fh	; 7186
	defw 077bdh	; 7188
	defw 07759h	; 718a
	defw 077cdh	; 718c
	defw 077d9h	; 718e
	defw 07294h	; 7190
	defw 0e805h	; 7192
	defw 03d77h	; 7194
	defw 0ac79h	; 7196
	defw 02976h	; 7198
	defw 0de79h	; 719a
	defw 0a077h	; 719c
	defb 072h	; 719e

; ----------------------------------------------------------------------
; DATOS atributos_de_las_posturas: Siete sprites por postura, cuatro bytes
;   cada uno. Las listas se solapan entre si: donde dos posturas comparten las
;   ultimas filas, comparten los mismos bytes.
;   0x719f..0x72ac  (269 bytes)
DATA_atributos_de_las_posturas:
	defb 001h,004h,0ffh,007h	; 719f
	defb 00fh,007h,012h,003h	; 71a3
	defb 010h,002h,0cfh,0cfh	; 71a7
	defb 003h,007h,0ffh,008h	; 71ab
	defb 00fh,009h,012h,006h	; 71af
	defb 010h,007h,0cfh,0cfh	; 71b3
	defb 000h,004h,0ffh,003h	; 71b7
	defb 00fh,009h,012h,007h	; 71bb
	defb 010h,007h,0cfh,0cfh	; 71bf
	defb 008h,011h,008h,00bh	; 71c3
	defb 014h,007h,018h,002h	; 71c7
	defb 01ch,000h,018h,011h	; 71cb
	defb 0cfh,006h,011h,00ch	; 71cf
	defb 00ch,010h,006h,016h	; 71d3
	defb 001h,01ch,000h,016h	; 71d7
	defb 011h,0cfh,006h,011h	; 71db
	defb 004h,011h,00fh,00fh	; 71df
	defb 013h,010h,01ch,00fh	; 71e3
	defb 0cfh,0cfh,003h,006h	; 71e7
	defb 0ffh,008h,00eh,009h	; 71eb
	defb 012h,007h,010h,006h	; 71ef
	defb 0cfh,0cfh,003h,008h	; 71f3
	defb 0ffh,008h,00fh,009h	; 71f7
	defb 011h,005h,011h,004h	; 71fb
	defb 0cfh,0cfh,003h,005h	; 71ff
	defb 0ffh,008h,003h,009h	; 7203
	defb 012h,0ffh,015h,0fdh	; 7207
	defb 012h,00fh,013h,014h	; 720b
	defb 003h,005h,0ffh,008h	; 720f
	defb 00fh,009h,012h,002h	; 7213
	defb 012h,000h,0cfh,013h	; 7217
	defb 010h,003h,008h,0ffh	; 721b
	defb 008h,00fh,009h,012h	; 721f
	defb 006h,011h,004h,0cfh	; 7223
	defb 0cfh,003h,005h,0ffh	; 7227
	defb 008h,00fh,009h,012h	; 722b
	defb 008h,011h,005h,0cfh	; 722f
	defb 0cfh,003h,008h,0ffh	; 7233
	defb 008h,00fh,009h,012h	; 7237
	defb 007h,010h,006h,0cfh	; 723b
	defb 0cfh,003h,007h,0ffh	; 723f
	defb 008h,00fh,009h,013h	; 7243
	defb 006h,01ch,005h,0cfh	; 7247
	defb 0cfh,000h,004h,001h	; 724b
	defb 008h,00eh,00ah,012h	; 724f
	defb 005h,012h,004h,0cfh	; 7253
	defb 0cfh,005h,00dh,003h	; 7257
	defb 00ah,00fh,00ah,010h	; 725b
	defb 01dh,00fh,01eh,0cfh	; 725f
	defb 0cfh,008h,012h,006h	; 7263
	defb 00fh,012h,00ch,016h	; 7267
	defb 010h,01dh,00fh,0cfh	; 726b
	defb 0cfh,004h,006h,002h	; 726f
	defb 004h,010h,006h,012h	; 7273
	defb 008h,01ch,00ch,0cfh	; 7277
	defb 0cfh,006h,00eh,002h	; 727b
	defb 00fh,010h,00fh,014h	; 727f
	defb 00fh,01ch,010h,0cfh	; 7283
	defb 0cfh,004h,010h,002h	; 7287
	defb 013h,010h,012h,012h	; 728b
	defb 00dh,01ch,00bh,0cfh	; 728f
	defb 0cfh,005h,00ch,002h	; 7293
	defb 00dh,010h,00dh,014h	; 7297
	defb 00dh,01dh,00eh,0cfh	; 729b
	defb 0cfh,000h,012h,000h	; 729f
	defb 010h,00eh,011h,011h	; 72a3
	defb 00fh,018h,00eh,0cfh	; 72a7
	defb 0cfh	; 72ab

; ----------------------------------------------------------------------
; DATOS patrones_del_atleta: Los patrones de sprite de 16x16 comprimidos con
;   la racha de ceros de 0x5A78 ([0x00][cuantos]). Tambien se solapan: donde
;   dos figuras acaban igual, comparten bytes.
;   0x72ac..0x794d  (1697 bytes)
DATA_patrones_del_atleta:
	defb 000h,002h,005h,00dh,01fh,01bh,001h,006h	; 72ac  ........
	defb 0e0h,0e0h,080h,0c0h,0e0h,070h,020h,000h	; 72b4  .....p .
	defb 005h,040h,0c0h,080h,000h,001h,040h,0e7h	; 72bc  .@....@.
	defb 0f7h,073h,077h,03eh,01ch,000h,001h,0e0h	; 72c4  .sw>....
	defb 0e5h,0cdh,0dfh,0dbh,0e1h,06eh,078h,030h	; 72cc  .....nx0
	defb 020h,000h,005h,00eh,00eh,006h,006h,046h	; 72d4   ......F
	defb 0ceh,09eh,03ch,07ch,0f8h,0e0h,060h,000h	; 72dc  ..<|..`.
	defb 004h,03ch,07eh,0f3h,0f9h,0c1h,0c3h,0c7h	; 72e4  .<~.....
	defb 047h,007h,007h,003h,003h,000h,006h,080h	; 72ec  G.......
	defb 000h,002h,080h,080h,080h,0c0h,0c0h,0c0h	; 72f4  ........
	defb 0e0h,006h,00fh,00fh,00eh,01eh,01ch,01ch	; 72fc  ........
	defb 038h,038h,038h,030h,070h,0e0h,020h,000h	; 7304  8880p. .
	defb 003h,070h,078h,038h,03ch,01ch,01ch,038h	; 730c  .px8<..8
	defb 038h,070h,070h,0e0h,0c0h,000h,003h,018h	; 7314  8pp.....
	defb 00eh,07ch,019h,071h,038h,010h,0c0h,0e0h	; 731c  .|.q8...
	defb 0f0h,038h,008h,000h,006h,0c0h,0e0h,0e0h	; 7324  .8......
	defb 0e0h,0e0h,0e0h,060h,060h,078h,038h,018h	; 732c  ...``x8.
	defb 028h,069h,0fbh,0dfh,00ch,031h,003h,003h	; 7334  (i...1..
	defb 031h,070h,0f0h,0c0h,000h,006h,080h,0e0h	; 733c  1p......
	defb 070h,0b8h,0f8h,0f0h,0e0h,000h,007h,030h	; 7344  p......0
	defb 060h,03ch,030h,01ch,018h,0d0h,0e0h,0e0h	; 734c  `<0.....
	defb 000h,010h,030h,07bh,07bh,0f1h,0e0h,0e0h	; 7354  ..0{{...
	defb 071h,071h,03bh,03bh,01bh,01bh,000h,005h	; 735c  qq;;....
	defb 0c0h,0c0h,0e0h,0e0h,0e0h,0c0h,0c0h,080h	; 7364  ........
	defb 080h,000h,006h,001h,001h,006h,01fh,03fh	; 736c  .......?
	defb 0ffh,0ffh,07ch,03ch,010h,000h,005h,0f0h	; 7374  ..|<....
	defb 0f8h,03ch,07ch,00ch,00ch,08ch,088h,080h	; 737c  .<|.....
	defb 000h,002h,03eh,07fh,007h,007h,005h,021h	; 7384  ..>....!
	defb 073h,00eh,03eh,07eh,0feh,0feh,0feh,07eh	; 738c  s.>~...~
	defb 000h,004h,080h,080h,080h,080h,000h,008h	; 7394  ........
	defb 029h,068h,0fah,0deh,00ch,030h,003h,01bh	; 739c  )h...0..
	defb 038h,078h,0e0h,0c0h,000h,004h,0c0h,0e0h	; 73a4  8x......
	defb 070h,038h,078h,0f0h,0e0h,0c0h,000h,008h	; 73ac  p8x.....
	defb 020h,07fh,07fh,0ffh,0f7h,0e3h,0e3h,073h	; 73b4   ......s
	defb 071h,071h,030h,030h,000h,007h,080h,080h	; 73bc  qq00....
	defb 080h,080h,080h,0c0h,0e0h,060h,040h,000h	; 73c4  .....`@.
	defb 004h,028h,068h,0fah,0deh,00ch,030h,006h	; 73cc  .(h...0.
	defb 007h,007h,003h,043h,0c7h,0deh,01ch,018h	; 73d4  ...C....
	defb 000h,00ah,080h,080h,000h,005h,018h,00dh	; 73dc  ........
	defb 07dh,018h,070h,030h,0d0h,0e0h,0f8h,038h	; 73e4  }.p0...8
	defb 008h,000h,005h,0c0h,0e0h,0e0h,0e0h,0e0h	; 73ec  ........
	defb 0e0h,060h,060h,078h,038h,018h,0fch,0fch	; 73f4  .``x8...
	defb 0fch,07ch,000h,01ch,03eh,07eh,0fch,0fch	; 73fc  .|..>~..
	defb 0fch,070h,000h,019h,020h,03fh,03fh,03fh	; 7404  .p.. ???
	defb 03fh,01fh,01fh,01fh,01dh,00fh,00eh,00ch	; 740c  ?.......
	defb 000h,009h,080h,080h,080h,0c0h,0c0h,0c0h	; 7414  ........
	defb 0c0h,080h,000h,003h,04fh,038h,040h,0e0h	; 741c  ....O8@.
	defb 000h,009h,038h,07ch,0fch,074h,038h,000h	; 7424  ..8|.t8.
	defb 00bh,000h,00ch,080h,0e0h,070h,000h,00ah	; 742c  .....p..
	defb 0c0h,060h,030h,000h,004h,000h,00dh,006h	; 7434  .`0.....
	defb 007h,00fh,000h,00dh,010h,030h,0e0h,0fch	; 743c  .....0..
	defb 0fch,0fch,0f8h,000h,01ch,002h,002h,00bh	; 7444  ........
	defb 00fh,006h,009h,01ch,038h,070h,0e0h,0e0h	; 744c  ....8p..
	defb 070h,038h,038h,000h,002h,080h,0c0h,0e0h	; 7454  p88.....
	defb 060h,000h,001h,080h,000h,001h,018h,018h	; 745c  `.......
	defb 078h,070h,040h,000h,004h,00fh,00fh,01eh	; 7464  xp@.....
	defb 03ch,078h,0e0h,0c0h,000h,008h,070h,0f8h	; 746c  <x....p.
	defb 07ch,03eh,01eh,03ch,078h,0e0h,0c0h,000h	; 7474  |>.<x...
	defb 007h,00fh,01eh,01eh,01ah,018h,004h,01fh	; 747c  ........
	defb 038h,070h,071h,0e1h,060h,020h,000h,002h	; 7484  8pq.` ..
	defb 0c0h,0e0h,000h,003h,040h,0e0h,000h,001h	; 748c  ....@...
	defb 080h,000h,007h,005h,005h,017h,002h,018h	; 7494  ........
	defb 03eh,01fh,007h,001h,000h,002h,07fh,0ffh	; 749c  >.......
	defb 0ffh,0fch,000h,002h,080h,0c0h,0c0h,000h	; 74a4  ........
	defb 001h,00ch,0fch,0fch,080h,000h,001h,030h	; 74ac  .......0
	defb 0ffh,0ffh,0deh,000h,002h,001h,01dh,0ffh	; 74b4  ........
	defb 0ffh,00fh,000h,009h,041h,0ffh,0f3h,0e0h	; 74bc  ....A...
	defb 0c0h,080h,000h,00ah,00bh,02fh,03dh,018h	; 74c4  ...../=.
	defb 006h,018h,038h,0b8h,09ch,09fh,08fh,000h	; 74cc  ..8.....
	defb 006h,080h,080h,000h,005h,0c0h,0c0h,0c0h	; 74d4  ........
	defb 000h,004h,001h,001h,005h,007h,003h,018h	; 74dc  ........
	defb 071h,0f3h,0c3h,0e1h,070h,030h,030h,000h	; 74e4  q...p00.
	defb 003h,040h,060h,0f0h,0b0h,00eh,00eh,016h	; 74ec  .@`.....
	defb 01ch,0dch,0f8h,070h,000h,005h,070h,061h	; 74f4  ...p..pa
	defb 083h,007h,006h,007h,003h,001h,000h,003h	; 74fc  ........
	defb 028h,02ch,0beh,0f6h,060h,078h,080h,080h	; 7504  (,..`x..
	defb 080h,030h,070h,0f0h,080h,000h,003h,063h	; 750c  .0p....c
	defb 073h,03fh,01fh,007h,03ch,078h,0e0h,0c0h	; 7514  s?..<x..
	defb 000h,006h,0e0h,0c0h,0c0h,080h,080h,000h	; 751c  ........
	defb 00bh,0c0h,0c0h,0c0h,060h,000h,00eh,008h	; 7524  ....`...
	defb 01eh,000h,00ch,080h,080h,0e0h,070h,000h	; 752c  ......p.
	defb 00eh,038h,03ch,07fh,07fh,037h,01fh,03eh	; 7534  .8<..7.>
	defb 07ch,0f0h,000h,00ah,080h,080h,000h,00ch	; 753c  |.......
	defb 0fch,0fch,0fch,0f8h,000h,010h,060h,0c0h	; 7544  ......`.
	defb 0c0h,0c0h,080h,000h,01bh,0e0h,0f0h,0f8h	; 754c  ........
	defb 078h,038h,03ch,01ch,00eh,004h,000h,017h	; 7554  x8<.....
	defb 030h,070h,0c0h,040h,000h,019h,038h,03ch	; 755c  0p.@..8<
	defb 000h,001h,03fh,03fh,03dh,03fh,03fh,07fh	; 7564  ..??=??.
	defb 06ch,060h,060h,0c0h,040h,000h,004h,0c0h	; 756c  l``.@...
	defb 0e0h,0e0h,0e0h,0c0h,000h,00bh,080h,0c1h	; 7574  ........
	defb 0e3h,077h,000h,00ch,080h,080h,000h,00eh	; 757c  .w......
	defb 070h,0f0h,000h,00dh,030h,070h,0e0h,040h	; 7584  p...0p.@
	defb 000h,009h,007h,007h,000h,00fh,080h,000h	; 758c  ........
	defb 001h,004h,006h,037h,0ffh,0ffh,00eh,000h	; 7594  ...7....
	defb 009h,01eh,03eh,076h,09ch,03ch,038h,010h	; 759c  ..>v.<8.
	defb 000h,009h,00ah,00bh,02fh,03dh,018h,0deh	; 75a4  ..../=..
	defb 0e0h,000h,00bh,080h,080h,000h,003h,007h	; 75ac  ........
	defb 00fh,00fh,00dh,00fh,00ch,018h,03ch,07fh	; 75b4  ......<.
	defb 0ffh,0feh,080h,000h,003h,0e0h,0f0h,000h	; 75bc  ........
	defb 003h,0a0h,0f0h,000h,009h,0ffh,0ffh,0ffh	; 75c4  ........
	defb 07ch,000h,00dh,080h,000h,00eh,077h,0f7h	; 75cc  |.....w.
	defb 000h,00fh,080h,080h,0c0h,0e0h,000h,00eh	; 75d4  ........
	defb 080h,0f0h,000h,00ch,03eh,07fh,0f0h,0f0h	; 75dc  ....>...
	defb 0d0h,0c2h,067h,008h,044h,040h,060h,07ch	; 75e4  ..g.D@`|
	defb 07fh,03fh,018h,000h,00eh,080h,000h,002h	; 75ec  .?......
	defb 03ch,07eh,0f2h,0f8h,0c1h,0c3h,0c7h,043h	; 75f4  <~.....C
	defb 007h,007h,007h,007h,003h,003h,000h,006h	; 75fc  ........
	defb 080h,000h,002h,080h,080h,080h,0c0h,0c0h	; 7604  ........
	defb 0c0h,0e0h,0e0h,0e0h,0c0h,0e0h,0e0h,060h	; 760c  .......`
	defb 060h,060h,0b0h,000h,016h,038h,070h,0c0h	; 7614  ``...8p.
	defb 000h,01dh,002h,0deh,0feh,0feh,07eh,07ch	; 761c  ......~|
	defb 03ch,01ch,018h,018h,038h,030h,000h,014h	; 7624  <...80..
	defb 030h,0f8h,0fch,0ffh,0fch,078h,030h,000h	; 762c  0....x0.
	defb 019h,0e0h,0c0h,0e0h,0e0h,060h,060h,060h	; 7634  .....```
	defb 0e0h,000h,018h,040h,0f0h,0f8h,0fch,0f8h	; 763c  ...@....
	defb 070h,010h,000h,019h,00eh,01fh,01fh,00fh	; 7644  p.......
	defb 00bh,00fh,01fh,03ch,078h,0e0h,040h,000h	; 764c  ...<x.@.
	defb 007h,080h,0c0h,0c0h,080h,000h,00ah,00bh	; 7654  ........
	defb 02fh,03dh,018h,006h,0c0h,070h,0f0h,0e0h	; 765c  /=...p..
	defb 0e1h,071h,03dh,01ch,00ch,000h,003h,080h	; 7664  .q=.....
	defb 080h,000h,007h,080h,080h,000h,003h,018h	; 766c  ........
	defb 00dh,001h,000h,00eh,0c0h,0e0h,000h,00ch	; 7674  ........
	defb 08dh,0c6h,0e0h,070h,000h,01ch,0a1h,0e0h	; 767c  ...p....
	defb 0f0h,038h,01ch,00eh,007h,003h,003h,000h	; 7684  .8......
	defb 007h,040h,000h,002h,0a0h,0f0h,0f8h,0d8h	; 768c  .@......
	defb 080h,060h,000h,007h,03eh,07fh,070h,030h	; 7694  .`..>.p0
	defb 010h,082h,047h,008h,03eh,03fh,03fh,01fh	; 769c  ..G.>??.
	defb 01fh,000h,00dh,080h,080h,080h,000h,003h	; 76a4  ........
	defb 0feh,0feh,0feh,07ch,000h,01ch,060h,0c0h	; 76ac  ...|..`.
	defb 0c0h,0c0h,080h,000h,003h,080h,080h,0c0h	; 76b4  ........
	defb 0c0h,000h,014h,07ch,0f0h,0e0h,0e0h,060h	; 76bc  ...|...`
	defb 000h,01bh,080h,080h,000h,01eh,040h,0c0h	; 76c4  ......@.
	defb 0c0h,0c0h,000h,01ch,00ah,00bh,02fh,03dh	; 76cc  ....../=
	defb 018h,006h,038h,078h,073h,0e7h,0ffh,0f8h	; 76d4  ..8xs...
	defb 070h,040h,000h,004h,080h,080h,000h,00ch	; 76dc  p@......
	defb 030h,078h,07eh,0feh,0fch,0f8h,078h,000h	; 76e4  0x~...x.
	defb 019h,080h,0c0h,0e0h,000h,01dh,03eh,03eh	; 76ec  ......>>
	defb 01eh,00eh,01ch,01ch,03ch,07ch,07ch,06ch	; 76f4  ....<||l
	defb 00ch,000h,015h,028h,02ch,0beh,0f6h,060h	; 76fc  ...(,..`
	defb 0d8h,0e0h,0fch,07fh,00fh,000h,00dh,020h	; 7704  ....... 
	defb 0f0h,0f0h,070h,000h,005h,005h,017h,01eh	; 770c  ..p.....
	defb 00ch,003h,018h,01ch,038h,070h,060h,070h	; 7714  ....8p`p
	defb 030h,038h,018h,018h,000h,001h,080h,0c0h	; 771c  08......
	defb 0c0h,000h,00ch,080h,0c1h,063h,077h,000h	; 7724  .....cw.
	defb 00ch,080h,080h,080h,000h,00dh,040h,040h	; 772c  ......@@
	defb 00ch,080h,080h,080h,080h,080h,0c0h,000h	; 7734  ........
	defb 007h,080h,080h,000h,001h,040h,040h,040h	; 773c  .....@@@
	defb 040h,040h,0c0h,000h,007h,03ch,07eh,0ffh	; 7744  @@...<~.
	defb 0ffh,07eh,07eh,024h,0ffh,0ffh,0ffh,0ffh	; 774c  .~~$....
	defb 0ffh,07eh,07eh,000h,012h,0feh,0feh,0feh	; 7754  .~~.....
	defb 0feh,000h,01ch,0ffh,0ffh,0ffh,07eh,03eh	; 775c  ......~>
	defb 07eh,06ch,06ch,00ch,00ch,00ch,000h,015h	; 7764  ~ll.....
	defb 0c0h,0c4h,0e4h,018h,000h,01ch,0feh,0ffh	; 776c  ........
	defb 07fh,01fh,000h,01ch,03eh,07fh,007h,007h	; 7774  ....>...
	defb 005h,021h,073h,008h,011h,001h,003h,01fh	; 777c  .!s.....
	defb 07fh,0feh,00ch,000h,003h,080h,080h,080h	; 7784  ........
	defb 080h,000h,00ah,02dh,06dh,07fh,02dh,0b2h	; 778c  ...-m.-.
	defb 0cch,0c0h,0c0h,0e1h,073h,033h,03fh,000h	; 7794  ....s3?.
	defb 005h,080h,080h,000h,001h,0c0h,0c0h,0c0h	; 779c  ........
	defb 0c0h,0c0h,080h,000h,006h,00fh,01fh,03fh	; 77a4  .......?
	defb 03bh,03fh,01fh,01eh,01ch,01ch,03eh,074h	; 77ac  ;?....>t
	defb 020h,000h,005h,0f0h,0e0h,0c0h,080h,000h	; 77b4   .......
	defb 00ah,03ch,07eh,0ffh,081h,000h,002h,024h	; 77bc  .<~....$
	defb 05ah,066h,07eh,07eh,03ch,018h,05ah,000h	; 77c4  Zf~~<.Z.
	defb 012h,0ffh,0ffh,0ffh,07eh,07ch,07eh,03eh	; 77cc  ....~|~>
	defb 036h,036h,010h,000h,016h,0dch,0e0h,060h	; 77d4  66.....`
	defb 000h,01dh,060h,060h,060h,000h,001h,080h	; 77dc  ..```...
	defb 0e0h,070h,000h,019h,000h,001h,003h,02bh	; 77e4  .p.....+
	defb 02ch,0beh,0f6h,067h,07fh,0fch,0f8h,0e0h	; 77ec  ,..g....
	defb 000h,005h,0f0h,0f8h,018h,000h,001h,020h	; 77f4  ....... 
	defb 0f8h,0f0h,080h,000h,008h,000h,009h,008h	; 77fc  ........
	defb 00ch,006h,080h,0c0h,060h,030h,000h,010h	; 7804  ....`0..
	defb 000h,002h,03eh,07fh,0f0h,0f0h,0d0h,0c2h	; 780c  ..>.....
	defb 067h,038h,07ch,07eh,07eh,07eh,07eh,07eh	; 7814  g8|~~~~~
	defb 000h,010h,000h,005h,010h,030h,060h,0c0h	; 781c  .....0`.
	defb 000h,017h,000h,002h,07ch,0feh,00fh,00fh	; 7824  ....|...
	defb 00bh,043h,0e6h,01ch,03eh,07eh,07eh,07eh	; 782c  .C..>~~~
	defb 07eh,07eh,000h,010h,000h,002h,00fh,01eh	; 7834  ~~......
	defb 01eh,01ch,03ch,038h,078h,070h,0e0h,0c0h	; 783c  ..<8xp..
	defb 0c0h,000h,003h,030h,078h,0fch,07ch,01ch	; 7844  ...0x.|.
	defb 038h,078h,070h,0e0h,040h,000h,006h,00fh	; 784c  8xp.@...
	defb 0ffh,07bh,03dh,01fh,00fh,007h,003h,003h	; 7854  .{=.....
	defb 007h,002h,000h,006h,080h,0c0h,0c0h,0c0h	; 785c  ........
	defb 080h,080h,080h,080h,0c0h,0e0h,040h,000h	; 7864  ......@.
	defb 003h,001h,001h,005h,007h,003h,000h,001h	; 786c  ........
	defb 03ch,07eh,0e0h,0c0h,0d8h,0f8h,038h,000h	; 7874  <~....8.
	defb 003h,040h,060h,0f0h,0beh,00eh,0c6h,00eh	; 787c  .@`.....
	defb 01ch,038h,038h,030h,000h,005h,00dh,01fh	; 7884  .880....
	defb 01bh,001h,006h,001h,007h,01fh,03ch,0f0h	; 788c  ......<.
	defb 0c0h,0c0h,000h,005h,040h,0c0h,080h,0c0h	; 7894  ....@...
	defb 0c0h,0c0h,080h,000h,007h,001h,001h,005h	; 789c  ........
	defb 007h,003h,000h,001h,011h,033h,073h,0e1h	; 78a4  .....3s.
	defb 061h,070h,030h,000h,003h,040h,060h,0f0h	; 78ac  ap0..@`.
	defb 0b0h,000h,001h,0c0h,080h,01eh,01eh,0deh	; 78b4  ........
	defb 0f8h,0f0h,000h,004h,000h,001h,023h,0e7h	; 78bc  ......#.
	defb 077h,07fh,03fh,01eh,00ch,000h,008h,00ch	; 78c4  w.?.....
	defb 0fch,09ch,09eh,00eh,00eh,00eh,007h,003h	; 78cc  ........
	defb 003h,000h,006h,000h,008h,010h,0f0h,0e0h	; 78d4  ........
	defb 000h,015h,000h,001h,0dfh,0dfh,0fdh,079h	; 78dc  .......y
	defb 078h,030h,000h,009h,080h,0c0h,0c0h,0e0h	; 78e4  x0......
	defb 0e0h,0f0h,070h,0e0h,0e0h,0c0h,0c0h,0c0h	; 78ec  ..p.....
	defb 000h,004h,000h,001h,001h,003h,007h,007h	; 78f4  ........
	defb 05eh,07eh,0ffh,0f9h,0f8h,078h,008h,000h	; 78fc  ^~...x..
	defb 005h,0f0h,0f8h,080h,080h,080h,010h,038h	; 7904  .......8
	defb 000h,008h,000h,001h,001h,003h,003h,003h	; 790c  ........
	defb 003h,007h,00fh,01eh,07ch,0f8h,0f8h,038h	; 7914  ....|..8
	defb 018h,000h,002h,0f8h,0fch,0c0h,0c0h,040h	; 791c  .......@
	defb 008h,09ch,080h,000h,008h,000h,001h,01fh	; 7924  ........
	defb 01fh,01fh,01fh,01eh,01eh,03ch,038h,070h	; 792c  .....<8p
	defb 0e0h,0c0h,000h,004h,080h,080h,080h,000h	; 7934  ........
	defb 00dh,03eh,07fh,0f0h,0f0h,0d0h,0c2h,066h	; 793c  .>.....f
	defb 020h,040h,040h,046h,03fh,03fh,03fh,000h	; 7944   @@F???.
	defb 012h	; 794c

; ----------------------------------------------------------------------
; DATOS posturas_del_objeto: Seis punteros a patrones que 0x6827 sube a 0x1800
;   para el objeto que vuela.
;   0x794d..0x7959  (12 bytes)
DATA_posturas_del_objeto:
	defw 07959h	; 794d  -> DATA_patrones_del_objeto
	defw 07969h	; 794f
	defw 0797ah	; 7951
	defw 0797ch	; 7953
	defw 0798bh	; 7955
	defw 0741eh	; 7957

; ----------------------------------------------------------------------
; DATOS patrones_del_objeto: Los patrones del objeto que vuela, comprimidos
;   igual.
;   0x7959..0x7992  (57 bytes)
DATA_patrones_del_objeto:
	defb 000h,005h,0c0h,0a0h,0bfh,0a0h,0c0h,000h	; 7959  ........
	defb 00bh,01ch,03eh,0feh,03ah,01ch,000h,006h	; 7961  ..>.:...
	defb 020h,020h,020h,0f0h,010h,010h,010h,010h	; 7969     .....
	defb 010h,010h,038h,07ch,07ch,074h,038h,000h	; 7971  ..8||t8.
	defb 011h,000h,020h,000h,002h,070h,0fbh,0feh	; 7979  .. ..p..
	defb 0e8h,070h,000h,009h,00ch,010h,070h,0d8h	; 7981  .p....p.
	defb 000h,00ch,070h,0f8h,0f8h,0e8h,070h,000h	; 7989  ..p...p.
	defb 01bh	; 7991

; ----------------------------------------------------------------------
; DATOS patron_en_blanco: Un patron de sprite entero a cero (0x66F7), para
;   borrar.
;   0x7992..0x7997  (5 bytes)
DATA_patron_en_blanco:
	defb 0f0h,0fch,078h,000h,01dh	; 7992

; ======================================================================
; CODIGO 0x7997..0x7b28  (401 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  LOS ACTORES  ==========
; Un actor es una ficha de dieciseis bytes en RAM (0xE120, 0xE130,
; 0xE140 y 0xE150) con: +0 banderas, +1 cuenta, +2 escalon, +6 columna
; dentro de la figura, +7/+8 direccion de VRAM, +9/+0A la ficha que le
; releva, +0B la fila de la tabla de ajuste, +0C columna calculada,
; +0D/+0E la figura y +0F cuantos caracteres se pintan.
; Las cuatro fichas van SEGUIDAS en memoria, y de ahi el truco: el bit 2
; hace que el actor empuje al de DELANTE y el bit 3 al de DETRAS,
; sumando o restando 0x11 al puntero. Asi se arrastran unos a otros.
; ----------------------------------------------------------------------
MUEVE_Y_PINTA_UN_ACTOR:
	push hl			;7997   ; IX apunta a la ficha
	pop ix		;7998
	inc hl			;799a
	ld a,(hl)			;799b   ; la cuenta
	cp 002h		;799c
	ret c			;799e   ; por debajo de dos no se mueve
	call ADELANTA_LA_ANIMACION		;799f   ; adelanta la animacion
	call CALCULA_LA_COLUMNA		;79a2   ; y calcula en que columna cae
PINTA_SI_ESTA_ENCENDIDO:
	bit 0,(ix+000h)		;79a5   ; bit 0: el actor esta encendido
	ret z			;79a9
PINTA_UN_ACTOR:
	call MONTA_LA_FIGURA		;79aa   ; monta la figura en el papel
	jp SUBE_LA_FIGURA		;79ad   ; y la sube a la VRAM
ADELANTA_LA_ANIMACION:
	push ix		;79b0
	pop hl			;79b2
	inc hl			;79b3   ; la cuenta
	ld a,(hl)			;79b4
	cp 002h		;79b5
	ret c			;79b7   ; por debajo de dos se acabo
	dec (hl)			;79b8   ; baja de dos en dos
	dec (hl)			;79b9
	inc hl			;79ba
	inc (hl)			;79bb   ; y el escalon sube de uno en uno
	bit 2,(ix+000h)		;79bc   ; bit 2: empuja al actor de delante
	jr nz,MIRA_SI_EMPUJA_AL_DE_DETRAS		;79c0
	push hl			;79c2
	ld de,00011h		;79c3   ; 0x11 hacia atras es la cuenta de la ficha anterior
	sbc hl,de		;79c6
	ld a,l			;79c8
	cp 011h		;79c9   ; salvo en la primera, que no tiene anterior
	jr z,NO_HAY_ACTOR_DELANTE		;79cb
	inc (hl)			;79cd
NO_HAY_ACTOR_DELANTE:
	pop hl			;79ce
MIRA_SI_EMPUJA_AL_DE_DETRAS:
	bit 3,(ix+000h)		;79cf   ; bit 3: empuja al de detras
	jr z,MIRA_EL_ESCALON		;79d3
	push hl			;79d5
	ld de,0000fh		;79d6   ; 0x0F hacia delante es la cuenta de la siguiente
	add hl,de			;79d9
	inc (hl)			;79da   ; y la sube de dos en dos
	inc (hl)			;79db
	pop hl			;79dc
MIRA_EL_ESCALON:
	ld a,(hl)			;79dd   ; el escalon
	inc hl			;79de
	inc (hl)			;79df   ; la columna sube de dos en dos
	inc (hl)			;79e0
	cp 004h		;79e1   ; hasta cuatro escalones se sigue moviendo
	jr c,ADELANTA_LA_ANIMACION		;79e3
	dec hl			;79e5
	xor a			;79e6   ; el escalon se reinicia
	ld (hl),a			;79e7
	bit 1,(ix+000h)		;79e8   ; bit 1: el actor solo se dibuja, no se anima
	ret nz			;79ec
	bit 0,(ix+000h)		;79ed   ; bit 0: encendido
	jr z,GASTA_LA_ESPERA_DEL_ACTOR		;79f1
	dec (ix+00fh)		;79f3
	jr nz,DESPLAZA_EL_ACTOR		;79f6
	inc (ix+00fh)		;79f8
DESPLAZA_EL_ACTOR:
	ld bc,00005h		;79fb   ; cinco bytes mas alla
	add hl,bc			;79fe
	dec (hl)			;79ff   ; la parte baja de la direccion de VRAM
	ld a,(hl)			;7a00
	and 01fh		;7a01   ; los cinco bits de la fila
	cp 01fh		;7a03
	jr nz,ADELANTA_LA_ANIMACION		;7a05
	inc (hl)			;7a07   ; al pasar de 0x1F se sube una fila
	dec hl			;7a08
	inc (hl)			;7a09
	jr ADELANTA_LA_ANIMACION		;7a0a
GASTA_LA_ESPERA_DEL_ACTOR:
	inc hl			;7a0c
	inc hl			;7a0d
	dec (hl)			;7a0e   ; la espera corta
	jr nz,ADELANTA_LA_ANIMACION		;7a0f
	inc hl			;7a11
	ld a,(hl)			;7a12   ; y la larga
	or a			;7a13
	jr z,ENCIENDE_EL_ACTOR		;7a14
	dec (hl)			;7a16
	jr nz,ADELANTA_LA_ANIMACION		;7a17
ENCIENDE_EL_ACTOR:
	set 0,(ix+000h)		;7a19   ; al acabarse, el actor se enciende
	jr ADELANTA_LA_ANIMACION		;7a1d
MONTA_LA_FIGURA:
	ld l,(ix+00dh)		;7a1f   ; el puntero a la figura
	ld h,(ix+00eh)		;7a22
	ld de,0e230h		;7a25   ; el papel donde se monta
UNA_ORDEN_DE_LA_FIGURA:
	ld a,(hl)			;7a28
	or a			;7a29
	jr z,REPITE_UN_CODIGO		;7a2a   ; 0x00 repite un codigo
	cp 001h		;7a2c
	jr z,REPITE_SUBIENDO		;7a2e   ; 0x01 lo repite subiendo
	cp 002h		;7a30
	jr z,CAMBIA_EL_DESPLAZAMIENTO		;7a32   ; 0x02 cambia el desplazamiento
	cp 0ffh		;7a34   ; 0xFF acaba la fila
	jr z,ACABA_LA_FILA		;7a36
	add a,c			;7a38   ; y cualquier otro va con su desplazamiento
	ld (de),a			;7a39
	inc de			;7a3a
	inc hl			;7a3b
	jr UNA_ORDEN_DE_LA_FIGURA		;7a3c
REPITE_UN_CODIGO:
	inc hl			;7a3e
	ld a,(hl)			;7a3f   ; el codigo
	inc hl			;7a40
	ld b,(hl)			;7a41   ; y cuantas veces
	add a,c			;7a42
SUELTA_EL_CODIGO:
	ld (de),a			;7a43
	inc de			;7a44
	djnz SUELTA_EL_CODIGO		;7a45
	inc hl			;7a47
	jr UNA_ORDEN_DE_LA_FIGURA		;7a48
REPITE_SUBIENDO:
	inc hl			;7a4a
	ld a,(hl)			;7a4b   ; el primer codigo
	inc hl			;7a4c
	ld b,(hl)			;7a4d   ; y cuantos
	add a,c			;7a4e
SUELTA_UNO_MAS:
	ld (de),a			;7a4f
	inc a			;7a50   ; cada uno es el siguiente del anterior
	inc de			;7a51
	djnz SUELTA_UNO_MAS		;7a52
	inc hl			;7a54
	jr UNA_ORDEN_DE_LA_FIGURA		;7a55
CAMBIA_EL_DESPLAZAMIENTO:
	inc hl			;7a57
	ld c,(hl)			;7a58   ; el paso
	ld b,(ix+002h)		;7a59   ; por el escalon del actor
	xor a			;7a5c
	inc b			;7a5d
	dec b			;7a5e
	jr z,GUARDA_EL_DESPLAZAMIENTO		;7a5f
MULTIPLICA_EL_PASO:
	add a,c			;7a61
	djnz MULTIPLICA_EL_PASO		;7a62
GUARDA_EL_DESPLAZAMIENTO:
	ld c,a			;7a64
	inc hl			;7a65
	jr UNA_ORDEN_DE_LA_FIGURA		;7a66
ACABA_LA_FILA:
	ld (de),a			;7a68   ; dos 0xFF cierran la fila
	inc de			;7a69
	ld (de),a			;7a6a
	inc hl			;7a6b
	inc de			;7a6c
	ld a,(hl)			;7a6d   ; y otro 0xFF detras cierra la figura
	inc a			;7a6e
	jr nz,UNA_ORDEN_DE_LA_FIGURA		;7a6f
	dec a			;7a71
	ld (de),a			;7a72   ; con un tercero de cierre
	ret			;7a73
SUBE_LA_FIGURA:
	exx			;7a74
	ld a,(00006h)		;7a75   ; el puerto de datos del VDP
	ld c,a			;7a78
	exx			;7a79
	ld hl,0e230h		;7a7a   ; el papel
	ld a,(ix+006h)		;7a7d   ; empezando en la columna del actor
	call SUMA_A_A_HL		;7a80
	ld b,(ix+00fh)		;7a83   ; cuantos caracteres caben
	ld a,(hl)			;7a86
	inc a			;7a87   ; con 0xFF ya no hay figura
	jr z,MIRA_LA_FICHA_DE_RELEVO		;7a88
	ld e,(ix+007h)		;7a8a   ; la direccion de VRAM del actor
	ld d,(ix+008h)		;7a8d
	call FIJA_ESCRITURA_CON_CANDADO		;7a90
	bit 1,(ix+000h)		;7a93   ; bit 1: se sube tal cual, sin recortar
	jr nz,SUBE_LA_FIGURA_ENTERA		;7a97
SUBE_UNA_FILA_DE_LA_FIGURA:
	ld a,(hl)			;7a99
	cp 0ffh		;7a9a   ; 0xFF acaba la fila
	jr z,SIGUIENTE_FILA		;7a9c
	inc b			;7a9e
	dec b			;7a9f   ; mientras el ancho no se agote
	jr z,SIGUIENTE_CARACTER_DE_LA_FILA		;7aa0
	inc b			;7aa2
	exx			;7aa3
	out (c),a		;7aa4   ; el codigo va a la VRAM
	exx			;7aa6
SIGUIENTE_CARACTER_DE_LA_FILA:
	inc hl			;7aa7
	jr SUBE_UNA_FILA_DE_LA_FIGURA		;7aa8
SIGUIENTE_FILA:
	inc hl			;7aaa
	inc hl			;7aab
	ld a,(hl)			;7aac   ; otro 0xFF cierra la figura
	inc a			;7aad
	ret z			;7aae
	ld b,(ix+00fh)		;7aaf   ; el ancho otra vez
	call BAJA_UNA_FILA		;7ab2   ; baja una fila en la VRAM
	call FIJA_ESCRITURA_CON_CANDADO		;7ab5
	ld a,(ix+006h)		;7ab8   ; y vuelve a la columna del actor
	call SUMA_A_A_HL		;7abb
	jr SUBE_UNA_FILA_DE_LA_FIGURA		;7abe
MIRA_LA_FICHA_DE_RELEVO:
	ld l,(ix+009h)		;7ac0   ; la ficha que releva a esta
	ld h,(ix+00ah)		;7ac3
	ld a,h			;7ac6
	inc a			;7ac7   ; 0xFFxx: hay que borrar
	jr z,BORRA_EL_ACTOR		;7ac8
	dec a			;7aca
	jr z,APAGA_EL_ACTOR		;7acb   ; 0x00xx: hay que apagar
	push ix		;7acd
	pop de			;7acf
	jp COPIA_UNA_FICHA		;7ad0   ; y si no, se carga encima
BORRA_EL_ACTOR:
	ld a,(ix+007h)		;7ad3
	or 01fh		;7ad6   ; la columna se lleva al final de la fila
	ld (ix+007h),a		;7ad8
	xor a			;7adb
	ld (ix+006h),a		;7adc   ; y el actor se queda sin figura
	dec a			;7adf
	ld (ix+00fh),a		;7ae0   ; con el ancho a 0xFF
	ret			;7ae3
APAGA_EL_ACTOR:
	ld a,0ffh		;7ae4
	ld (ix+006h),a		;7ae6   ; sin figura
	res 0,(ix+000h)		;7ae9   ; y apagado
	ret			;7aed
SUBE_LA_FIGURA_ENTERA:
	ld a,(hl)			;7aee
	ld b,020h		;7aef   ; 0x20 caracteres, la fila entera
	call REPITE_BYTE		;7af1
	inc hl			;7af4
	ld a,(hl)			;7af5
	inc a			;7af6   ; hasta el 0xFF
	jr nz,SUBE_LA_FIGURA_ENTERA		;7af7
	ret			;7af9
CALCULA_LA_COLUMNA:
	bit 0,(ix+000h)		;7afa   ; bit 0: apagado
	jr nz,COLUMNA_DEL_ACTOR		;7afe
	ld (ix+00ch),0ffh		;7b00   ; y entonces no se pinta nada
	ret			;7b04
COLUMNA_DEL_ACTOR:
	ld a,(ix+007h)		;7b05   ; la parte baja de la direccion de VRAM
	and 01fh		;7b08   ; los cinco bits de la columna
	cp 01eh		;7b0a   ; de 0x1E en adelante no cabe
	ret nc			;7b0c
	rlca			;7b0d   ; por ocho
	rlca			;7b0e
	rlca			;7b0f
	ld c,a			;7b10
	ld hl,07b28h		;7b11   ; la tabla de ajuste
	ld a,(ix+00bh)		;7b14   ; con la fila que diga la ficha
	call SUMA_A_A_HL		;7b17
	ld a,(hl)			;7b1a   ; se le suma
	add a,c			;7b1b
	ld c,a			;7b1c
	ld a,(ix+002h)		;7b1d   ; y el escalon cuenta doble
	add a,a			;7b20
	ld b,a			;7b21
	ld a,c			;7b22
	sub b			;7b23
	ld (ix+00ch),a		;7b24
	ret			;7b27

; ----------------------------------------------------------------------
; DATOS ajuste_de_la_figura: Cuatro bytes que 0x7B11 suma al calcular en que
;   columna cae la figura.
;   0x7b28..0x7b2c  (4 bytes)
DATA_ajuste_de_la_figura:
	defb 000h,000h,010h,004h	; 7b28

; ======================================================================
; CODIGO 0x7b2c..0x7b46  (26 bytes)
; ======================================================================


MONTA_LOS_ACTORES_DE_LA_PRUEBA:
	ld hl,07bfbh		;7b2c   ; la ficha del atleta
	ld de,0e120h		;7b2f   ; siempre va en 0xE120
	call COPIA_UNA_FICHA		;7b32
	ld hl,07b44h		;7b35   ; y la cadena de esta prueba
	call CASILLA_DE_LA_PRUEBA		;7b38
	ld de,0e130h		;7b3b   ; empezando en 0xE130
MONTA_UNA_FICHA_MAS:
	call COPIA_UNA_FICHA		;7b3e   ; cada una se lleva los dieciseis bytes siguientes
	ld a,(hl)			;7b41   ; hasta el 0xFF
	inc a			;7b42
	jr nz,MONTA_UNA_FICHA_MAS		;7b43
	ret			;7b45

; ----------------------------------------------------------------------
; DATOS fichas_de_la_prueba: Un puntero por prueba a la cadena de fichas de
;   actor que se copia a 0xE130 en adelante. 0x7B35 los indexa desde uno, con
;   la direccion dos bytes antes.
;   0x7b46..0x7b4e  (8 bytes)
DATA_fichas_de_la_prueba:
	defw 07c06h	; 7b46  -> DATA_fichas_de_los_100_metros
	defw 07bd0h	; 7b48  -> DATA_fichas_del_salto_de_longitud
	defw 07ca9h	; 7b4a  -> DATA_fichas_del_martillo
	defw 07ce8h	; 7b4c  -> DATA_fichas_de_los_400_metros

; ======================================================================
; CODIGO 0x7b4e..0x7b65  (23 bytes)
; ======================================================================


COPIA_UNA_FICHA:
	ld c,010h		;7b4e   ; dieciseis bytes por ficha
UN_BYTE_DE_LA_FICHA:
	ld a,(hl)			;7b50
	or a			;7b51   ; el cero abre una racha
	jr z,RACHA_DE_CEROS		;7b52
	ld (de),a			;7b54
	inc de			;7b55
	inc hl			;7b56
	dec c			;7b57
	jr nz,UN_BYTE_DE_LA_FICHA		;7b58
	ret			;7b5a
RACHA_DE_CEROS:
	inc hl			;7b5b
	ld b,(hl)			;7b5c   ; cuantos
	inc hl			;7b5d
SUELTA_UN_CERO:
	ld (de),a			;7b5e
	dec c			;7b5f
	inc de			;7b60
	djnz SUELTA_UN_CERO		;7b61
	jr UN_BYTE_DE_LA_FICHA		;7b63

; ----------------------------------------------------------------------
; DATOS figuras_del_decorado: Las figuras que 0x7A1F expande a codigos de
;   caracter: 0x00 repite uno, 0x01 los repite subiendo, 0x02 cambia el
;   desplazamiento, 0xFF acaba fila y 0xFF 0xFF acaba la figura.
;   0x7b65..0x7bd0  (107 bytes)
DATA_figuras_del_decorado:
	defb 002h,00ah,001h,038h,00ah,002h,000h,038h	; 7b65  ...8...8
	defb 038h,038h,002h,005h,001h,020h,005h,002h	; 7b6d  88... ..
	defb 000h,038h,0ffh,0ffh,002h,000h,05ch,05ch	; 7b75  .8....\\
	defb 002h,011h,001h,05ch,011h,002h,000h,05ch	; 7b7d  ...\...\
	defb 05ch,0ffh,0ffh,002h,000h,028h,028h,002h	; 7b85  \....((.
	defb 002h,028h,029h,002h,000h,02fh,02fh,0ffh	; 7b8d  .()..//.
	defb 002h,003h,004h,005h,030h,031h,032h,002h	; 7b95  ....012.
	defb 001h,0b1h,0ffh,002h,003h,010h,011h,012h	; 7b9d  ........
	defb 03ch,03dh,03eh,002h,001h,0b1h,0ffh,002h	; 7ba5  <=>.....
	defb 000h,01ch,002h,003h,01ch,01dh,01eh,048h	; 7bad  .......H
	defb 049h,04ah,002h,001h,0b1h,0ffh,002h,001h	; 7bb5  IJ......
	defb 000h,0adh,005h,002h,002h,054h,055h,002h	; 7bbd  .....TU.
	defb 000h,05bh,0ffh,0ffh,002h,002h,004h,00ch	; 7bc5  .[......
	defb 014h,0ffh,0ffh	; 7bcd

; ----------------------------------------------------------------------
; DATOS fichas_del_salto_de_longitud: Cadena de tres fichas de actor de
;   dieciseis bytes, comprimidas con rachas de ceros.
;   0x7bd0..0x7bfb  (43 bytes)
DATA_fichas_del_salto_de_longitud:
	defb 001h,000h,006h,082h,079h,0ffh,0ffh,000h	; 7bd0  ....y...
	defb 002h,065h,07bh,001h,008h,000h,003h,03eh	; 7bd8  .e{....>
	defb 000h,002h,01fh,07ah,0dch,07bh,002h,0ffh	; 7be0  ...z.{..
	defb 079h,07bh,0ffh,004h,000h,003h,038h,000h	; 7be8  y{....8.
	defb 002h,03fh,07ah,0ebh,07bh,002h,0ffh,088h	; 7bf0  .?z.{...
	defb 07bh,0ffh,0ffh	; 7bf8

; ----------------------------------------------------------------------
; DATOS ficha_del_atleta: La ficha que 0x7B2C copia siempre a 0xE120.
;   0x7bfb..0x7c06  (11 bytes)
DATA_ficha_del_atleta:
	defb 003h,000h,007h,079h,0fbh,07bh,000h,002h	; 7bfb  ...y.{..
	defb 0c9h,07bh,001h	; 7c03

; ----------------------------------------------------------------------
; DATOS fichas_de_los_100_metros: Cadena de tres fichas para 0xE130, 0xE140 y
;   0xE150.
;   0x7c06..0x7c2b  (37 bytes)
DATA_fichas_de_los_100_metros:
	defb 001h,000h,006h,084h,079h,0ffh,0ffh,000h	; 7c06  ....y...
	defb 002h,048h,07ch,001h,001h,000h,006h,0eah	; 7c0e  .H|.....
	defb 079h,02bh,07ch,000h,002h,05dh,07ch,001h	; 7c16  y+|..]|.
	defb 005h,000h,006h,0aah,07ah,039h,07ch,000h	; 7c1e  ....z9|.
	defb 002h,083h,07ch,001h,0ffh	; 7c26

; ----------------------------------------------------------------------
; DATOS fichas_de_relevo: Las fichas que 0x7AC0 carga encima de otra cuando la
;   animacion cambia.
;   0x7c2b..0x7c48  (29 bytes)
DATA_fichas_de_relevo:
	defb 000h,004h,09ah,000h,002h,0ffh,079h,083h	; 7c2b  ......y.
	defb 07ch,001h,0ffh,05dh,07ch,0ffh,004h,000h	; 7c33  |..]|...
	defb 003h,09ah,000h,002h,0bfh,07ah,039h,07ch	; 7c3b  .....z9|
	defb 001h,0ffh,083h,07ch,0ffh	; 7c43

; ----------------------------------------------------------------------
; DATOS figuras_de_los_100_metros: Mas figuras del decorado de las pruebas de
;   carrera.
;   0x7c48..0x7ca9  (97 bytes)
DATA_figuras_de_los_100_metros:
	defb 002h,00fh,001h,0a8h,00fh,002h,000h,000h	; 7c48  ........
	defb 0a8h,002h,002h,005h,001h,094h,005h,002h	; 7c50  ........
	defb 000h,0a8h,0a8h,0ffh,0ffh,002h,003h,01ch	; 7c58  ........
	defb 01dh,01eh,002h,001h,058h,002h,000h,05bh	; 7c60  ....X..[
	defb 05bh,0ffh,002h,003h,010h,011h,012h,002h	; 7c68  [.......
	defb 001h,0d2h,002h,000h,0d5h,0ffh,002h,000h	; 7c70  ........
	defb 01ch,002h,003h,01ch,01dh,01eh,002h,001h	; 7c78  ........
	defb 0d6h,0ffh,0ffh,002h,003h,004h,005h,006h	; 7c80  ........
	defb 002h,001h,0ceh,002h,000h,0d1h,0d1h,0ffh	; 7c88  ........
	defb 002h,003h,010h,011h,012h,002h,001h,0d2h	; 7c90  ........
	defb 002h,000h,0d5h,0ffh,002h,000h,01ch,002h	; 7c98  ........
	defb 003h,01ch,01dh,01eh,002h,001h,0d6h,0ffh	; 7ca0  ........
	defb 0ffh	; 7ca8

; ----------------------------------------------------------------------
; DATOS fichas_del_martillo: Cadena de dos fichas para 0xE130 y 0xE140.
;   0x7ca9..0x7cc2  (25 bytes)
DATA_fichas_del_martillo:
	defb 001h,000h,006h,0a4h,079h,0ffh,0ffh,000h	; 7ca9  ....y...
	defb 002h,0c2h,07ch,001h,001h,000h,006h,06ah	; 7cb1  ..|....j
	defb 07ah,000h,002h,003h,0ffh,0d7h,07ch,001h	; 7cb9  z.....|.
	defb 0ffh	; 7cc1

; ----------------------------------------------------------------------
; DATOS figuras_del_martillo: Las figuras del circulo y la jaula.
;   0x7cc2..0x7ce8  (38 bytes)
DATA_figuras_del_martillo:
	defb 002h,00eh,001h,038h,00eh,002h,000h,038h	; 7cc2  ...8...8
	defb 038h,038h,002h,005h,001h,020h,005h,002h	; 7cca  88... ..
	defb 000h,038h,038h,0ffh,0ffh,002h,002h,0c0h	; 7cd2  .88.....
	defb 0c1h,0ffh,0c8h,0c9h,0ffh,0d0h,0d1h,0ffh	; 7cda  ........
	defb 0d8h,0d9h,0ffh,0ffh,0ffh,0ffh	; 7ce2

; ----------------------------------------------------------------------
; DATOS fichas_de_los_400_metros: Cadena de tres fichas.
;   0x7ce8..0x7d0d  (37 bytes)
DATA_fichas_de_los_400_metros:
	defb 001h,000h,006h,084h,079h,0ffh,0ffh,000h	; 7ce8  ....y...
	defb 002h,048h,07ch,001h,001h,000h,006h,0eah	; 7cf0  .H|.....
	defb 079h,00dh,07dh,000h,002h,05dh,07ch,001h	; 7cf8  y.}..]|.
	defb 005h,000h,006h,0aah,07ah,01ch,07dh,000h	; 7d00  ....z.}.
	defb 002h,083h,07ch,001h,0ffh	; 7d08

; ----------------------------------------------------------------------
; DATOS fichas_de_relevo_2: Dos fichas mas de relevo.
;   0x7d0d..0x7d2c  (31 bytes)
DATA_fichas_de_relevo_2:
	defb 000h,004h,0e2h,003h,000h,001h,0ffh,079h	; 7d0d  .......y
	defb 00dh,07dh,001h,0ffh,05dh,07ch,0ffh,004h	; 7d15  .}..]|..
	defb 000h,003h,0e2h,003h,000h,001h,0bfh,07ah	; 7d1d  .......z
	defb 01ch,07dh,001h,0ffh,083h,07ch,0ffh	; 7d25

; ======================================================================
; CODIGO 0x7d2c..0x7ef6  (458 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  EL VUELO DEL SALTO Y DEL MARTILLO  ==========
; La unica cuenta de verdad del cartucho. Con la velocidad de carrera y
; el angulo saca el avance y la altura de cada cuadro, y la marca en
; metros. Se apoya en tres rutinas de aritmetica escritas a mano:
; 0x7E76 divide desplazando y restando, 0x7E94 multiplica desplazando y
; sumando, y 0x7EB8 pasa un numero binario a BCD doblandolo en BCD.
; El seno sale de la tabla de 0x7EF6, un byte por grado.
; ----------------------------------------------------------------------
AVANZA_EL_TIRO:
	ld hl,(0e0afh)		;7d2c   ; la velocidad de salida
	push hl			;7d2f
	ld de,00546h		;7d30   ; el tope es 0x546
	sbc hl,de		;7d33
	pop hl			;7d35
	jr c,CALCULA_EL_TIRO		;7d36   ; y si se pasa, se usa el tope
	ex de,hl			;7d38
CALCULA_EL_TIRO:
	ld a,l			;7d39   ; al reves, que es como lo quiere la division
	ld l,h			;7d3a
	ld h,a			;7d3b
	ld (0e220h),hl		;7d3c
	ld hl,0e222h		;7d3f   ; el divisor
	ld (hl),000h		;7d42
	inc hl			;7d44
	exx			;7d45
	ld a,d			;7d46
	exx			;7d47
	ld (hl),a			;7d48
	call DIVIDE		;7d49   ; divide
	ld hl,(0e221h)		;7d4c   ; el cociente
	ld (0e100h),hl		;7d4f
	ld a,(0e032h)		;7d52   ; el angulo
	push af			;7d55
	add a,0a5h		;7d56   ; su complemento a 90 grados
	cpl			;7d58
	ld de,0e103h		;7d59   ; y de ahi sale el coseno
	call EL_SENO_DEL_ANGULO		;7d5c
	ld hl,(0e220h)		;7d5f   ; la velocidad
	ld (0e104h),hl		;7d62
	ld hl,0e109h		;7d65   ; el ajuste de 0x41
	ld a,(hl)			;7d68
	add a,041h		;7d69
	ld (hl),a			;7d6b
	dec hl			;7d6c
	ld a,(hl)			;7d6d
	adc a,000h		;7d6e
	ld (hl),a			;7d70
	ld de,0e102h		;7d71   ; el angulo tal cual
	pop af			;7d74
	call EL_SENO_DEL_ANGULO		;7d75   ; da el seno
	ld de,0e221h		;7d78   ; y la parte vertical sale de restarlo
	ld hl,0e109h		;7d7b
	ld a,(de)			;7d7e
	sub (hl)			;7d7f
	ld (de),a			;7d80
	dec de			;7d81
	dec hl			;7d82
	ld a,(de)			;7d83
	sbc a,(hl)			;7d84
	ld (de),a			;7d85
	ld hl,(0e220h)		;7d86   ; la velocidad otra vez
	ld (0e106h),hl		;7d89
	ld hl,0e10ch		;7d8c
	ld b,002h		;7d8f
ACUMULA_LAS_DOS_COMPONENTES:
	or a			;7d91
	ld de,0e105h		;7d92   ; el avance del cuadro
	call SUMA_TRES_BYTES		;7d95
	ld a,000h		;7d98
	adc a,(hl)			;7d9a
	ld (hl),a			;7d9b
	ld hl,0e112h		;7d9c   ; y la altura
	djnz ACUMULA_LAS_DOS_COMPONENTES		;7d9f
ACUMULA_LA_ALTURA:
	ld hl,0e10fh		;7da1
	ld de,0e107h		;7da4   ; la componente vertical
	call SUMA_TRES_BYTES		;7da7
	push af			;7daa
	ld a,(de)			;7dab   ; el signo manda en el acarreo
	bit 7,a		;7dac
	jr z,PASA_EL_TIRO_A_METROS		;7dae
	dec b			;7db0
PASA_EL_TIRO_A_METROS:
	pop af			;7db1
	ld a,b			;7db2
	adc a,(hl)			;7db3
	ld (hl),a			;7db4
	ld de,0e220h		;7db5   ; el avance acumulado
	ld hl,0e10ah		;7db8
	ld bc,00003h		;7dbb
	ldir		;7dbe
	exx			;7dc0
	ld a,b			;7dc1
	exx			;7dc2
	ld (de),a			;7dc3
	call DIVIDE		;7dc4   ; lo divide
	ld hl,0e221h		;7dc7
	ld a,(hl)			;7dca
	inc hl			;7dcb
	rrd		;7dcc   ; mueve el nibble de sitio
	ld a,(hl)			;7dce
	ld de,0e114h		;7dcf
	ex de,hl			;7dd2
	sub (hl)			;7dd3   ; la altura de este cuadro
	ld (0e117h),a		;7dd4
	ld a,(de)			;7dd7
	ld (hl),a			;7dd8
	dec hl			;7dd9
	dec de			;7dda
	ld a,(de)			;7ddb   ; los cuatro bits de arriba
	and 0f0h		;7ddc
	rrca			;7dde
	rrca			;7ddf
	rrca			;7de0
	rrca			;7de1
	ld (hl),a			;7de2
	dec de			;7de3
	ld hl,0e10dh		;7de4
	bit 7,(hl)		;7de7   ; con el bit 7 puesto el tiro baja
	jr z,TIRO_QUE_BAJA		;7de9
	inc b			;7deb
TIRO_QUE_BAJA:
	push bc			;7dec
	jr z,TIRO_QUE_SUBE		;7ded   ; si baja, se cambia de signo
	inc hl			;7def
	inc hl			;7df0
	inc de			;7df1
	inc de			;7df2
	ld b,003h		;7df3
	scf			;7df5
CAMBIA_DE_SIGNO:
	ld a,(hl)			;7df6
	cpl			;7df7   ; complemento a dos de tres bytes
	adc a,000h		;7df8
	ld (de),a			;7dfa
	dec de			;7dfb
	dec hl			;7dfc
	djnz CAMBIA_DE_SIGNO		;7dfd
	ld de,0e223h		;7dff
	jr GUARDA_EL_TIRO		;7e02
TIRO_QUE_SUBE:
	ld c,003h		;7e04   ; tres bytes tal cual
	ldir		;7e06
GUARDA_EL_TIRO:
	exx			;7e08
	ld a,c			;7e09
	exx			;7e0a
	ld (de),a			;7e0b
	call DIVIDE		;7e0c   ; el divisor
	ld hl,0e221h		;7e0f   ; el dividendo
	ld b,002h		;7e12
	ld c,(hl)			;7e14
	ld (hl),000h		;7e15
	inc hl			;7e17
	ld a,(hl)			;7e18
	ld (hl),c			;7e19
DESPLAZA_EL_RESULTADO:
	rlca			;7e1a   ; dos desplazamientos a la izquierda, o sea por cuatro
	rl (hl)		;7e1b
	dec hl			;7e1d
	rl (hl)		;7e1e
	inc hl			;7e20
	djnz DESPLAZA_EL_RESULTADO		;7e21
	ld de,0e116h		;7e23
	ex de,hl			;7e26
	pop bc			;7e27
	ld a,b			;7e28   ; con signo, la altura va restando
	or a			;7e29
	jr z,ALTURA_QUE_SUBE		;7e2a
	ld a,(de)			;7e2c   ; cambiada de signo
	neg		;7e2d
	sub (hl)			;7e2f
	ld (0e118h),a		;7e30
	ld a,(de)			;7e33
	neg		;7e34
	jr GUARDA_LA_ALTURA		;7e36
ALTURA_QUE_SUBE:
	ld a,(de)			;7e38
	sub (hl)			;7e39   ; la altura de este cuadro
	ld (0e118h),a		;7e3a
	ld a,(de)			;7e3d
GUARDA_LA_ALTURA:
	ld (hl),a			;7e3e
	ld hl,(0e110h)		;7e3f   ; la marca acumulada
	ld (0e220h),hl		;7e42
	call PASA_A_BCD		;7e45   ; se pasa a BCD
	ld hl,0e222h		;7e48   ; y se guarda en metros
	ld de,0e119h		;7e4b
	ld bc,00003h		;7e4e
	ldir		;7e51
	ret			;7e53
EL_SENO_DEL_ANGULO:
	ld hl,07ef6h		;7e54   ; la tabla del seno
	call SUMA_A_A_HL		;7e57
	ld a,(hl)			;7e5a   ; el valor del angulo
	ld (de),a			;7e5b
	ld hl,(0e100h)		;7e5c   ; la velocidad
	ld (0e220h),hl		;7e5f
	ld hl,0e222h		;7e62
	ld (hl),000h		;7e65
	inc hl			;7e67
	ld a,(de)			;7e68   ; y el seno de multiplicador
	ld (hl),a			;7e69
	jp MULTIPLICA		;7e6a
SUMA_TRES_BYTES:
	call SUMA_UN_BYTE		;7e6d
	dec de			;7e70
SUMA_UN_BYTE:
	ld a,(de)			;7e71
	adc a,(hl)			;7e72
	ld (hl),a			;7e73
	dec hl			;7e74
	ret			;7e75
DIVIDE:
	ld c,010h		;7e76   ; dieciseis vueltas, un bit de cociente por vuelta
UNA_VUELTA_DE_DIVISION:
	ld hl,0e222h		;7e78
	or a			;7e7b
	ld b,003h		;7e7c   ; tres bytes de dividendo
DESPLAZA_EL_DIVIDENDO:
	rl (hl)		;7e7e
	dec hl			;7e80
	djnz DESPLAZA_EL_DIVIDENDO		;7e81
	inc hl			;7e83
	ex de,hl			;7e84
	ld hl,0e223h		;7e85   ; el divisor
	ld a,(de)			;7e88   ; se resta si cabe
	sub (hl)			;7e89
	jr c,SIGUIENTE_VUELTA_DE_DIVISION		;7e8a
	ld (de),a			;7e8c
	dec hl			;7e8d
	set 0,(hl)		;7e8e   ; y se apunta el bit del cociente
SIGUIENTE_VUELTA_DE_DIVISION:
	dec c			;7e90
	jr nz,UNA_VUELTA_DE_DIVISION		;7e91
	ret			;7e93
MULTIPLICA:
	ld b,010h		;7e94   ; dieciseis vueltas
UNA_VUELTA_DE_MULTIPLICACION:
	ld hl,0e222h		;7e96
	or a			;7e99
	rl (hl)		;7e9a   ; tres bytes a la izquierda
	dec hl			;7e9c
	rl (hl)		;7e9d
	dec hl			;7e9f
	rl (hl)		;7ea0
	jr nc,SIGUIENTE_VUELTA_DE_MULTIPLICACION		;7ea2   ; si sale un uno, se suma el multiplicando
	ld hl,0e223h		;7ea4
	ld a,(hl)			;7ea7   ; tres bytes con acarreo
	dec hl			;7ea8
	add a,(hl)			;7ea9
	ld (hl),a			;7eaa
	dec hl			;7eab
	ld a,(hl)			;7eac
	adc a,000h		;7ead
	ld (hl),a			;7eaf
	dec hl			;7eb0
	ld a,(hl)			;7eb1
	adc a,000h		;7eb2
	ld (hl),a			;7eb4
SIGUIENTE_VUELTA_DE_MULTIPLICACION:
	djnz UNA_VUELTA_DE_MULTIPLICACION		;7eb5
	ret			;7eb7
PASA_A_BCD:
	ld hl,0e222h		;7eb8   ; el acumulador
	ld b,005h		;7ebb   ; cinco bytes a cero
LIMPIA_EL_ACUMULADOR:
	ld (hl),000h		;7ebd
	inc hl			;7ebf
	djnz LIMPIA_EL_ACUMULADOR		;7ec0
	ld (hl),001h		;7ec2   ; y el ultimo a uno, que es la primera potencia
	ex de,hl			;7ec4
	ld hl,0e224h		;7ec5
	exx			;7ec8
	ld b,010h		;7ec9   ; dieciseis bits
UN_BIT_A_BCD:
	ld hl,0e220h		;7ecb   ; el numero, dos bytes
	or a			;7ece
	rr (hl)		;7ecf   ; a la derecha
	inc hl			;7ed1
	rr (hl)		;7ed2
	exx			;7ed4
	jr nc,DOBLA_LA_POTENCIA		;7ed5   ; con el bit a cero solo se dobla la potencia
	push hl			;7ed7
	push de			;7ed8
	ld b,003h		;7ed9   ; tres bytes
	or a			;7edb
SUMA_LA_POTENCIA:
	ld a,(de)			;7edc   ; en BCD
	adc a,(hl)			;7edd
	daa			;7ede
	ld (hl),a			;7edf
	dec de			;7ee0
	dec hl			;7ee1
	djnz SUMA_LA_POTENCIA		;7ee2
	pop de			;7ee4
	pop hl			;7ee5
DOBLA_LA_POTENCIA:
	push de			;7ee6
	ld b,003h		;7ee7   ; tres bytes
	or a			;7ee9
DOBLA_UN_BYTE_BCD:
	ld a,(de)			;7eea   ; sumarse a si mismo es doblar
	adc a,a			;7eeb
	daa			;7eec
	ld (de),a			;7eed
	dec de			;7eee
	djnz DOBLA_UN_BYTE_BCD		;7eef
	pop de			;7ef1
	exx			;7ef2
	djnz UN_BIT_A_BCD		;7ef3
	ret			;7ef5

; ----------------------------------------------------------------------
; DATOS seno: El seno de 0 a 91 grados por 255, un byte por grado. Lo lee
;   0x7E54 con el angulo de lanzamiento para partir el tiro en avance y
;   altura.
;   0x7ef6..0x7f52  (92 bytes)
DATA_seno:
	defb 000h,004h,009h,00dh,012h,016h,01bh,01fh,023h,028h,02ch,031h,035h,039h,03eh,042h	; 7ef6  ........#(,159>B
	defb 046h,04bh,04fh,053h,057h,05bh,060h,064h,068h,06ch,070h,074h,078h,07ch,080h,083h	; 7f06  FKOSW[`dhlptx|..
	defb 087h,08bh,08fh,092h,096h,099h,09dh,0a0h,0a4h,0a7h,0abh,0adh,0b1h,0b3h,0b7h,0bah	; 7f16  ................
	defb 0beh,0c0h,0c3h,0c6h,0c9h,0cch,0ceh,0d1h,0d3h,0d6h,0d8h,0dbh,0ddh,0dfh,0e1h,0e3h	; 7f26  ................
	defb 0e5h,0e7h,0e9h,0ebh,0ech,0eeh,0f0h,0f1h,0f3h,0f4h,0f5h,0f6h,0f7h,0f8h,0f9h,0fah	; 7f36  ................
	defb 0fbh,0fch,0fdh,0fdh,0feh,0feh,0feh,0ffh,0ffh,0ffh,0ffh,0ffh	; 7f46  ............

; ======================================================================
; CODIGO 0x7f52..0x7fff  (173 bytes)
; ======================================================================



; ----------------------------------------------------------------------
; ==========  MONTAR EL SPRITE DEL ATLETA  ==========
; El atleta no es un sprite: son SIETE, y cada postura los coloca a mano.
; 0x7F86 sube los patrones que hagan falta y despues escribe las siete
; filas de la tabla de atributos, sumando a cada una la fila y la
; columna del atleta.
; ----------------------------------------------------------------------
FICHA_DEL_QUE_JUEGA:
	ld hl,0e0b4h		;7f52   ; la del jugador 1
	ld b,001h		;7f55   ; y su numero de atleta
	call A_QUIEN_LE_TOCA		;7f57
	ret z			;7f5a
	ld hl,0e0eah		;7f5b   ; o la del jugador 2
	dec b			;7f5e
	ret			;7f5f
COLUMNA_DEL_QUE_JUEGA:
	call FICHA_DEL_QUE_JUEGA		;7f60
	inc hl			;7f63
	ret			;7f64
POSTURA_DEL_QUE_JUEGA:
	call FICHA_DEL_QUE_JUEGA		;7f65
	inc hl			;7f68
	inc hl			;7f69
	ret			;7f6a
BOTON_DEL_QUE_JUEGA:
	ld hl,0e00bh		;7f6b   ; el del jugador 1
	call A_QUIEN_LE_TOCA		;7f6e
	ret z			;7f71
	ld hl,0e00fh		;7f72   ; o el del 2
	ret			;7f75
ACABA_EL_INTENTO_Y_ANIMA:
	ld hl,0e02eh		;7f76
	set 0,(hl)		;7f79   ; bit 0 de 0xE02E: intento acabado
CUENTA_DE_ANIMACION:
	ld hl,0e0bbh		;7f7b   ; la del jugador 1
	call A_QUIEN_LE_TOCA		;7f7e
	ret z			;7f81
	ld hl,0e0f1h		;7f82   ; o la del 2
	ret			;7f85
PINTA_AL_ATLETA:
	exx			;7f86
	ld hl,07b10h		;7f87   ; la fila de atributos del jugador 2
	ld de,05880h		;7f8a   ; y sus patrones de sprite
	ld bc,0e0b6h		;7f8d   ; y su postura
	or a			;7f90
	jr nz,SUBE_LOS_PATRONES		;7f91
	ld hl,07b2ch		;7f93   ; o los del jugador 1
	ld de,05960h		;7f96
	ld bc,0e0ech		;7f99
SUBE_LOS_PATRONES:
	ld a,(bc)			;7f9c   ; la postura
	dec bc			;7f9d   ; y de paso deja BC en la fila y la columna
	dec bc			;7f9e
	push bc			;7f9f
	push hl			;7fa0
	ld hl,0702eh		;7fa1   ; la tabla de posturas
	rlca			;7fa4
	call SUMA_A_A_HL		;7fa5
	ld a,(hl)			;7fa8   ; el registro de la postura
	inc hl			;7fa9
	ld h,(hl)			;7faa
	ld l,a			;7fab
	ld b,(hl)			;7fac   ; cuantos trozos lleva
	inc hl			;7fad
UN_TROZO_DEL_ATLETA:
	push bc			;7fae
	push hl			;7faf
	ld a,(hl)			;7fb0   ; el puntero al patron
	inc hl			;7fb1
	ld h,(hl)			;7fb2
	ld l,a			;7fb3
	xor a			;7fb4
	cp h			;7fb5   ; con el byte alto a cero no hay patron que subir
	jr z,SIGUIENTE_TROZO		;7fb6
	call SUBE_UN_PATRON_DE_SPRITE		;7fb8   ; y si lo hay, se sube comprimido
SIGUIENTE_TROZO:
	ld hl,00020h		;7fbb   ; cada patron ocupa 0x20 bytes de VRAM
	add hl,de			;7fbe
	ex de,hl			;7fbf
	pop hl			;7fc0
	inc hl			;7fc1
	inc hl			;7fc2
	pop bc			;7fc3
	djnz UN_TROZO_DEL_ATLETA		;7fc4
	ld a,(hl)			;7fc6   ; detras del ultimo trozo va la lista de atributos
	inc hl			;7fc7
	ld h,(hl)			;7fc8
	ld l,a			;7fc9
	pop de			;7fca
	pop bc			;7fcb
	exx			;7fcc
	push bc			;7fcd
	ld a,(00006h)		;7fce   ; el puerto de datos del VDP
	ld c,a			;7fd1
	exx			;7fd2
	ld a,007h		;7fd3   ; siete sprites
UN_SPRITE_DEL_ATLETA:
	ex af,af'			;7fd5
	call FIJA_ESCRITURA_CON_CANDADO		;7fd6   ; fija la fila de la tabla de atributos
	ld a,(hl)			;7fd9
	cp 0cfh		;7fda   ; 0xCF es "no pintar"
	jr z,SUELTA_LA_COLUMNA		;7fdc
	ld a,(bc)			;7fde   ; la fila de la lista mas la del atleta
	add a,(hl)			;7fdf
	cp 0d0h		;7fe0   ; y 0xD0 se cambia por 0xCF para no esconderlo
	jr nz,SUELTA_LA_FILA		;7fe2
	ld a,0cfh		;7fe4
SUELTA_LA_FILA:
	exx			;7fe6
	out (c),a		;7fe7
	exx			;7fe9
	inc bc			;7fea   ; la columna, sumada igual
	inc hl			;7feb
	ld a,(bc)			;7fec
	add a,(hl)			;7fed
	dec bc			;7fee
SUELTA_LA_COLUMNA:
	exx			;7fef
	out (c),a		;7ff0   ; la suelta
	exx			;7ff2
	inc hl			;7ff3   ; el siguiente byte de la lista
	inc de			;7ff4   ; cuatro bytes por sprite
	inc de			;7ff5
	inc de			;7ff6
	inc de			;7ff7
	ex af,af'			;7ff8
	dec a			;7ff9   ; hasta los siete sprites
	jr nz,UN_SPRITE_DEL_ATLETA		;7ffa
	exx			;7ffc
	pop bc			;7ffd
	ret			;7ffe

; ----------------------------------------------------------------------
; DATOS relleno: El unico byte que sobra del cartucho, a 0xFF.
;   0x7fff..0x8000  (1 bytes)
DATA_relleno:
	defb 0ffh	; 7fff
