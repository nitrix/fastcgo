package fastcgo

import "unsafe"

// Directly calls a C function from Go by temporarily replacing the stack.
// This does not collaborates with Cgo not the GC. Use sparingly.
func UnsafeCall1(fn unsafe.Pointer, arg0 uintptr)

func UnsafeCall1r1(fn unsafe.Pointer, arg0 uintptr) uintptr
