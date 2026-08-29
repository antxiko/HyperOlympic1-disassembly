#!/usr/bin/env python3
"""Ejecuta un guion largo de Hyper Olympic y devuelve la VRAM que deja.

Es la traduccion a Python de GUION_LARGO (HO1 0x4D09) y de todo lo que cuelga
de el: MONTA_UN_ROTULO, LLENA_EL_PAPEL, ESTIRA_LAS_LETRAS y SUBE_EL_PAPEL. El
cartucho no guarda pantallas: guarda guiones, y la unica forma de comparar dos
guiones distintos es EJECUTARLOS y mirar la VRAM que dejan.

Las cinco ordenes:
  0  bytes a VRAM, con 0x11 cuenta valor para las rachas
  1  tiras de glifos de la fuente, subidos como patron
  2  rotulos de letra grande (se montan en el papel de 0xE230)
  3  rellenos de un byte
  4+ repetir un patron de ocho bytes N veces

Uso como programa: pinta_largo.py <rom> <ini> <fuente> [<rom2> <ini2> <fuente2>]
"""
import sys

ORG = 0x4000


class Maquina:
    def __init__(self, rom, fuente, org=ORG):
        self.rom = rom
        self.fuente = fuente
        self.org = org
        self.vram = {}
        self.dir = 0
        self.papel = bytearray(8 + 0xA0 + 32)   # 8 bytes de guarda por delante

    def b(self, p):
        return self.rom[p - self.org]

    def fija(self, de):
        self.dir = de & 0x3FFF

    def out(self, v):
        self.vram[self.dir] = v
        self.dir = (self.dir + 1) & 0x3FFF

    # ---------------------------------------------------------- el papel
    def sube_el_papel(self, i):
        """SUBE_EL_PAPEL: de ocho en ocho hasta el 0x11. Devuelve donde paro."""
        while True:
            for _ in range(8):
                self.out(self.papel[8 + i])
                i += 1
            if self.papel[8 + i] == 0x11:
                return i

    def estira(self):
        """ESTIRA_LAS_LETRAS: tres pasadas de dos bits."""
        for _ in range(3):
            h = 0
            while True:
                for _ in range(8):
                    c = 0
                    for _ in range(2):
                        v = self.papel[8 + h]
                        acarreo = (v >> 7) & 1
                        self.papel[8 + h] = (v << 1) & 0xFF
                        c = ((c << 1) | acarreo) & 0xFF
                    self.papel[8 + h - 8] |= c
                    h += 1
                if self.papel[8 + h] == 0x11:
                    break
            h -= 8
            guardado = self.papel[8 + h]
            self.papel[8 + h] = 0x11
            i = self.sube_el_papel(0)
            self.papel[8 + i] = guardado
            self.papel[8 + i + 8] = 0x11

    def llena_el_papel(self, p):
        de = 0
        tipo = self.b(p)
        p += 1
        if tipo == 0:
            c = self.b(p)
            fin = False
            while not fin:
                p += 1
                a = self.b(p)
                if a == 0x11:
                    p += 1
                    n = self.b(p)
                    p += 1
                    while True:
                        self.papel[8 + de] = self.b(p)
                        de += 1
                        c -= 1
                        if c == 0:
                            fin = True
                            break
                        n -= 1
                        if n == 0:
                            break
                    continue
                self.papel[8 + de] = a
                de += 1
                c -= 1
                if c == 0:
                    break
            self.papel[8 + de] = 0x11
        else:
            while True:
                g = self.b(p)
                s = self.fuente + 8 * g
                for k in range(8):
                    self.papel[8 + de] = self.b(s + k)
                    de += 1
                p += 1
                if self.b(p) == 0xFF:
                    break
            self.papel[8 + de] = 0x11
        return de

    def monta_un_rotulo(self, p):
        fin = self.llena_el_papel(p)
        h = fin - 8
        guardado = self.papel[8 + h]
        self.papel[8 + h] = 0x11
        i = self.sube_el_papel(0)
        self.papel[8 + i] = guardado
        self.estira()
        for k in range(len(self.papel)):
            self.papel[k] = 0

    # ---------------------------------------------------------- el guion
    def guion_largo(self, p):
        n = self.b(p)
        p += 1
        for _ in range(n):
            t = self.b(p)
            p += 1
            if t == 0:
                p = self.orden_de_bytes(p)
            elif t == 1:
                p = self.orden_de_glifos(p)
            elif t == 2:
                p = self.orden_de_rotulos(p)
            elif t == 3:
                p = self.orden_de_rellenos(p)
            else:
                p = self.orden_de_patron(p)
        return p

    def orden_de_bytes(self, p):
        nb = self.b(p)
        p += 1
        for _ in range(nb if nb else 256):
            self.fija((self.b(p) << 8) | self.b(p + 1))
            p += 2
            c = self.b(p)
            if c == 0:
                c = 256
            p += 1
            while True:
                a = self.b(p)
                if a == 0x11:
                    p += 1
                    n = self.b(p)
                    p += 1
                    v = self.b(p)
                    p += 1
                    while True:
                        self.out(v)
                        c -= 1
                        if c == 0:
                            break
                        n -= 1
                        if n == 0:
                            break
                    if c == 0:
                        break
                    continue
                self.out(a)
                p += 1
                c -= 1
                if c == 0:
                    break
        return p

    def orden_de_glifos(self, p):
        nb = self.b(p)
        for _ in range(nb if nb else 256):
            p += 1
            self.fija((self.b(p) << 8) | self.b(p + 1))
            p += 1
            p += 1
            while True:
                g = self.b(p)
                s = self.fuente + 8 * g
                for k in range(8):
                    self.out(self.b(s + k))
                p += 1
                if self.b(p) == 0xFF:
                    break
        return p + 1

    def orden_de_rotulos(self, p):
        nr = self.b(p)
        p += 1
        self.fija((self.b(p) << 8) | self.b(p + 1))
        p += 2
        for _ in range(nr if nr else 256):
            q = self.b(p) | (self.b(p + 1) << 8)
            p += 2
            self.monta_un_rotulo(q)
        return p

    def orden_de_rellenos(self, p):
        nr = self.b(p)
        p += 1
        self.fija((self.b(p) << 8) | self.b(p + 1))
        p += 1
        for _ in range(nr if nr else 256):
            p += 1
            n = self.b(p)
            p += 1
            v = self.b(p)
            for _ in range(n if n else 256):
                self.out(v)
        return p + 1

    def orden_de_patron(self, p):
        self.fija((self.b(p) << 8) | self.b(p + 1))
        p += 1
        p += 1
        n = self.b(p)
        p += 1
        d = self.b(p) | (self.b(p + 1) << 8)
        p += 1
        for _ in range(n if n else 256):
            for k in range(8):
                self.out(self.b(d + k))
        return p + 1


def ejecuta(ruta, ini, fuente):
    m = Maquina(open(ruta, "rb").read(), fuente)
    fin = m.guion_largo(ini)
    return m, fin


def main():
    m1, f1 = ejecuta(sys.argv[1], int(sys.argv[2], 0), int(sys.argv[3], 0))
    print("A: guion 0x%04X-0x%04X (%d bytes), %d direcciones de VRAM escritas"
          % (int(sys.argv[2], 0), f1 - 1, f1 - int(sys.argv[2], 0), len(m1.vram)))
    if len(sys.argv) <= 4:
        return
    m2, f2 = ejecuta(sys.argv[4], int(sys.argv[5], 0), int(sys.argv[6], 0))
    print("B: guion 0x%04X-0x%04X (%d bytes), %d direcciones de VRAM escritas"
          % (int(sys.argv[5], 0), f2 - 1, f2 - int(sys.argv[5], 0), len(m2.vram)))
    ka, kb = set(m1.vram), set(m2.vram)
    solo_a, solo_b = sorted(ka - kb), sorted(kb - ka)
    dif = [x for x in sorted(ka & kb) if m1.vram[x] != m2.vram[x]]
    print()
    print("direcciones que solo escribe A: %d" % len(solo_a))
    print("direcciones que solo escribe B: %d" % len(solo_b))
    print("direcciones con valor distinto : %d" % len(dif))

    def zona(x):
        if x < 0x1800:
            return "color   patron %3d fila %d" % (x // 8, x % 8)
        if x < 0x2000:
            return "sprites"
        if x < 0x3800:
            n = x - 0x2000
            return "patron  patron %3d fila %d" % (n // 8, n % 8)
        if x < 0x3B00:
            n = x - 0x3800
            return "nombres fila %2d col %2d" % (n // 32, n % 32)
        return "otros"

    todos = sorted(set(solo_a) | set(solo_b) | set(dif))
    grupos = []
    for x in todos:
        if grupos and x <= grupos[-1][1] + 1:
            grupos[-1][1] = x
        else:
            grupos.append([x, x])
    print()
    print("tramos de VRAM que no coinciden: %d" % len(grupos))
    for a, b in grupos:
        print("  0x%04X-0x%04X  %5d bytes   %s" % (a, b, b - a + 1, zona(a)))


if __name__ == "__main__":
    main()
