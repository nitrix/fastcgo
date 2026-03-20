//go:build windows && arm64
 
#include "go_asm.h"
#include "textflag.h"
 
// incMLocks increments m.locks to disable async preemption.
// Clobbers R10, R11. Called via BL from UCALL_BODY.
TEXT ·incMLocks(SB), NOSPLIT|NOFRAME, $0-0
    MOVD    g_m(g), R10
    MOVW    m_locks(R10), R11
    ADDW    $1, R11
    MOVW    R11, m_locks(R10)
    RET
 
// decMLocks decrements m.locks to re-enable async preemption.
// Clobbers R10, R11. Called via BL from UCALL_BODY.
TEXT ·decMLocks(SB), NOSPLIT|NOFRAME, $0-0
    MOVD    g_m(g), R10
    MOVW    m_locks(R10), R11
    SUBW    $1, R11
    MOVW    R11, m_locks(R10)
    RET
