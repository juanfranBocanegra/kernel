bits 32
org 0x00100000
global _start

VIDEO_MEMORY equ 0xb8000
WHITE_ON_BLACK equ 0x0f

_start:
    cld
    ; Configurar segmentos
    mov ax, 0x10
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    
    ; Configurar pila
    mov esp, 0x00200000
    
    ; 1. Limpiar pantalla
    mov edi, VIDEO_MEMORY
    mov ecx, 80*25
    mov ax, 0x0f20
    rep stosw
    
    ; 2. Imprimir primer mensaje
    mov esi, msg_hello
    mov edi, VIDEO_MEMORY
    call print_string
    
    ; 3. Sleep de 2 segundos (¡SIMPLE!)
    mov ecx, 0x80000000   ; Ajusta este número para más/menos tiempo
    call delay
    
    ; 4. Imprimir segundo mensaje después del sleep
    mov esi, msg_after
    mov edi, VIDEO_MEMORY + 160  ; Segunda línea
    call print_string
    
    ; 5. Otro sleep de 1 segundo
    mov ecx, 0x40000000   ; Mitad del anterior ≈ 1 segundo
    call delay
    
    ; 6. Tercer mensaje
    mov esi, msg_final
    mov edi, VIDEO_MEMORY + 320  ; Tercera línea
    call print_string
    
    ; 7. Bucle infinito
    jmp $

; ============================================
; DELAY SUPER SIMPLE - Solo un bucle
; Entrada: ECX = contador de iteraciones
; ============================================
delay:
    nop                 ; No operation
    nop                 ; Algunos NOPs para gastar ciclos
    nop
    loop delay          ; Decrementa ECX, salta si no es 0
    ret

; ============================================
; Función para imprimir cadena
; Entrada: ESI = cadena, EDI = posición VGA
; ============================================
print_string:
    mov ah, WHITE_ON_BLACK
.loop:
    lodsb               ; Cargar carácter
    test al, al         ; ¿Fin de cadena?
    jz .done
    stosw               ; Escribir carácter + atributo
    jmp .loop
.done:
    ret

; Mensajes
msg_hello db 'Hello! Waiting 2 seconds...', 0
msg_after db '2 seconds passed!', 0
msg_final db 'Another second passed!', 0

; Rellenar
times 2560-($-$$) db 0