.section .text
.global main

main:
	# Write code here to jump to supervisor mode 
	li t0, 1
	slli t0, t0, 11
	csrrw x0, mstatus, t0
	la t0, supervisor
	csrrw x0, mepc, t0
	mret
	
supervisor: 
################ Initialize your page tables here ################

	la t0, lvl3_pt
	la t1, lvl2_pt
	srli t1, t1, 12          
	slli t1, t1, 10          
	ori t1, t1, 0x1          
	sd t1, 0(t0)             

	la t0, lvl2_pt
	la t1, lvl1_pt_user
	srli t1, t1, 12
	slli t1, t1, 10
	ori t1, t1, 0x1
	sd t1, 0(t0)

	la t0, lvl1_pt_user
	la t1, lvl0_pt_user
	srli t1, t1, 12
	slli t1, t1, 10
	ori t1, t1, 0x1
	sd t1, 0(t0)

	la t0, lvl0_pt_user
	la t1, user_code        
	srli t1, t1,12
	slli t1, t1, 10
	ori t1, t1, 0xDF         
	sd t1, 0(t0)

	la t1, data_start        
	srli t1, t1, 12
	slli t1, t1, 10
	ori t1, t1, 0xDF         
	sd t1, 8(t0)             

	la a0, main              

	srli t0, a0, 30
	andi t0, t0, 0x1FF
	slli t0, t0, 3           
	la t1, lvl2_pt
	add t1, t1, t0           

	la t2, lvl1_pt_id
	srli t2, t2, 12
	slli t2, t2, 10
	ori t2, t2, 0x1
	sd t2, 0(t1)

	srli t0, a0, 21
	andi t0, t0, 0x1FF
	slli t0, t0, 3           
	la t1, lvl1_pt_id
	add t1, t1, t0           

	la t2, lvl0_pt_id
	srli t2, t2, 12
	slli t2, t2, 10
	ori t2, t2, 0x1
	sd t2, 0(t1)

	srli t0, a0, 12
	andi t0, t0, 0x1FF
	slli t0, t0, 3           
	la t1, lvl0_pt_id
	add t1, t1, t0           
	
	la t2, main
	srli t2, t2, 12
	slli t2, t2, 10
	ori t2, t2, 0xCF        
	sd t2, 0(t1)

	# 3. Configure SATP Register
	la t0, lvl3_pt
	srli t0, t0, 12          
	li t1, 9                 
	slli t1, t1, 60          
	or t0, t0, t1            
	la t1, satp_config
	sd t0, 0(t1)

####################################################################

	# Prepare a jump to user mode
	li t0, 0x100             
	csrrc x0, sstatus, t0   

################ DO NOT MODIFY THESE INSTRUCTIONS ################
	la t1, satp_config # load satp val
	ld t2, 0(t1)
	sfence.vma zero, zero
	csrrw zero, satp, t2
	sfence.vma zero, zero

	li t4, 0
	csrrw zero, sepc, t4
	sret
#################################################################### 
.align 12
user_code:
# Write user code here that does the following:
    # 1. Initialize four variables var1 , var2 , var3 , var4 in the data section with values 1 , 2 , 3 , 4.
    # 2. The user_code must load these variables into t1 , t2 , t3 , t4 registers (for reading during debug mode) and then loop back to itself.
# Don't forget to align the data section and user_code propely. For assembly directive usage, use the last reference given.

	li t0, 0x1000            
	
	li t1, 1
	li t2, 2
	li t3, 3
	li t4, 4

	sw t1, 0(t0)             # var1 = 1
	sw t2, 4(t0)             # var2 = 2
	sw t3, 8(t0)             # var3 = 3
	sw t4, 12(t0)            # var4 = 4

	lw t1, 0(t0)
	lw t2, 4(t0)
	lw t3, 8(t0)
	lw t4, 12(t0)

infinite_loop:
	j infinite_loop          # Loop back to itself

.section .data 
.align 12                    
.global data_start
data_start:
var1: .word 0
var2: .word 0
var3: .word 0
var4: .word 0

.align 3
satp_config: .dword  
# Set appropriate value for satp here.

.align 12
lvl3_pt: .space 4096
lvl2_pt: .space 4096
lvl1_pt_user: .space 4096
lvl0_pt_user: .space 4096
lvl1_pt_id: .space 4096
lvl0_pt_id: .space 4096

