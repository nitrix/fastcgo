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

#define UCALL_FN   R4
#define UCALL_RET  R0
#define UCALL_A0   R0
#define UCALL_A1   R1
#define UCALL_A2   R2
#define UCALL_A3   R3
#define UCALL_TMP0 R10
#define UCALL_TMP1 R11
#define UCALL_SSP  R19

// On Windows arm64, switching to g0's stack causes hangs because the
// Windows kernel validates stack pointers against the TEB (Thread
// Environment Block) stack bounds. g0's stack is not registered with
// the TEB, so touching it can trigger a stack guard page fault that
// the OS turns into an access violation or silent hang.
//
// Instead, on Windows we stay on the current goroutine stack, just
// save SP, align to 16 bytes, call, and restore. This is safe for
// small/fast C functions (which is the entire point of fastcgo).
//
// On Unix-like systems (Linux, macOS, BSD) we do the full g0 stack
// switch, matching the amd64 behavior.

#ifdef GOOS_windows
#define UCALL_BODY                                     \
    MOVD    RSP, UCALL_SSP                             \
    MOVD    RSP, UCALL_TMP0                            \
    MOVD    $15, UCALL_TMP1                            \
    BIC     UCALL_TMP1, UCALL_TMP0, UCALL_TMP0         \
    SUB     $16, UCALL_TMP0, UCALL_TMP0                \
    MOVD    UCALL_TMP0, RSP                            \
    BL      (UCALL_FN)                                 \
    MOVD    UCALL_SSP, RSP
#else
#define UCALL_BODY                                     \
    MOVD    g, UCALL_TMP1                              \
    MOVD    g_m(UCALL_TMP1), UCALL_TMP0                \
    MOVD    RSP, UCALL_SSP                             \
    MOVD    m_g0(UCALL_TMP0), UCALL_TMP1               \
    MOVD    (g_sched+gobuf_sp)(UCALL_TMP1), UCALL_TMP0 \
    MOVD    UCALL_TMP0, RSP                            \
    MOVD    $15, UCALL_TMP1                            \
    BIC     UCALL_TMP1, UCALL_TMP0, UCALL_TMP0         \
    MOVD    UCALL_TMP0, RSP                            \
    BL      (UCALL_FN)                                 \
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