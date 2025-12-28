ENTRY(_start)                  /* Cambia _start por tu etiqueta de entrada */

OUTPUT_FORMAT(binary)          /* Salida binario plano (.bin), sin headers ELF */

SECTIONS
{
    . = 0x7C00;                /* Dirección donde carga el BIOS el boot sector */

    .text : {
        *(.text)               /* Código */
    }

    .data : {
        *(.data)
    }

    .rodata : {
        *(.rodata*)
    }

    .bss : {
        *(.bss)
    }

    /* Firma de boot (obligatoria para que sea bootable) */
    .sig : {
        SHORT(0xAA55)
    }

    /* Descarta lo innecesario */
    /DISCARD/ : { *(*) }
}