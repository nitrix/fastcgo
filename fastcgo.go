package fastcgo

import "unsafe"

// These directly call a C function from Go by temporarily hijacking the goroutine's stack.
// DO NOT USE unless you know what you're doing.

func UnsafeCall1(fn unsafe.Pointer, arg0 uintptr)
func UnsafeCall2(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr)
func UnsafeCall3(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr)
func UnsafeCall4(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr, arg3 uintptr)

func UnsafeCall1Return1(fn unsafe.Pointer, arg0 uintptr) uintptr
func UnsafeCall2Return1(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr) uintptr
func UnsafeCall3Return1(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr) uintptr
func UnsafeCall4Return1(fn unsafe.Pointer, arg0 uintptr, arg1 uintptr, arg2 uintptr, arg3 uintptr) uintptr
