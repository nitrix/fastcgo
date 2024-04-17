package main

/*
#include <stdio.h>
int foo = 0;
void example(int x) {
	foo = x;
}
int doubleNumber(int x) {
	return x * 2;
}
*/
import "C"
import (
	"fmt"

	"github.com/nitrix/fastcgo"
)

func main() {
	fastcgo.UnsafeCall1(C.example, 42)
	result := fastcgo.UnsafeCall1r1(C.doubleNumber, 13)
	fmt.Printf("%d %d", C.foo, result)
}
