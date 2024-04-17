package bench

// #include <stdio.h>
// void noop(void) {}
import "C"

import (
	"fmt"

	"github.com/nitrix/fastcgo"
)

var global bool

func noopGo() {
	if global {
		fmt.Println("noopGo")
	}
}

func noopCgo() {
	C.noop()
}

func noopFastCgo() {
	fastcgo.UnsafeCall1(C.noop, uintptr(0))
}
