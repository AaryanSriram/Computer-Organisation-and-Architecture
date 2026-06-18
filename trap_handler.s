.section .text.init
.global _start
_start:
# 1. Initialize Stack Pointer (sp)
# 2. Setup Trap Vectors (mtvec)
# 3. Prepare transition to User Mode (mstatus and mepc)
# 4. Execute mret to jump to ucode

    la sp, _stack_top

    la t0, mtrap_handler
    csrrw x0, mtvec, t0

    li t0, 3
    slli t0, t0, 11
    csrrc x0, mstatus, t0

    li t0, 1
    slli t0, t0, 7
    csrrs x0, mstatus, t0

    la t0, ucode
    csrrw x0, mepc, t0
    mret

.section .text
.align 4
mtrap_handler:
# --- Context Saving ---
    addi sp, sp, -56
    sd t0, 0(sp)
    sd t1, 8(sp)
    sd t2, 16(sp)
    sd t3, 24(sp)
    sd t4, 32(sp)
    sd t5, 40(sp)
    sd t6, 48(sp)
    sd sp, 56(sp)
# Save registers used in ucode. In the ideal case should save all registers.
# --- Decode mcause ---
    li t1, 2
    li t2, 3
    li t3, 4
    li t4, 5
    li t5, 8
    csrr t0, mcause
    beq t0, t1, IllegalInstruction
    beq t0, t2, BreakPoint
    beq t0, t3, laMisaligned
    beq t0, t4, laFault
    beq t0, t5, EnvCall

# Implement logic to handle causes 2, 3, 4, 5, 8
BreakPoint:
    csrr t0, mepc
    addi t0, t0, 2
    csrrw x0, mepc, t0
    la a0, 0xBEEF
    j end

IllegalInstruction:
    csrr s9, mtval
    csrr t0, mepc
    addi t0, t0, 4
    csrrw x0, mepc, t0
    j end

EnvCall:
    csrr t0, mepc
    addi t0, t0, 4
    csrrw x0, mepc, t0
    la a0, 0xFEED
    j end

laMisaligned:
    csrr s10, mtval
    csrr t0, mepc
    addi t0, t0, 4
    csrrw x0, mepc, t0
    j end

laFault:
    csrr s11, mtval
    csrr t0, mepc
    addi t0, t0, 4
    csrrw x0, mepc, t0
    j end

# --- Context Restoration ---
end:
    ld t0, 0(sp)
    ld t1, 8(sp)
    ld t2, 16(sp)
    ld t3, 24(sp)
    ld t4, 32(sp)
    ld t5, 40(sp)
    ld t6, 48(sp)
    ld sp, 56(sp)
mret

ucode:
    # --- Sequence of Exception Tests ---
    # Trigger exceptions one after another to test your handler logic
    .word 0x00000000
    ebreak
    la t0, ucode
    ld t0, 0(t0)
    li t0, 0x0
    ld t1, 0(t0)
    ecall
    j .

.section .bss
.align 16
_stack_low:
.space 4096
_stack_top:
