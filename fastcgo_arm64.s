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
//   R10/R11 = temps (caller-saved, used only before CALL)
//
// Windows-only additional registers:
//   R20 = saved TEB StackBase (callee-saved)
//   R21 = saved TEB StackLimit (callee-saved)

#define UCALL_FN   R4
#define UCALL_RET  R0
#define UCALL_A0   R0
#define UCALL_A1   R1
#define UCALL_A2   R2
#define UCALL_A3   R3
#define UCALL_TMP0 R10
#define UCALL_TMP1 R11
#define UCALL_SSP  R19

// TEB offsets (NT_TIB at start of TEB, 64-bit layout):
//   +0x008 = StackBase  (high address)
//   +0x010 = StackLimit (low address)
// On Windows arm64, R18 (R18_PLATFORM) points to the TEB.

#ifdef GOOS_windows

// On Windows arm64, the kernel validates stack pointers against the
// TEB's StackBase/StackLimit fields. When we switch RSP to g0's
// scheduler stack, we must update these TEB fields to match g0's
// stack bounds, or Windows will fault/hang on stack guard page checks.
//
// Steps:
//   1. g -> m -> g0
//   2. Save original SP
//   3. Save old TEB StackBase/StackLimit into R20/R21
//   4. Write g0's stack bounds into TEB
//   5. Switch RSP to g0's scheduler stack, 16-byte align
//   6. BL to function
//   7. Restore TEB StackBase/StackLimit from R20/R21
//   8. Restore original SP

#define UCALL_BODY                                          \
    MOVD    g, UCALL_TMP1                                   \
    MOVD    g_m(UCALL_TMP1), UCALL_TMP0                     \
    MOVD    RSP, UCALL_SSP                                  \
    /* Save old TEB stack bounds */                         \
    MOVD    0x08(R18_PLATFORM), R20                         \
    MOVD    0x10(R18_PLATFORM), R21                         \
    /* Get g0 */                                            \
    MOVD    m_g0(UCALL_TMP0), UCALL_TMP1                    \
    /* Write g0's stack bounds to TEB */                    \
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
    BL      (UCALL_FN)                                      \
    /* Restore TEB stack bounds */                          \
    MOVD    R20, 0x08(R18_PLATFORM)                         \
    MOVD    R21, 0x10(R18_PLATFORM)                         \
    MOVD    UCALL_SSP, RSP

#else

// Unix-like (Linux, macOS, BSD): straightforward g0 stack switch.
// No TEB to worry about.

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
