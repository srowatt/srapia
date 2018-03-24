section .text
global _start

_start:
  xor eax, eax              ; init eax 0
  xor ebx, ebx              ; init ebx 0
  xor esi, esi              ; init esi 0
  jmp _socket               ; jmp to _socket

_socket_call:
  mov al, 0x66              ; invoke SYS_SOCKET (kernel opcode 102)
  inc byte bl               ; increment bl (1=socket, 2=bind, 3=listen, 4=accept)
  mov ecx, esp              ; move address arguments struct into ecx
  int 0x80                  ; call SYS_SOCKET
  jmp esi                   ; esi is loaded with a return address each call to _socket_call

_socket:
  push byte 6               ; push 6 onto the stack (IPPROTO_TCP)
  push byte 1               ; push 1 onto the stack (SOCK_STREAM)
  push byte 2               ; push 2 onto the stack (PF_INET)
  mov esi, _bind            ; move address of _bind into ESI
  jmp _socket_call          ; jmp to _socket_call

_bind:
  mov edi, eax              ; move return value of SYS_SOCKET into edi (file descriptor for new socket, or -1 on error)
  xor edx, edx              ; init edx 0
  push dword edx            ; end struct on stack (arguments get pushed in reverse order)
  push word 0x6022          ; move 24610 dec onto stack
  push word bx              ; move 1 dec onto stack AF_FILE
  mov ecx, esp              ; move address of stack pointer into ecx
  push byte 0x10            ; move 16 dec onto stack
  push ecx                  ; push the address of arguments onto stack
  push edi                  ; push the file descriptor onto stack

  mov esi, _listen          ; move address of _listen onto stack
  jmp _socket_call          ; jmp to _socket_call

_listen:
  inc bl                    ; bl = 3
  push byte 0x01            ; move 1 onto stack (max queue length argument)
  push edi                  ; push the file descriptor onto stack
  mov esi, _accept          ; move address of _accept onto stack
  jmp _socket_call          ; jmp to socket call

_accept:
  push edx                  ; push 0 dec onto stack (address length argument)
  push edx                  ; push 0 dec onto stack (address argument)
  push edi                  ; push the file descriptor onto stack
  mov esi, _fork            ; move address of _fork onto stack
  jmp _socket_call          ; jmp to _socket_call

_fork:
  mov esi, eax              ; move return value of SYS_SOCKET into esi (file descriptor for accepted socket, or -1 on error)
  mov al, 0x02              ; invoke SYS_FORK (kernel opcode 2)
  int 0x80                  ; call SYS_FORK
  test eax, eax             ; if return value of SYS_FORK in eax is zero we are in the child process
  jz _write                 ; jmp in child process to _write

  xor eax, eax              ; init eax 0
  xor ebx, ebx              ; init ebx 0
  mov bl, 0x02              ; move 2 dec in ebx lower bits
  jmp _listen               ; jmp in parent process to _listen

_write:
  mov ebx, esi              ; move file descriptor into ebx (accepted socket id)
  push edx                  ; push 0 dec onto stack then push a bunch of ascii (http headers & reponse body)
                            ;
                            ; HTTP/1.0 200 OK
                            ; Content-Type: application/json
                            ;
                            ; {"response":"Hello World!!"}
                            ;
  push dword 0x0a0d7d22     ; [\n][\r]}"
  push dword 0x2121646c     ; !!dl
  push dword 0x726f5720     ; roW
  push dword 0x6f6c6c65     ; olle
  push dword 0x223a2248     ; H":"
  push dword 0x65736e6f     ; esno
  push dword 0x70736572     ; pser
  push dword 0x227b0a0d     ; "{[\n][\r]
  push dword 0x0a0d6e6f     ; [\n][\r]no
  push dword 0x736a2f6e     ; sj/n
  push dword 0x6f697461     ; oita
  push dword 0x63696c70     ; cilp
  push dword 0x7061203a     ; pa :
  push dword 0x65707954     ; epyT
  push dword 0x2d746e65     ; -tne
  push dword 0x746e6f43     ; tnoC
  push dword 0x0a4b4f20     ; \nKO
  push dword 0x30303220     ; 002
  push dword 0x302e312f     ; 0.1/
  push dword 0x50545448     ; PTTH  
  mov al, 0x04              ; invoke SYS_WRITE (kernel opcode 4)
  mov ecx, esp              ; move address of stack arguments into ecx
  mov dl, 64                ; move 64 dec into edx lower bits (length in bytes to write)
  int 0x80                  ; call SYS_WRITE

_close:
  mov al, 6                 ; invoke SYS_CLOSE (kernel opcode 6)
  mov ebx, esi              ; move esi into ebx (accepted socket file descriptor)
  int 0x80                  ; call SYS_CLOSE
  mov al, 6                 ; invoke SYS_CLOSE (kernel opcode 6)
  mov ebx, edi              ; move edi into ebx (new socket file descriptor)
  int 0x80                  ; call SYS_CLOSE

_exit:
  mov eax, 0x01             ; invoke SYS_EXIT (kernel opcode 1)
  xor ebx, ebx              ; 0 errors
  int 0x80                  ; call SYS_EXIT
