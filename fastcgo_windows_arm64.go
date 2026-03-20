//go:build windows && arm64

package fastcgo

import (
	"syscall"
	"unsafe"
)

func UnsafeCall1(fn unsafe.Pointer, arg0 uintptr) {
	syscall.SyscallN(uintptr(fn), arg0)
}

func UnsafeCall2(fn unsafe.Pointer, arg0, arg1 uintptr) {
	syscall.SyscallN(uintptr(fn), arg0, arg1)
}

func UnsafeCall3(fn unsafe.Pointer, arg0, arg1, arg2 uintptr) {
	syscall.SyscallN(uintptr(fn), arg0, arg1, arg2)
}

func UnsafeCall4(fn unsafe.Pointer, arg0, arg1, arg2, arg3 uintptr) {
	syscall.SyscallN(uintptr(fn), arg0, arg1, arg2, arg3)
}

func UnsafeCall1Return1(fn unsafe.Pointer, arg0 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(uintptr(fn), arg0)
	return r
}

func UnsafeCall2Return1(fn unsafe.Pointer, arg0, arg1 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(uintptr(fn), arg0, arg1)
	return r
}

func UnsafeCall3Return1(fn unsafe.Pointer, arg0, arg1, arg2 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(uintptr(fn), arg0, arg1, arg2)
	return r
}

func UnsafeCall4Return1(fn unsafe.Pointer, arg0, arg1, arg2, arg3 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(uintptr(fn), arg0, arg1, arg2, arg3)
	return r
}
