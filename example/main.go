package main

/*
#include <stdio.h>
int secret = 0;

int twice(int x) {
	return x * 2;
}
int add2(int a, int b) {
	return a + b;
}
int add3(int a, int b, int c) {
	return a + b + c;
}
int add4(int a, int b, int c, int d) {
	return a + b + c + d;
}

void mutate1(int a) {
	secret = twice(a);
}
void mutate2(int a, int b) {
	secret = add2(a, b);
}
void mutate3(int a, int b, int c) {
	secret = add3(a, b, c);
}
void mutate4(int a, int b, int c, int d) {
	secret = add4(a, b, c, d);
}
*/
import "C"
import (
	"fmt"

	"github.com/nitrix/fastcgo"
)

func main() {
	fastcgo.UnsafeCall1(C.mutate1, 9)
	a := C.secret
	fastcgo.UnsafeCall2(C.mutate2, 2, 3)
	b := C.secret
	fastcgo.UnsafeCall3(C.mutate3, 2, 3, 5)
	c := C.secret
	fastcgo.UnsafeCall4(C.mutate4, 2, 3, 5, 7)
	d := C.secret

	e := fastcgo.UnsafeCall1Return1(C.twice, 9)
	f := fastcgo.UnsafeCall2Return1(C.add2, 2, 3)
	g := fastcgo.UnsafeCall3Return1(C.add3, 2, 3, 5)
	h := fastcgo.UnsafeCall4Return1(C.add4, 2, 3, 5, 7)

	fmt.Println(a, b, c, d, "|", e, f, g, h)
}
