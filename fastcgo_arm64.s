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
// Windows-only additional callee-saved registers:
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

// On Windows arm64, two extra things are needed beyond a simple g0 stack switch:
//
// 1. Disable async preemption by incrementing m.locks. Windows uses
//    SuspendThread + context injection for preemption. If the runtime
//    preempts us while we're secretly on g0's stack, it will see a
//    corrupt state and hang/crash. Incrementing m.locks tells the
//    runtime "don't preempt this M".
//
// 2. Update the TEB stack bounds (StackBase at +0x08, StackLimit at
//    +0x10, accessed via R18_PLATFORM). Windows validates SP against
//    these bounds for stack guard page handling. g0's stack is not
//    registered with the TEB, so we must temporarily update them.

#define UCALL_BODY                                          \
    /* g -> m (keep m in UCALL_TMP0 for later) */           \
    MOVD    g, UCALL_TMP1                                   \
    MOVD    g_m(UCALL_TMP1), UCALL_TMP0                     \
    /* m.locks++ (disable preemption) */                    \
    MOVW    m_locks(UCALL_TMP0), UCALL_TMP1                 \
    ADDW    $1, UCALL_TMP1                                  \
    MOVW    UCALL_TMP1, m_locks(UCALL_TMP0)                 \
    /* Save original SP */                                  \
    MOVD    RSP, UCALL_SSP                                  \
    /* Save old TEB stack bounds */                         \
    MOVD    0x08(R18_PLATFORM), R20                         \
    MOVD    0x10(R18_PLATFORM), R21                         \
    /* Get g0 */                                            \
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
    /* m.locks-- (re-enable preemption) */                  \
    MOVD    g, UCALL_TMP1                                   \
    MOVD    g_m(UCALL_TMP1), UCALL_TMP0                     \
    MOVW    m_locks(UCALL_TMP0), UCALL_TMP1                 \
    SUBW    $1, UCALL_TMP1                                  \
    MOVW    UCALL_TMP1, m_locks(UCALL_TMP0)

#else

// Unix-like (Linux, macOS, BSD): straightforward g0 stack switch.
// No TEB to worry about, and async preemption uses signals which
// are blocked during cgo calls by the runtime's signal mask.

#define UCALL_BODY                                          \
    MOVD    g, UCALL_TMP1                                   \
    MOVD    g_m(UCALL_TMP1), UCALL_TMP0                     \
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
