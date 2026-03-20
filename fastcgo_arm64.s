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
//   R20 = pointer to m (callee-saved, survives the C call) [Windows only]
//   R10/R11 = temps (caller-saved, used only before BL)

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
// Incrementing m.locks before the stack switch tells the runtime
// "don't preempt this M". We save the m pointer in callee-saved
// R20 so we can decrement m.locks after the call without needing
// to re-derive it through temp registers.
//
// We also update the TEB stack bounds (StackBase at +0x08, StackLimit
// at +0x10, via R18_PLATFORM) so Windows won't fault on stack guard
// page checks when SP is on g0's stack. Old values are saved in
// callee-saved R21/R22.

#define UCALL_SAVED_M    R20
#define UCALL_SAVED_TEBB R21
#define UCALL_SAVED_TEBL R22

#define UCALL_BODY                                          \
    /* g -> m, save m in callee-saved R20 */                \
    MOVD    g_m(g), UCALL_SAVED_M                           \
    /* m.locks++ (disable preemption) */                    \
    MOVW    m_locks(UCALL_SAVED_M), UCALL_TMP1              \
    ADDW    $1, UCALL_TMP1                                  \
    MOVW    UCALL_TMP1, m_locks(UCALL_SAVED_M)              \
    /* Save original SP */                                  \
    MOVD    RSP, UCALL_SSP                                  \
    /* Save old TEB stack bounds */                         \
    MOVD    0x08(R18_PLATFORM), UCALL_SAVED_TEBB            \
    MOVD    0x10(R18_PLATFORM), UCALL_SAVED_TEBL            \
    /* Get g0 */                                            \
    MOVD    m_g0(UCALL_SAVED_M), UCALL_TMP1                 \
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
    MOVD    UCALL_SAVED_TEBB, 0x08(R18_PLATFORM)            \
    MOVD    UCALL_SAVED_TEBL, 0x10(R18_PLATFORM)            \
    /* Restore original SP */                               \
    MOVD    UCALL_SSP, RSP                                  \
    /* m.locks-- (re-enable preemption), m still in R20 */  \
    MOVW    m_locks(UCALL_SAVED_M), UCALL_TMP1              \
    SUBW    $1, UCALL_TMP1                                  \
    MOVW    UCALL_TMP1, m_locks(UCALL_SAVED_M)

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
