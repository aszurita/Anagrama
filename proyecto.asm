.model small
.stack 100h
.data
    ; Mensajes de solicitud y resultados
    ; 10 para salto de linea
    ; 13 para iniciar lines para escribir 
    msg_inicio db       '****************    PROYECTO ANAGRAMA      ***************** $'
    msg_integrante1 db 10, 13, '*************** Angelo Zurita - Luis Romero **************** $'  
    msg_enter1 db 10,13, 'Ingrese la primera cadena (max 40 caracteres): $'
    msg_enter2 db 10, 13, 'Ingrese la segunda cadena (max 40 caracteres): $'
    msg_anagram db 10, 13, 'Las cadenas son anagramas. $'
    msg_not_anagram db 10, 13, 'Las cadenas NO son anagramas. $'
    msg_continue db 10, 13, 'Desea continuar? (S/N): $'
    
    ; Buferes de entrada
    input1 db 41 dup(0)    ; Bufer para primera entrada (40 caracteres + terminador nulo)
    input2 db 41 dup(0)    ; Bufer para segunda entrada (40 caracteres + terminador nulo)
    
    ; Almacenamiento temporal para procesamiento
    sorted1 db 41 dup(0)   ; Primera entrada ordenada
    sorted2 db 41 dup(0)   ; Segunda entrada ordenada
    
    ; Variables para contar longitud
    len1 db 0              ; Longitud de la primera cadena
    len2 db 0              ; Longitud de la segunda cadena
    
    new_line db 13, 10, '$' 
    temp_buffer db 41 dup(0)   ; Buffer temporal para procesar cadenas
.code

main proc
    ; Inicializar segmento de datos
    mov ax, @data
    mov ds, ax
    
    ; Para mostrar mensaje se usa la funcion 09h de la interrupcion 21h
    ; Mostrar mensaje de inicio
    lea dx,msg_inicio
    mov ah,09h
    int 21h

    ; Mostrar mensaje de integrante
    lea dx,msg_integrante1
    mov ah,09h
    int 21h       
    
start:
    call clear_buffers

    ; Solicitar y obtener primer input
    lea dx, msg_enter1
    mov ah, 09h
    int 21h
    
    ; Para leer la entrada del usuario se usa la funcion 0Ah de la interrupcion 21h
    lea dx, input1
    call read_input

    ; Procesar primera cadena
    lea si, input1
    lea di, sorted1
    call process_spaces    ; Procesar espacios primero
    lea si, sorted1
    call normalize_string
    mov len1, cl

    ; Solicitar y obtener segundo input
    lea dx, msg_enter2
    mov ah, 09h
    int 21h
    
    ; Para leer la entrada del usuario se usa la funcion 0Ah de la interrupcion 21h
    lea dx, input2
    call read_input

    ; Procesar segunda cadena
    lea si, input2
    lea di, sorted2
    call process_spaces    ; Procesar espacios primero
    lea si, sorted2
    call normalize_string
    mov len2, cl

    ; Verificar longitudes
    mov al, len1
    mov ah, len2
    cmp al, ah
    jne not_anagram_output ; Si las longitudes son diferentes no contando espacios, no son anagramas

    ; Ordenar primera cadena (ya procesada)
    lea si, sorted1
    lea di, sorted1
    call sort_string ; Ordenar primera cadena (ya procesada)

    ; Ordenar segunda cadena (ya procesada)
    lea si, sorted2
    lea di, sorted2
    call sort_string ; Ordenar segunda cadena (ya procesada)

    ; Comparar cadenas ordenadas
    call compare_strings ; Si son anagramas, se muestra el mensaje de anagrama

    jmp continue_prompt ; Si no son anagramas, se muestra el mensaje de no anagrama

not_anagram_output:
    ; Mostrar mensaje de no anagrama si longitudes son diferentes
    lea dx, msg_not_anagram
    mov ah, 09h
    int 21h

continue_prompt:
    ; Preguntar si desea continuar
    lea dx, msg_continue ; Para mostrar mensaje se usa la funcion 09h de la interrupcion 21h
    mov ah, 09h 
    int 21h

    ; Leer respuesta del usuario
    mov ah, 01h ; Para leer la entrada del usuario se usa la funcion 01h de la interrupcion 21h
    int 21h
    
    ; Convertir a mayúsculas
    cmp al, 'a'
    jl continue_check ; Si es menor que 'a' no se convierte
    sub al, 32  ; Convertir minúscula a mayúscula

continue_check:
    ; Agregar salto de línea despues de la respuesta
    push ax                 ; Guardar acumulador
    mov dx, offset new_line ; Agregar salto de linea
    mov ah, 09h
    int 21h
    pop ax                  ; Restaurar acumulador
    cmp al, 'S'
    je start
    cmp al, 's'
    je start

    ; Salir del programa
    mov ah, 4Ch
    int 21h
main endp

; Lee cadena de entrada del usuario
; DX debe apuntar al búfer de entrada antes de llamar
read_input proc
    ; Guardar registros
    push ax
    push di
    
    ; Copiar direccion de entrada a di
    mov di, dx
    mov byte ptr [di], 40  ; Longitud maxima del búfer
    mov ah, 0Ah            ; Entrada con búfer
    int 21h
    
    ; Convertir entrada a cadena terminada en nulo
    mov si, dx
    inc si          ; Saltar byte de longitud
    mov cl, [si]    ; Obtener longitud real de entrada
    inc si          ; Mover a entrada real
    xor ch, ch      ; Limpiar byte alto
    
    ; Terminar cadena con nulo
    add si, cx
    mov byte ptr [si], 0
    
    ; Restaurar registros
    pop di          ; Restaurar destino
    pop ax          ; Restaurar acumulador
    ret
read_input endp

; Normaliza cadena (elimina espacios, convierte a mayusculas)
normalize_string proc
    push ax
    push si         ; Guardar fuente
    push di         ; Guardar destino
    push bx         ; Guardar contador externo

    mov di, si
    mov bx, si
    xor cx, cx      ; Inicializar contador a 0

normalize_loop:
    mov al, [si]
    cmp al, 0
    je normalize_end

    ; Ignorar todos los caracteres de espacio y control
    cmp al, 33  
    jl skip_char
    
    ; Convertir a mayuscula si es minuscula
    cmp al, 'a'
    jl not_lowercase
    cmp al, 'z'
    jg not_lowercase
    sub al, 32      ; Convertir a mayuscula

not_lowercase:
    mov [bx], al    ; Almacenar caracter
    inc bx
    inc cx          ; Incrementar contador de caracteres validos

skip_char:
    inc si
    jmp normalize_loop

normalize_end:
    mov byte ptr [bx], 0  ; Terminar cadena con nulo
    pop bx          ; Restaurar contador externo
    pop di          ; Restaurar destino
    pop si          ; Restaurar fuente
    pop ax          ; Restaurar acumulador
    ret
normalize_string endp

; Ordena cadena usando burbuja
sort_string proc
    push ax         ; Guardar acumulador  
    push bx
    push cx
    push dx
    push si         ; Guardar fuente
    push di         ; Guardar destino

    ; Copiar entrada al destino
    mov cx, 41      ; Longitud maxima del buffer
copy_loop:
    mov al, [si]    ; Cargar desde la fuente
    mov [di], al    ; Guardar en el destino
    inc si          ; Incrementar fuente
    inc di          ; Incrementar destino
    dec cx          ; Decrementar contador
    jnz copy_loop ; Si no es 0, continuar

    ; Obtener longitud de cadena para ordenar
    mov si, di      ; Apuntar al final de la cadena copiada
    sub si, 41      ; Regresar al inicio
    xor cx, cx      ; Contador de longitud

length_loop:
    cmp byte ptr [si], 0 ; Si es 0, terminar
    je sort_start       ; Saltar al inicio de ordenamiento
    inc cx              ; Incrementar contador
    inc si              ; Incrementar fuente
    jmp length_loop     ; Continuar

sort_start:
    dec cx          ; Ajustar para el bucle
    jz sort_end     ; Si la longitud es 0, terminar

outer_loop:
    mov bx, cx      ; Guardar contador externo
    mov si, di      ; Inicio de la cadena
    sub si, 41      ; Regresar al inicio

inner_loop: ; Bucle interno de ordenamiento
    mov al, [si]    ; Cargar caracter
    mov ah, [si+1]  ; Cargar siguiente caracter
    cmp al, ah      ; Comparar caracteres
    jle no_swap     ; Si no es menor, no intercambiar

    ; Intercambiar caracteres
    mov [si], ah    ; Intercambiar caracteres
    mov [si+1], al  ; Intercambiar caracteres

no_swap:
    inc si          ; Incrementar fuente
    dec bx          ; Decrementar contador
    jnz inner_loop  ; Si no es 0, continuar

    loop outer_loop  ; Si no es 0, continuar

sort_end:
    pop di          ; Restaurar destino
    pop si          ; Restaurar fuente
    pop dx          ; Restaurar acumulador
    pop cx          ; Restaurar contador
    pop bx          ; Restaurar contador externo
    pop ax          ; Restaurar acumulador
    ret
sort_string endp

; Compara dos cadenas ordenadas
compare_strings proc
    push si
    push di
    push ax
    push cx         ; Guardar contador

    lea si, sorted1
    lea di, sorted2
    mov cx, 40      ; Longitud maxima de comparacion

compare_loop:
    mov al, [si]
    mov ah, [di]
    
    ; Comparar caracteres actuales
    cmp al, ah
    jne not_anagram ; Si no es igual, no es anagrama
    
    ; Verificar fin de cadenas
    cmp al, 0
    je is_anagram ; Si es 0, es anagrama
    
    inc si          ; Incrementar fuente
    inc di          ; Incrementar destino
    loop compare_loop ; Usar contador para seguridad

is_anagram:
    ; Mostrar mensaje de anagrama
    lea dx, msg_anagram
    mov ah, 09h
    int 21h
    jmp compare_end

not_anagram:
    ; Mostrar mensaje de no anagrama
    lea dx, msg_not_anagram
    mov ah, 09h
    int 21h

compare_end:
    pop cx          ; Restaurar contador
    pop ax
    pop di
    pop si
    ret
compare_strings endp

clear_buffers proc
    push si
    push cx

    ; Limpiar input1
    lea si, input1
    mov cx, 41      ; Longitud maxima del buffer
clear_input1:
    mov byte ptr [si], 0 ; Limpiar buffer 
    inc si
    loop clear_input1

    ; Limpiar input2
    lea si, input2
    mov cx, 41      ; Longitud maxima del buffer
clear_input2:
    mov byte ptr [si], 0 ; Limpiar buffer 
    inc si
    loop clear_input2

    ; Reiniciar longitudes
    mov len1, 0      ; Longitud de la primera cadena
    mov len2, 0      ; Longitud de la segunda cadena

    pop cx
    pop si
    ret
clear_buffers endp

; Nuevo procedimiento para procesar espacios
process_spaces proc
    push ax                 ; Guardar acumulador
    push si                 ; Guardar fuente
    push di                 ; Guardar destino

process_loop:
    mov al, [si]          ; Cargar carácter
    cmp al, 0             ; Verificar fin de cadena
    je process_end
    
    cmp al, ' '           ; Verificar si es espacio
    je skip_space
    cmp al, 9             ; Tab
    je skip_space
    cmp al, 13            ; CR
    je skip_space
    cmp al, 10            ; LF
    je skip_space
    
    ; Si no es espacio, copiar el carácter
    mov [di], al
    inc di

skip_space:
    inc si          ; Incrementar fuente
    jmp process_loop ; Continuar

process_end:
    mov byte ptr [di], 0  ; Terminar con null
    pop di                 ; Restaurar destino  
    pop si                 ; Restaurar fuente
    pop ax                 ; Restaurar acumulador
    ret
process_spaces endp

; Procedimiento para limpiar buffer temporal
clear_temp_buffer proc ; Procedimiento para limpiar buffer temporal
    push ax
    push cx
    push di

    mov cx, 41      ; Longitud maxima del buffer
    mov al, 0       ; Limpiar buffer temporal
clear_loop:
    mov [di], al    ; Limpiar buffer temporal 
    inc di
    loop clear_loop

    pop di          ; Restaurar destino 
    pop cx          ; Restaurar contador
    pop ax          ; Restaurar acumulador
    ret
clear_temp_buffer endp

end main

