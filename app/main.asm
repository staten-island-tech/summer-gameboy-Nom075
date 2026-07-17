SECTION "Header", ROM0[$100]
    jp Start
    ds $150 - @, 0    ; pad header area, rgbfix fills in the rest

SECTION "Main", ROM0[$150]
Start:
    di
.loop:
    jr .loop