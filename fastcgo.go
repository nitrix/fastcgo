package fastcgo

import "unsafe"

// Directly calls a C function from Go by temporarily replacing the stack.
// This does not collaborates with Cgo not the GC. Use sparingly.
func UnsafeCall1(fn unsafe.Pointer, arg0 uintptr)
func UnsafeCall2(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr)
func UnsafeCall3(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr)
func UnsafeCall4(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr, arg3 uintptr)

func UnsafeCall1Return1(fn unsafe.Pointer, arg0 uintptr) uintptr
func UnsafeCall2Return1(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr) uintptr
func UnsafeCall3Return1(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr) uintptr
func UnsafeCall4Return1(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr, arg3 uintptr) uintptr
