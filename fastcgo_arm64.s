//go:build arm64

#include "go_asm.h"
#include "textflag.h"

// arm64 native ABI on Linux and Windows:
//   arg0..arg3 = R0..R3
//   return     = R0
//
// Using:
//   R4  = function pointer
//   R10/R11 = temps (caller-saved, not argument registers)
//   R19 = saved original SP (callee-saved in platform ABI, preserved across call)

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
#define UCALL_SAVE_FRAME    \
    MOVD    LR, -8(RSP);   \
    MOVD    R29, -16(RSP); \
    SUB     $16, RSP;
#define UCALL_RESTORE_FRAME \
    ADD     $16, RSP;       \
    MOVD    -8(RSP), LR;
#else
#define UCALL_SAVE_FRAME
#define UCALL_RESTORE_FRAME
#endif

#define UCALL_BODY                                     \
    MOVD    g, UCALL_TMP1                              \
    MOVD    g_m(UCALL_TMP1), UCALL_TMP0                \
    MOVD    RSP, UCALL_SSP                             \
    MOVD    m_g0(UCALL_TMP0), UCALL_TMP1               \
    MOVD    (g_sched+gobuf_sp)(UCALL_TMP1), UCALL_TMP0 \
    MOVD    UCALL_TMP0, RSP                            \
    MOVD    RSP, UCALL_TMP0                            \
    MOVD    $15, UCALL_TMP1                            \
    BIC     UCALL_TMP1, UCALL_TMP0, UCALL_TMP0         \
    MOVD    UCALL_TMP0, RSP                            \
    UCALL_SAVE_FRAME                                   \
    CALL    UCALL_FN;                                  \
    UCALL_RESTORE_FRAME                                \
    MOVD    UCALL_SSP, RSP

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
