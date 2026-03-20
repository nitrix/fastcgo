//go:build arm64

#include "go_asm.h"
#include "textflag.h"

// arm64 calling convention (same on Linux, macOS, Windows):
//   arg0..arg3 = R0..R3
//   return     = R0
//
// Register allocation:
//   R4  = function pointer (callee-saved, survives the C call)
//   R19 = saved original SP (callee-saved, survives the C call)
//   R10/R11 = temps (caller-saved, used only before BL)
//
// Windows-only callee-saved registers:
//   R20 = saved TEB StackBase
//   R21 = saved TEB StackLimit

#define UCALL_FN   R4
#define UCALL_RET  R0
#define UCALL_A0   R0
#define UCALL_A1   R1
#define UCALL_A2   R2
#define UCALL_A3   R3
#define UCALL_TMP0 R10
#define UCALL_TMP1 R11
#define UCALL_SSP  R19

#ifdef GOOS_windows

// On Windows arm64, the Go runtime uses SuspendThread + context
// injection for async preemption. If it preempts us while we're
// secretly running on g0's stack, it sees a corrupt state and hangs.
//
// We increment m.locks to disable preemption and update the TEB
// stack bounds so Windows won't fault on stack guard page checks.
//
// All runtime struct field accesses (g_m, m_locks, m_g0, etc.) go
// through the g pseudo-register, since Go's assembler only allows
// that syntax with g. We re-derive m from g after the call for the
// m.locks decrement.

#define UCALL_BODY                                          \
    /* g -> m -> m.locks++ */                               \
    MOVD    g_m(g), UCALL_TMP0                              \
    MOVW    m_locks(UCALL_TMP0), UCALL_TMP1                 \
    ADDW    $1, UCALL_TMP1                                  \
    MOVW    UCALL_TMP1, m_locks(UCALL_TMP0)                 \
    /* Save original SP */                                  \
    MOVD    RSP, UCALL_SSP                                  \
    /* Save old TEB stack bounds in callee-saved regs */    \
    MOVD    0x08(R18_PLATFORM), R20                         \
    MOVD    0x10(R18_PLATFORM), R21                         \
    /* Get g0 (m still in UCALL_TMP0) */                    \
    MOVD    m_g0(UCALL_TMP0), UCALL_TMP1                    \
    /* Write g0 stack bounds to TEB */                      \
    MOVD    (g_stack+stack_hi)(UCALL_TMP1), UCALL_TMP0      \
    MOVD    UCALL_TMP0, 0x08(R18_PLATFORM)                  \
    MOVD    (g_stack+stack_lo)(UCALL_TMP1), UCALL_TMP0      \
    MOVD    UCALL_TMP0, 0x10(R18_PLATFORM)                  \
    /* Switch to g0's scheduler stack */                    \
    MOVD    (g_sched+gobuf_sp)(UCALL_TMP1), UCALL_TMP0      \
    MOVD    UCALL_TMP0, RSP                                 \
    /* 16-byte align */                                     \
    MOVD    $15, UCALL_TMP1                                 \
    BIC     UCALL_TMP1, UCALL_TMP0, UCALL_TMP0              \
    MOVD    UCALL_TMP0, RSP                                 \
    /* Call the C function */                               \
    BL      (UCALL_FN)                                      \
    /* Restore TEB stack bounds */                          \
    MOVD    R20, 0x08(R18_PLATFORM)                         \
    MOVD    R21, 0x10(R18_PLATFORM)                         \
    /* Restore original SP */                               \
    MOVD    UCALL_SSP, RSP                                  \
    /* g -> m -> m.locks-- (re-derive m from g) */          \
    MOVD    g_m(g), UCALL_TMP0                              \
    MOVW    m_locks(UCALL_TMP0), UCALL_TMP1                 \
    SUBW    $1, UCALL_TMP1                                  \
    MOVW    UCALL_TMP1, m_locks(UCALL_TMP0)

#else

// Unix-like (Linux, macOS, BSD): straightforward g0 stack switch.

#define UCALL_BODY                                          \
    MOVD    g_m(g), UCALL_TMP0                              \
    MOVD    RSP, UCALL_SSP                                  \
    MOVD    m_g0(UCALL_TMP0), UCALL_TMP1                    \
    MOVD    (g_sched+gobuf_sp)(UCALL_TMP1), UCALL_TMP0      \
    MOVD    UCALL_TMP0, RSP                                 \
    MOVD    $15, UCALL_TMP1                                 \
    BIC     UCALL_TMP1, UCALL_TMP0, UCALL_TMP0              \
    MOVD    UCALL_TMP0, RSP                                 \
    BL      (UCALL_FN)                                      \
    MOVD    UCALL_SSP, RSP

#endif

TEXT ·UnsafeCall1(SB), NOSPLIT, $0-16
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    UCALL_BODY
    RET

TEXT ·UnsafeCall2(SB), NOSPLIT, $0-24
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    MOVD    arg1+16(FP), UCALL_A1
    UCALL_BODY
    RET

TEXT ·UnsafeCall3(SB), NOSPLIT, $0-32
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    MOVD    arg1+16(FP), UCALL_A1
    MOVD    arg2+24(FP), UCALL_A2
    UCALL_BODY
    RET

TEXT ·UnsafeCall4(SB), NOSPLIT, $0-40
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    MOVD    arg1+16(FP), UCALL_A1
    MOVD    arg2+24(FP), UCALL_A2
    MOVD    arg3+32(FP), UCALL_A3
    UCALL_BODY
    RET

TEXT ·UnsafeCall1Return1(SB), NOSPLIT, $0-24
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    UCALL_BODY
    MOVD    UCALL_RET, ret+16(FP)
    RET

TEXT ·UnsafeCall2Return1(SB), NOSPLIT, $0-32
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    MOVD    arg1+16(FP), UCALL_A1
    UCALL_BODY
    MOVD    UCALL_RET, ret+24(FP)
    RET

TEXT ·UnsafeCall3Return1(SB), NOSPLIT, $0-40
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    MOVD    arg1+16(FP), UCALL_A1
    MOVD    arg2+24(FP), UCALL_A2
    UCALL_BODY
    MOVD    UCALL_RET, ret+32(FP)
    RET

TEXT ·UnsafeCall4Return1(SB), NOSPLIT, $0-48
    MOVD    fn+0(FP), UCALL_FN
    MOVD    arg0+8(FP), UCALL_A0
    MOVD    arg1+16(FP), UCALL_A1
    MOVD    arg2+24(FP), UCALL_A2
    MOVD    arg3+32(FP), UCALL_A3
    UCALL_BODY
    MOVD    UCALL_RET, ret+40(FP)
    RET
