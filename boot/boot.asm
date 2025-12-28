bits 16
org 0x7c00

KERNEL_SIZE_DWORDS equ 2560 / 4  ; 5 sectores de 512 bytes

_start:
    ; 1. Configurar segmentos
    cli
    xor ax, ax
    mov ds, ax
    mov es, ax
    mov ss, ax
    mov sp, 0x7c00
    sti
    
    cld
    ; 2. Mostrar mensaje
    mov si, msg_loading
    call print
    
    ; 3. Cargar kernel desde disco
    mov ax, 0x0201        ; AH=02h (read), AL=5 sectores
    mov ch, 0             ; Cylinder 0
    mov cl, 2             ; Sector 2
    mov dh, 0             ; Head 0
    mov bx, 0x8000        ; ES:BX = 0x0000:0x8000
    
    int 0x13
   
    jc disk_error
    
    ; 4. Mostrar mensaje de éxito
    mov si, msg_loaded
    call print
    
    ; 5. Habilitar línea A20
    call enable_a20
    
    ; 6. Deshabilitar interrupciones y cargar GDT
    cli
    lgdt [gdt_descriptor]
    
    ; 7. Cambiar a modo protegido
    mov eax, cr0
    or eax, 0x1
    mov cr0, eax
    
    ; 8. ¡SALTO FAR OBLIGATORIO para limpiar pipeline!
    jmp CODE_SEG:init_pm
    
; ============================================
; MODO PROTEGIDO (32-bit)
; ============================================
bits 32

init_pm:
    ; 9. Configurar segmentos en modo protegido
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x00200000

    mov esi, 0x00008000
    mov edi, 0x00100000
    mov ecx, KERNEL_SIZE_DWORDS   ; tamaño / 4
    rep movsd
    
    ; 10. Opcional: Limpiar pantalla modo 32-bit
    call clear_screen_32
    
    ; 11. Mostrar mensaje modo protegido
    call print_pm
    
    ; 12. Saltar al kernel (ASUME que el kernel es código 32-bit)
    jmp 0x00100000

; ============================================
; FUNCIONES 32-BIT
; ============================================
clear_screen_32:
    mov edi, 0xb8000
    mov ecx, 80*25
    mov ax, 0x0f20      ; Espacio blanco sobre negro
    rep stosw
    ret

print_pm:
    mov esi, msg_pm
    mov edi, 0xb8000
    mov ah, 0x0f        ; Blanco sobre negro
.loop:
    lodsb
    test al, al
    jz .done
    stosw
    jmp .loop
.done:
    ret

; ============================================
; FUNCIONES 16-BIT
; ============================================
bits 16

print:
    mov ah, 0x0e
.loop:
    lodsb
    test al, al
    jz .done
    int 0x10
    jmp .loop
.done:
    ret

disk_error:
    mov si, msg_error
    call print
    ; Mostrar código de error
    mov al, ah
    call print_hex
    jmp $

print_hex:
    push ax
    shr al, 4
    call .digit
    pop ax
    and al, 0x0F
    call .digit
    ret
.digit:
    cmp al, 10
    jl .num
    add al, 'A' - '0' - 10
.num:
    add al, '0'
    mov ah, 0x0e
    int 0x10
    ret

enable_a20:
    ; Método rápido A20
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

; ============================================
; DATOS
; ============================================
msg_loading db 'Loading kernel... ', 0
msg_loaded  db 'OK', 0x0D, 0x0A, 0
msg_error   db 'Disk error: ', 0
msg_pm      db 'Protected mode enabled! Jumping to kernel...', 0

; ============================================
; GDT
; ============================================
gdt_start:
    ; Descriptor nulo (obligatorio)
    dq 0x0
    
gdt_code:
    ; Descriptor código (32-bit)
    dw 0xffff       ; Límite 0-15
    dw 0x0000       ; Base 0-15
    db 0x00         ; Base 16-23
    db 10011010b    ; P=1, DPL=00, S=1, Type=1010 (code, non-conforming, readable)
    db 11001111b    ; G=1, D/B=1, L=0, AVL=0, Límite 16-19
    db 0x00         ; Base 24-31
    
gdt_data:
    ; Descriptor datos
    dw 0xffff
    dw 0x0000
    db 0x00
    db 10010010b    ; P=1, DPL=00, S=1, Type=0010 (data, expand-up, writable)
    db 11001111b
    db 0x00
gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; ============================================
; FIRMA BOOT
; ============================================
times 510-($-$$) db 0
dw 0xaa55