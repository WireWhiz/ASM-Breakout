; all the main game logic/drawing happens here
default rel

global run
global WIDTH
global HEIGHT
global writeBounds;

extern draw
extern malloc
extern free

section .data
    framebuffer     dq 0x0000000000000000
    framebuffer_end dq 0x0000000000000000

    WIDTH dw 700
    HEIGHT dw 400
    box_width  db 40
    box_height db 20

    green dd 0x00ff00ff
    black dd 0x000000ff
    white dd 0xffffffff
    grey  dd 0xf0f0f0ff

    margin dw 2
    box_mem_size dq 8
    boxes dq 0
    num_boxes_x dw 0
    num_boxes_y dw 4

    ball_position dq 0 ;Store both x and y in the same dword as words
    ball_velocity dq 0

    oneandhalf dd 1.5
    n_one dd -1.0
    zero dd 0.0
section .text

run:
    push rbp
    mov [framebuffer], rdi ;framebuffer
    movzx rax, WORD [WIDTH]
    movzx rsi, WORD [HEIGHT]
    mul rsi
    mov rsi, 4
    mul rsi
    add rax, rdi
    mov [framebuffer_end], rax ; We use this to make sure we don't write past the framebuffer

    call clear_screen
    call draw

    ; Calculate how many boxes we need
    movzx rax, WORD [WIDTH]
    mov rdx, 0x0
    movzx rdi, BYTE [box_width]
    add di, WORD [margin]; width of the box plus margin
    div rdi ; Divide width by box size
    mov word [num_boxes_x], ax ; save horizontal boxes
    movzx rdi, WORD [num_boxes_y] ; Multiply boxes by how many layers we want
    mul rdi

    ; Allocate memory for boxes
    mov rdi, [box_mem_size]
    mul rdi
    mov rdi, rax
    call [rel malloc wrt ..got]
    mov [boxes], rax

    ; Set up scene
    call clear_screen
    call init_boxes

    ; Set ball velocity
    movss xmm0, [oneandhalf]
    movss [ball_velocity],     xmm0
    movss [ball_velocity + 4], xmm0

    ; Call our main loop here
    mov rcx, 0
    call run_loop

    ; Cleanup our memory here
    mov rdi, [boxes]
    call [rel free wrt ..got]

    pop rbp

    ret

run_loop:
    ; move paddle
    ; move ball
    call update_ball
    ; check for collision
    call check_hit_wall
    call check_hit_boxes

    push rbp
    mov rbp, rsp
    call draw
    pop rbp

    cmp rax, 1
    je run_loop
    ret

init_boxes:
    ; box
    ; word x
    ; word y
    ; byte alive
    push rcx

    mov r8, [box_mem_size]; offset
    mov rdi,  [boxes]; memory
    mov esi, DWORD [green]

    mov rcx, 0; y
init_boxes_y_loop:
    mov r11, 0; x

    movzx rax, byte [box_height]
    add ax, word [margin]
    mul cx
    movzx r9, word [HEIGHT]
    sub r9, rax
    sub r9b, byte [box_height]
    sub r9w, word [margin]
init_boxes_x_loop:

    movzx rax, byte [box_width]; Set X
    add ax, word [margin]
    mul r11w
    add ax, word [margin]

    mov word [rdi], ax
    mov word [rdi + 2], r9w
    mov byte [rdi + 4], 1

    push r11

    push rdi
    push rsi
    push r9
    mov rdi, [rdi]
    movzx rsi, byte [box_width]
    movzx rdx, byte [box_height]
    mov r9, [green]
    call draw_box
    pop r9
    pop rsi

            push rsi
            push r10
            push r9
            push r8
            push rcx
            push rbp
            mov rbp, rsp
            call draw   ; This is only here for the cool sequential box pop in effect
            pop rbp
            pop rcx
            pop r8
            pop r9
            pop r10
            pop rsi
    pop rdi

    pop r11

    add rdi, r8

    add r11, 1
    cmp r11w, word [num_boxes_x]
    jl init_boxes_x_loop

    add rcx, 1
    cmp cx, word [num_boxes_y]
    jl init_boxes_y_loop

    pop rcx
    ret

clear_screen:
    push rax
    push rbx
    push rdi
    mov rdi, [framebuffer]
    movzx rax, WORD [WIDTH]
    movzx rbx, WORD [HEIGHT]
    mul rbx
    mov rbx, 3
    mul rbx
clear_screen_loop:
    mov byte [rdi], 0x0
    add rdi, 1
    sub rax, 1

    cmp rax, 0
    jnz clear_screen_loop
    pop rdi
    pop rbx
    pop rax
    ret

update_ball:
    ; First erase the ball
    movss xmm0, [ball_position]
    movss xmm1, [ball_position + 4]
    call float_to_box_chord
    mov rdi, rax
    mov rsi, 4
    mov rdx, 4
    mov r9, [black]
    call draw_box

    ; Move the ball
    movss xmm0, [ball_velocity] ; X
    movss xmm1, [ball_position]
    addss xmm0, xmm1
    movss [ball_position], xmm0

    movss xmm0, [ball_velocity + 4] ; Y
    movss xmm1, [ball_position + 4]
    addss xmm0, xmm1
    movss [ball_position + 4], xmm0

    ; Re-draw the ball
    movss xmm0, [ball_position]
    movss xmm1, [ball_position + 4]
    call float_to_box_chord
    mov rdi, rax
    mov rsi, 4
    mov rdx, 4
    mov r9, [white]
    call draw_box

    ret

update_paddle:

    ret

check_hit_wall:
    movzx rdi, word [WIDTH]
    cvtsi2ss xmm1, rdi ; Check if we hit the far wall
    movss xmm0, [ball_position]
    ucomiss xmm0, xmm1
    ja bounce_vertical

    cvtsi2ss xmm1, [zero]; Check if we hit the close wall
    ucomiss xmm1, xmm0
    ja bounce_vertical

    movzx rdi, word [HEIGHT]
    cvtsi2ss xmm1, rdi ; Check if we hit the celing
    movss xmm0, [ball_position + 4]
    ucomiss xmm0, xmm1
    ja bounce_horizontal

    cvtsi2ss xmm1, [zero]; Check if we hit the floor
    ucomiss xmm1, xmm0
    ja bounce_horizontal

    ret

check_hit_boxes:
    mov rdi, [boxes]

    mov rcx, 0
    movzx r9, word [num_boxes_x]
    movzx rax, word [num_boxes_y]
    mul r9
    mov r9, rax

check_hit_boxes_loop:
    movzx eax, byte [rdi + 4] ; If this box isn't alive, skip it
    cmp eax, 0
    jz check_hit_boxes_loop_continue

    call ball_in_box
    cmp eax, 0
    jz check_hit_boxes_loop_continue ; if the ball isn't in the box continue

    ; If it is in the box, remove it and set it to not alive
    push rdi
    push r9

    mov rdi, [rdi]
    movzx rsi, byte [box_width]
    movzx rdx, byte [box_height]
    mov r9d, [black]
    call draw_box

    pop r9
    pop rdi

    mov byte [rdi + 4], 0 ; Set block inactive
    call bounce_block

check_hit_boxes_loop_continue:
    add rdi, 8
    add rcx, 1
    cmp rcx, r9
    jl check_hit_boxes_loop

    ret

bounce_block:
    push rdi
    push rsi

    ; get ball position (xmm0, xmm1)
    movss xmm0, [ball_position]
    movss xmm1, [ball_position + 4]

    ; get box center (xmm2, xmm3)
    movzx rsi, word [rdi]
    cvtsi2ss xmm2, rsi
    movzx rsi, word [rdi + 2]
    cvtsi2ss xmm3, rsi

    movzx rsi, byte [box_width]
    cvtsi2ss xmm4, rsi
    movzx rsi, byte [box_height]
    cvtsi2ss xmm5, rsi

    mov rsi, qword 2 ; I should have used a constant float here, but I'm lazy
    cvtsi2ss xmm6, rsi
    divss xmm4, xmm6 ; divide bounds by 2
    divss xmm5, xmm6

    addss xmm2, xmm4 ; add bounds to center
    addss xmm3, xmm5

    ; Get deltas from center, and normalize by box bounds
    subss xmm0, xmm2 ; x minus center
    subss xmm1, xmm3
    divss xmm0, xmm4 ; x divided by box_width / 2
    divss xmm1, xmm5

    ; Flip negitives
    movd eax, xmm0
    movd esi, xmm1
    and eax, 0x7FFFFFFF ; Force the parady bit to always be 0, or positive
    and esi, 0x7FFFFFFF
    movd xmm0, eax
    movd xmm1, esi
    ; movss xmm6, [zero]
    ;movss xmm7, [n_one]
    ;ucomiss xmm0, xmm6
    ;ja $ + 6 ; skip next instruction if we're above 0
    ;mulss xmm0, xmm7
    ;ucomiss xmm1, xmm6
    ;ja $ + 6 ; skip next instruction if we're above 0
    ;mulss xmm1, xmm7

    ; Bounce off the further side
    pop rsi
    pop rdi
    ucomiss xmm1, xmm0
    ja bounce_horizontal
    jmp bounce_vertical
    ret




ball_in_box:
    ; rdi box
    push rsi
    movss xmm0, [ball_position] ; Retreve x
    cvtss2si eax, xmm0
    movzx ebx, word [rdi]

    cmp eax, ebx         ; check left bound
    jl ball_in_box_false

    movzx rsi, byte [box_width]
    add rbx, rsi ; check right bound
    movzx rsi, word [margin]
    add rbx, rsi ; add margin
    cmp eax, ebx
    ja ball_in_box_false

    movss xmm0, [ball_position + 4] ; Retreve y
    cvtss2si eax, xmm0
    movzx ebx, word [rdi + 2]

    cmp eax, ebx         ; check bottom bound
    jl ball_in_box_false

    movzx rsi, byte [box_height]
    add rbx, rsi; check top bound
    movzx rsi, word [margin]
    add rbx, rsi ; add margin
    cmp eax, ebx
    ja ball_in_box_false

    mov rax, 1
    pop rsi
    ret
ball_in_box_false:
    mov rax, 0
    pop rsi
    ret

bounce_vertical:
    movss xmm1, [n_one]
    movss xmm0, [ball_velocity]
    mulss xmm0, xmm1
    movss [ball_velocity], xmm0
    ret

bounce_horizontal:
    movss xmm1, [n_one]
    movss xmm0, [ball_velocity + 4]
    mulss xmm0, xmm1
    movss [ball_velocity + 4], xmm0
    ret

float_to_box_chord:
    ;xmm0 x
    ;xmm1 y
    ;return rax
    cvtss2si rax, xmm1 ; Get y and convert to int
    shl rax, 16; Shift bits for y up a word
    cvtss2si rbx, xmm0 ; Convert x to int
    or rax, rbx; Combine
    ret

draw_box:
    ; rdi box x y (rdi should be a dword with each word being a vector component)
    ; rsi width
    ; rdx height
    ; r9 color
    push rdi
    push rsi
    push rdx
    push r8
    push r9
    movzx r10, word [rsp + 32 + 2]
    movzx rsi, word [rsp + 32]
    mov rdi, [framebuffer]

    ;Add position offset to framebuffer pointer
    mov QWORD rax, 4
    mul rsi
    add rdi, rax ; x added

    movzx rax, WORD [WIDTH]
    mul r10
    mov rbx, QWORD  4
    mul rbx
    add rdi, rax ; y added
    sub rdi, 1

    ; rdi is now pointing to the first pixel we want to color
    mov r10, [rsp + 16] ; Get box height from stack


    movzx r8, WORD [WIDTH]; offset to increment by on the y loop
    sub r8, [rsp + 24]
    mov rax, QWORD 4
    mul r8
    mov r8, rax

    jmp draw_box_y_loop

draw_box_y_loop:
    mov rsi, [rsp + 24] ; Set to box width
draw_box_x_loop:
    ; make sure we aren't writing past the buffer
    cmp [framebuffer_end], rdi
    jle end_draw_box

    ; Write the color
    mov DWORD [rdi], r9d
    add rdi, 4
    sub rsi, 1
    cmp rsi, 0
    jnz draw_box_x_loop

    add rdi, r8
    sub r10, 1
    cmp r10, 0
    jnz draw_box_y_loop
end_draw_box:
    pop r9
    pop r8
    pop rdx
    pop rsi
    pop rdi
    ret