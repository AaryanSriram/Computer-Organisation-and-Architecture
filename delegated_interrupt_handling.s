.data
.align 4
val1: .word 3
val2: .word 5
.section .text

.global main
main:

# Configure CSR registers (medeleg, mstatus, mepc, mtvec, stvec etc.)
# Execute mret to initiate downward transition to User code

la t0, mtrap_handler
csrrw x0, mtvec, t0

la t0, strap_handler
csrrw x0, stvec, t0

li t0, 1
slli t0, t0, 8
csrrs x0, medeleg, t0

li t0, 3
slli t0, t0, 11
csrrc x0, mstatus, t0

li t0, 1
slli t0, t0, 7
csrrs x0, mstatus, t0

la t0, ucode
csrrw x0, mepc, t0
mret


.align 4
mtrap_handler:
# Process traps originating from the strap_handler
# Perform the multiplication operation
# Flip a0 to 0
# Set mepc back to strap_handler and execute mret

li t0, 3
slli t0, t0, 11
csrrc x0, mstatus, t0

li t0, 1
slli t0, t0, 11
csrrs x0, mstatus, t0

mul a1, a1, a2
li a0, 0

la t0, strap_handler
csrrw x0, mepc, t0
mret



scode:
# Execute sret to initiate transition to User mode after setting the CSRs
li t0, 1
slli t0, t0, 8
csrrc x0, sstatus, t0

li t0, 1
slli t0, t0, 5
csrrs x0, sstatus, t0

la t0, ucode1
csrrw x0, sepc, t0

sret


.align 4
strap_handler:
csrr t6, sstatus
# The Dispatcher
# Check if a0 == 0 or a0 == 1
# If a0 == 0: jump to scode (to setup S to U transition)
# If a0 == 1: execute ecall to jump up to mtrap_handler
beq a0, x0, scode
ecall


ucode:
# Note: Handle initial variable loading here if using a single User block
lw a1, val1
lw a2, val2
ecall


ucode1:
# Perform the addition operation
# Flip a0 to 1
# The ecall should invoke the supervisor’s trap handler
add a1, a1, a2
li a0, 1
ecall
