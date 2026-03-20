//go:build amd64

#include "go_asm.h"
#include "textflag.h"

// amd64 calling convention split:
//
//   Windows:
//     arg0..arg3 = CX, DX, R8, R9
//     return     = AX
//
//   Unix-like (Linux, macOS, BSD, etc.):
//     arg0..arg3 = DI, SI, DX, CX
//     return     = AX
//
// Common:
//   AX   = function pointer / return register
//   R13/R14 = temps
//   R12 = saved SP
//   SP  = stack pointer

#ifdef GOOS_windows
    #define UCALL_FN   AX
    #define UCALL_RET  AX
    #define UCALL_A0   CX
    #define UCALL_A1   DX
    #define UCALL_A2   R8
    #define UCALL_A3   R9
#else
    #define UCALL_FN   AX
    #define UCALL_RET  AX
    #define UCALL_A0   DI
    #define UCALL_A1   SI
    #define UCALL_A2   DX
    #define UCALL_A3   CX
#endif

#define UCALL_TMP0 R13
#define UCALL_TMP1 R14
#define UCALL_SSP  R12

#define UCALL_BODY                         \
    MOVQ    (TLS), UCALL_TMP1;             /* load g */              \
    MOVQ    g_m(UCALL_TMP1), UCALL_TMP0;   /* load g.m */            \
    MOVQ    SP, UCALL_SSP;                 /* save current SP */     \
    MOVQ    m_g0(UCALL_TMP0), UCALL_TMP1;  /* load m.g0 */           \
    MOVQ    (g_sched+gobuf_sp)(UCALL_TMP1), SP; /* g0.sched.sp */    \
    ANDQ    $~15, SP;                      /* align stack */         \
    SUBQ    $32, SP;                       /* reserve shadow */      \
    CALL    UCALL_FN;                      /* call fn */             \
    MOVQ    UCALL_SSP, SP                  /* restore SP */

TEXT ·UnsafeCall1(SB), NOSPLIT, $0-16
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    UCALL_BODY
    RET

TEXT ·UnsafeCall2(SB), NOSPLIT, $0-24
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    MOVQ    arg1+16(FP), UCALL_A1
    UCALL_BODY
    RET

TEXT ·UnsafeCall3(SB), NOSPLIT, $0-32
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    MOVQ    arg1+16(FP), UCALL_A1
    MOVQ    arg2+24(FP), UCALL_A2
    UCALL_BODY
    RET

TEXT ·UnsafeCall4(SB), NOSPLIT, $0-40
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    MOVQ    arg1+16(FP), UCALL_A1
    MOVQ    arg2+24(FP), UCALL_A2
    MOVQ    arg3+32(FP), UCALL_A3
    UCALL_BODY
    RET

TEXT ·UnsafeCall1Return1(SB), NOSPLIT, $0-24
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    UCALL_BODY
    MOVQ    UCALL_RET, ret+16(FP)
    RET

TEXT ·UnsafeCall2Return1(SB), NOSPLIT, $0-32
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    MOVQ    arg1+16(FP), UCALL_A1
    UCALL_BODY
    MOVQ    UCALL_RET, ret+24(FP)
    RET

TEXT ·UnsafeCall3Return1(SB), NOSPLIT, $0-40
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    MOVQ    arg1+16(FP), UCALL_A1
    MOVQ    arg2+24(FP), UCALL_A2
    UCALL_BODY
    MOVQ    UCALL_RET, ret+32(FP)
    RET

TEXT ·UnsafeCall4Return1(SB), NOSPLIT, $0-48
    MOVQ    fn+0(FP), UCALL_FN
    MOVQ    arg0+8(FP), UCALL_A0
    MOVQ    arg1+16(FP), UCALL_A1
    MOVQ    arg2+24(FP), UCALL_A2
    MOVQ    arg3+32(FP), UCALL_A3
    UCALL_BODY
    MOVQ    UCALL_RET, ret+40(FP)
    RET