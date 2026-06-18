
.section .text
.global main



main:
    # Prepare jump to super mode
    li t1, 1
    slli t1, t1, 11   #mpp_mask
    csrs mstatus, t1
    
    la t4, supervisor       #load address of user-space code
    csrrw zero, mepc, t4    #set mepc to user code
    
    la t5, page_fault_handler
    csrw mtvec, t5
   
    mret

supervisor:
################## Setting up page tables ##############
    # Set value in PTE2 (Initial Mapping)
    li a0,0x81000000
    li a1, 0x82000
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 16(a0)

    # To set V.A 0x0 -> P.A 0x0
    li a1, 0x82001
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set value in PTE1 (Initial Mapping)
    li a0,0x82000000
    li a1, 0x83000
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set Frame number in PTE0 (Initial Mapping)
    li a0,0x83000000
    li a1, 0x80000
    slli a1, a1, 0xa
    ori a1, a1, 0xef # D | A | G | - | X | W | R |V
    sd a1, 0(a0)

    li a1, 0x80001
    slli a1, a1, 0xa
    ori a1, a1, 0xef # D | A | G | - | X | W | R |V
    sd a1, 8(a0)

    # Set value in PTE1 (Code Mapping)
    li a0,0x82001000
    li a1, 0x83001
    slli a1, a1, 0xa
    ori a1, a1, 0x01 # | - | - | - |V
    sd a1, 0(a0)

    # Set value in PTE0 (Code Mapping)
    li a0,0x83001000
    li a1, 0x80001
    slli a1, a1, 0xa
    ori a1, a1, 0xfb # D | A | G | U | X | - | R |V
    sd a1, 0(a0)

    # Data Mapping
    li a1, 0x80002
    slli a1, a1, 0xa
    ori a1, a1, 0xf7 # D | A | G | U | - | W | R |V
    sd a1, 8(a0)
    

####################################################################

    # Prepare jump to user mode
    li t1, 0
    slli t1, t1, 8   #spp_mask
    csrs sstatus, t1

    # Configure satp
    la t1, satp_config 
    ld t2, 0(t1)
    sfence.vma zero, zero
    csrrw zero, satp, t2
    sfence.vma zero, zero

    li t4, 0       # load VA address of user-space code
    csrrw zero, sepc, t4    # set sepc to user code
    
    sret



###################################################################
##################### ADD CODE ONLY HERE  #########################
###################################################################
.align 4
page_fault_handler:
j handler
.align 3
reg_save:
.space 80          # to save 10 registers
next_page_table:
.dword 0x80003000  # physical address of next page table

handler:

csrrw a0, mscratch, a0  # mscratch <- a0
la a0, reg_save
sd t0, 0(a0)
sd t1, 8(a0)
sd t2, 16(a0)
sd t3, 24(a0)
sd a2, 32(a0)
sd a3, 40(a0)
sd a4, 48(a0)
sd a6, 56(a0)
sd a7, 64(a0)
csrr t0, mscratch
sd t0, 72(a0)

# reading trap details
csrr a0, mcause
csrr a2, mtval  # address which caused page-fault
la a7, next_page_table
ld a6, 0(a7)

srli a4, a2, 30
andi a4, a4, 0x1ff
slli a4, a4, 3
li a3, 0x81000000
add a3, a3, a4

ld a4, 0(a3)
andi t0, a4, 1
bne zero, t0, l2_valid

mv t0, a6
li t1, 512 
l1_loop:
    sd zero, 0(t0) 
    addi t0, t0, 8 
    addi t1, t1, -1 
    bnez t1, l1_loop 

srli t0, a6, 12 
slli t0, t0, 10 
ori t0, t0, 1
sd t0, 0(a3) 
mv a4, t0 
li t0, 0x1000 
add a6, a6, t0 
sd a6, 0(a7)

l2_valid:
srli a4, a4, 10
slli a3, a4, 12  # a3 stores the physical base address of L[1]

srli a4, a2, 21
andi a4, a4, 0x1ff
slli a4, a4, 3
add a3, a3, a4

ld a4, 0(a3)
andi t0, a4, 1
bne zero, t0, l1_valid

mv t0, a6
li t1, 512 
l0_loop:
    sd zero, 0(t0) 
    addi t0, t0, 8 
    addi t1, t1, -1 
    bnez t1, l0_loop 

srli t0, a6, 12 
slli t0, t0, 10 
ori t0, t0, 1
sd t0, 0(a3) 
mv a4, t0 
li t0, 0x1000 
add a6, a6, t0 
sd a6, 0(a7)

l1_valid:
srli a4, a4, 10
slli a3, a4, 12  # a3 stores the physical base address of L[0]

srli a4, a2, 12
andi a4, a4, 0x1ff
slli a4, a4, 3
add a3, a3, a4

#Cheking fault types
li t0, 12                   # Instruction Page Fault
beq a0, t0, inst_fault
li t0, 13                   # Load Page Fault (Data)
beq a0, t0, data_fault
li t0, 15                   # Store Page Fault (Data)
beq a0, t0, data_fault
j done

inst_fault:

li t0, 0x80001000
mv t1, a6
li t2, 512

copy_loop:
    ld t3, 0(t0)
    sd t3, 0(t1)
    addi t0, t0, 8
    addi t1, t1, 8
    addi t2, t2, -1
    bne zero, t2, copy_loop

# Update L0 PTE, D|A|G|U|X|-|R|V = 0xfb
srli t0, a6, 12
slli t0, t0, 10 
ori t0, t0, 0xfb 
sd t0, 0(a3) # Store into Leaf PTE 
li t0, 0x1000 
add a6, a6, t0 # Increment to next free page 
sd a6, 0(a7) # Save updated free page pointer 
j done

data_fault:
    li t0, 0x80002              # PPN for User Data (0x80002000)
    slli t0, t0, 10
    ori t0, t0, 0xf7            # Permissions: D|A|G|U|-|W|R|V = 0xf7
    sd t0, 0(a3)                # Store into Leaf PTE

done:
    sfence.vma zero, zero
    la a0, reg_save
    ld t0, 0(a0)
    ld t1, 8(a0)
    ld t2, 16(a0)
    ld t3, 24(a0)
    ld a2, 32(a0)
    ld a3, 40(a0)
    ld a4, 48(a0)
    ld a6, 56(a0)
    ld a7, 64(a0)
    ld a0, 72(a0)
    mret 

###################################################################
###################################################################



.align 12
user_code:
    la t1,var_count
    lw t2, 0(t1)
    addi t2, t2, 1
    sw t2, 0(t1)

    la t5, code_jump_position
    lw t3, 0(t5)
    li t4, 0x2000
    add t3, t3, t4
    sw t3, 0(t5)
    
    jalr x0, t3


.data
.align 12
var_count:  .word  0
code_jump_position: .word 0x0000


.align 8
# Value to set in satp
satp_config: .dword 0x8000000000081000
