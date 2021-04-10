global find_word
extern string_equals
extern _colon_1

section .text

; rdi -- ptr to key
; rsi -- ptr to last word in dict
find_word:
  mov r10, rsi
  mov r9, _colon_1
.loop:
  mov rsi, r9
  add rsi, 8
  call string_equals
  test rax, rax
  jnz .exit
  cmp r9, r10
  je .return_0
  mov r9, [r9]
  jmp .loop
.return_0:
  xor r9, r9
.exit:
  mov rax, r9
  ret

