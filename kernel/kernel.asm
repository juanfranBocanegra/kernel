bits 32

global _start



; Definiciones
VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

_start:
    cld
    ; Configurar segmentos
    mov ax, 0x10       ; Selector de datos GDT
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; 1. Limpiar pantalla
    mov edi, VIDEO_MEMORY
    mov ecx, 80*25
    mov ax, 0x0f20      ; Espacio blanco sobre negro
    rep stosw
    
    ; 2. Imprimir mensaje
    mov esi, msg_kernel
    add esi, 0x8000
    mov edi, VIDEO_MEMORY
    call print_string

    
    
    
    ; Configurar pila
    mov esp, 0x90000
    
    ; Llamar a la función principal en C
   
    
    ; Si vuelve (no debería)
    cli
    hlt

    
    
    ; 3. Bucle infinito
    jmp $

print_string:
    mov ah, WHITE_ON_BLACK
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
.done:
    ret

msg_kernel db 'Kernel 32-bit loaded!', 0

; Rellenar hasta 5 sectores (512*5 = 2560 bytes)
times 2560-($-$$) db 0