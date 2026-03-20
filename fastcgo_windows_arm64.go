//go:build windows && arm64

package fastcgo

import "syscall"

func UnsafeCall1(fn uintptr, arg0 uintptr) {
	syscall.SyscallN(fn, arg0)
}

func UnsafeCall2(fn uintptr, arg0, arg1 uintptr) {
	syscall.SyscallN(fn, arg0, arg1)
}

func UnsafeCall3(fn uintptr, arg0, arg1, arg2 uintptr) {
	syscall.SyscallN(fn, arg0, arg1, arg2)
}

func UnsafeCall4(fn uintptr, arg0, arg1, arg2, arg3 uintptr) {
	syscall.SyscallN(fn, arg0, arg1, arg2, arg3)
}

func UnsafeCall1Return1(fn uintptr, arg0 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(fn, arg0)
	return r
}

func UnsafeCall2Return1(fn uintptr, arg0, arg1 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(fn, arg0, arg1)
	return r
}

func UnsafeCall3Return1(fn uintptr, arg0, arg1, arg2 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(fn, arg0, arg1, arg2)
	return r
}

func UnsafeCall4Return1(fn uintptr, arg0, arg1, arg2, arg3 uintptr) uintptr {
	r, _, _ := syscall.SyscallN(fn, arg0, arg1, arg2, arg3)
	return r
}
