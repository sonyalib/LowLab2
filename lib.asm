global exit
global string_length
global print_string
global fprint_string
global print_char
global print_newline
global print_uint
global print_int
global read_char
global read_word
global read_line
global parse_uint
global parse_int
global string_equals
global string_copy

section .text
 
; Принимает код возврата и завершает текущий процесс
exit: 
  mov rax, 60
  syscall

; Принимает указатель на нуль-терминированную строку, возвращает её длину
string_length:
  xor rax, rax
.loop:
  cmp byte [rdi+rax], 0
  je .exit
  inc rax
  jmp .loop
.exit:
  ret

; Принимает указатель на нуль-терминированную строку, выводит её в stdout
print_string:
  mov rsi, 1

fprint_string:
  call string_length
  mov rdx, rsi
  mov rsi, rdi
  mov rdi, rdx
  mov rdx, rax
  mov rax, 1
  syscall
  ret

; Переводит строку (выводит символ с кодом 0xA)
print_newline:
  mov rdi, 10
  ; Дальше выполняется print_char

; Принимает код символа и выводит его в stdout
print_char:
  push rdi
  mov rax, 1
  mov rdi, 1
  mov rsi, rsp
  mov rdx, 1
  syscall
  pop rdi
  ret

; Выводит знаковое 8-байтовое число в десятичном формате 
print_int:
  test rdi, rdi
  jns print_uint
  push rdi
  mov rdi, '-'
  call print_char
  pop rdi
  neg rdi

; Выводит беззнаковое 8-байтовое число в десятичном формате 
; Совет: выделите место в стеке и храните там результаты деления
; Не забудьте перевести цифры в их ASCII коды.
print_uint:
  mov rax, rdi
  xor rcx, rcx
  mov rsi, 10
.loop:
  xor rdx, rdx
  div rsi
  add rdx, '0'
  dec rsp
  mov [rsp], dl
  inc rcx
  test rax, rax
  jnz .loop
  mov rax, 1
  mov rdi, 1
  mov rsi, rsp
  mov rdx, rcx
  push rcx
  syscall
  pop rcx
  add rsp, rcx
  ret

; Принимает два указателя на нуль-терминированные строки, возвращает 1 если они равны, 0 иначе
string_equals:
  xor rcx, rcx
.loop:
  mov al, [rdi+rcx]
  cmp [rsi+rcx], al
  jne .ret_neq
  test al, al
  jz .ret_eq
  inc rcx
  jmp .loop
.ret_eq:
  mov rax, 1
  ret
.ret_neq:
  xor rax, rax
  ret

; Читает один символ из stdin и возвращает его. Возвращает 0 если достигнут конец потока
read_char:
  push qword 0
  xor rax, rax
  xor rdi, rdi
  mov rsi, rsp
  mov rdx, 1
  syscall
  test rax, rax
  js .error
  pop rax
  ret
.error:
  xor rax, rax
  ret 

; Принимает: адрес начала буфера, размер буфера
; Читает в буфер слово из stdin, пропуская пробельные символы в начале, .
; Пробельные символы это пробел 0x20, табуляция 0x9 и перевод строки 0xA.
; Останавливается и возвращает 0 если слово слишком большое для буфера
; При успехе возвращает адрес буфера в rax, длину слова в rdx.
; При неудаче возвращает 0 в rax
; Эта функция должна дописывать к слову нуль-терминатор

read_word:
  push r12
  push r13
  push r14
  mov r12, rdi
  mov r13, rsi
  mov byte [r12], 0
.skip_whitespace:
  call read_char
  test rax, rax
  jz .error
  cmp rax, 32
  je .skip_whitespace
  cmp rax, 10
  je .skip_whitespace
  cmp rax, 9
  je .skip_whitespace
  xor r14, r14
.loop:
  cmp r14, r13
  jge .error
  mov [r12+r14], al
  inc r14
  call read_char
  test rax, rax
  jz .word_end
  cmp rax, 32
  je .word_end
  cmp rax, 10
  je .word_end
  cmp rax, 9
  je .word_end
  jmp .loop
.word_end:
  cmp r14, r13
  jge .error
  mov byte [r12+r14], 0
  mov rax, r12
  mov rdx, r14
  jmp .ret
.error:
  xor rax, rax
  xor rdx, rdx
.ret:
  pop r14
  pop r13
  pop r12
  ret

read_line:
  push r12
  push r13
  push r14
  mov r12, rdi
  mov r13, rsi
  mov byte [r12], 0
  xor r14, r14
.loop:
  cmp r14, r13
  jge .error
  call read_char
  test rax, rax
  jz .line_end
  cmp rax, 10
  je .line_end
  mov [r12+r14], al
  inc r14
  jmp .loop
.line_end:
  cmp r14, r13
  jge .error
  mov byte [r12+r14], 0
  mov rax, r12
  mov rdx, r14
  jmp .ret
.error:
  xor rax, rax
  xor rdx, rdx
.ret:
  pop r14
  pop r13
  pop r12
  ret

; Принимает указатель на строку, пытается
; прочитать из её начала беззнаковое число.
; Возвращает в rax: число, rdx : его длину в символах
; rdx = 0 если число прочитать не удалось
parse_uint:
  xor rax, rax
  xor rcx, rcx
  xor rsi, rsi
  mov r10, 10
.loop:
  mov sil, [rdi+rcx]
  sub rsi, '0'
  js .exit
  cmp rsi, 9
  jg .exit
  mul r10
  add rax, rsi
  inc rcx
  jmp .loop
.exit:
  mov rdx, rcx
  ret

; Принимает указатель на строку, пытается
; прочитать из её начала знаковое число.
; Если есть знак, пробелы между ним и числом не разрешены.
; Возвращает в rax: число, rdx : его длину в символах (включая знак, если он был) 
; rdx = 0 если число прочитать не удалось
parse_int:
  cmp byte [rdi], '+'
  je .parse_plus
  cmp byte [rdi], '-'
  je .parse_minus
  call parse_uint
  ret
.parse_plus:
  inc rdi
  call parse_uint
  inc rdx
  ret
.parse_minus:
  inc rdi
  call parse_uint
  neg rax
  inc rdx
  ret

; Принимает указатель на строку, указатель на буфер и длину буфера
; Копирует строку в буфер
; Возвращает длину строки если она умещается в буфер, иначе 0
string_copy:
  xor rax, rax
  test rdx, rdx
  jz .exit
.loop:
  mov cl, [rdi+rax]
  mov [rsi+rax], cl
  test cl, cl
  jz .exit
  inc rax
  cmp rax, rdx
  jle .loop
  xor rax, rax
.exit:
  ret

