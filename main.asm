global _start
extern exit
extern find_word
extern fprint_string
extern print_string
extern read_line
extern string_length

section .bss
input: resb 256

section .rodata
%include "colon.inc"
%include "words.inc"
last_colon
error_message_stdin: db "Error! stdin is closed!", 10, 0
error_message_key: db "Error! Could not find key!", 10, 0

section .text

_start:
  mov rdi, input
  mov rsi, 256
  call read_line
  test rax, rax
  jz .err_stdin
  mov rdi, input
  mov rsi, word_3
  call find_word
  test rax, rax
  jz .err_key
  mov rdi, rax
  add rdi, 8
  call string_length
  add rdi, rax
  inc rdi
  call print_string
  mov rdi, 0
  call exit
.err_stdin:
  mov rdi, error_message_stdin
  mov rsi, 2
  call fprint_string
  mov rdi, 1
  call exit
.err_key:
  mov rdi, error_message_key
  mov rsi, 2
  call fprint_string
  mov rdi, 2
  call exit

