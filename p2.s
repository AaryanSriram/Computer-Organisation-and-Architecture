.section .data
.global ans # need to declare as a global variable
ans: .space 40

.section .text
.global decrypt # need to declare as a global variable

decrypt:
    la a2, ans
    li t4, 0
    j loop_1
loop_1:
    lb t2, 0(a0)    # stores cipher_text[i]
    beqz t2, end
    addi a0, a0, 1
    li t0, 0
    la a3, substitution
    la a4, alphabet
    addi t4, t4, 1
    j loop_2

loop_2:
    li t5, 26
    beq t0, t5, loop_1
    lb t1, 0(a3)
    beq t1, t2, store_word
    addi a3, a3, 1
    addi a4, a4, 1
    addi t0, t0, 1
    j loop_2
    
store_word:
    lb t3, 0(a4)
    sb t3, 0(a2)
    addi a2, a2, 1
    j loop_1

end:
mv a0, t4
# perform decryption over the string cipher_text
ret
