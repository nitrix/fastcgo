// +build amd64 arm64

#include "go_asm.h"
#include "textflag.h"

// Registers N_A0 through N_A3 are for arguments.
// Registers N_T0 through N_T1 are for temporaries.
// Register N_LC is location for the function call.
// Register N_LR is location for the return value.
// Register N_SP is for the stack pointer.
// Register N_C0 is callee-saved.

// ======================================
//               REGISTERS
// ======================================

#ifdef GOOS_windows
	#define N_LC AX
	#define N_LR AX
	#define N_A0 CX
	#define N_A1 DX
	#define N_A2 R8
	#define N_A3 R9
	#define N_T0 R13
	#define N_T1 R14
	#define N_C0 R12
	#define N_SP SP
#else
	#ifdef GOARCH_arm64
		#define N_LC R4
		#define N_LR R0
		#define N_A0 R0
		#define N_A1 R1
		#define N_A2 R2
		#define N_A3 R3
		#define N_T0 R8
		#define N_T1 R9
		#define N_C0 R12
		#define N_SP R13
	#else
		#define N_LC AX
		#define N_LR AX
		#define N_A0 DI
		#define N_A1 SI
		#define N_A2 DX
		#define N_A3 CX
		#define N_T0 R13
		#define N_T1 R14
		#define N_C0 R12
		#define N_SP SP
	#endif
#endif

// ======================================
//              INSTRUCTIONS
// ======================================

#ifdef GOARCH_arm64
	#define N_MOV MOVD
	#define N_AND AND
	#define N_GVAR g
#else
	#define N_MOV MOVQ
	#define N_AND ANDQ
	#define N_GVAR (TLS)
#endif

// ======================================
//              FUNCTIONS
// ======================================

#define N_SAVE                           \
	N_MOV fn+0(FP), N_LC                 \ // Save the first argument as the function to call
	N_MOV arg0+8(FP), N_A0                 // Save the second argument

#define N_BODY                           \
	N_MOV N_GVAR, N_T1                   \ // Load g
	N_MOV g_m(N_T1), N_T0                \ // Load g.m
	N_MOV N_SP, N_C0                     \ // Save SP in a callee-saved register
	N_MOV m_g0(N_T0), N_T1               \ // Load m.go
	N_MOV (g_sched+gobuf_sp)(N_T1), N_SP \ // Load g0.sched.sp
	N_AND $~15, N_SP                     \ // Align the stack to 16-bytes
	CALL N_LC                            \ // Call the saved function
	N_MOV N_C0, N_SP                       // Restore SP

// Change the stack pointer to g0's stack and calls the first argument with the second argument.
TEXT ·UnsafeCall1(SB), NOSPLIT, $0-0
	N_SAVE
	N_BODY
	RET

TEXT ·UnsafeCall1r1(SB), NOSPLIT, $0-0
	N_SAVE
	N_BODY
	N_MOV N_LR, ret+16(FP)  // Place the return value on the stack
	RET
