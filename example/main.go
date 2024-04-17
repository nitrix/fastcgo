package main

/*
#include <stdio.h>
void example(int x) {
	printf("Hello %d", x);
}
*/
import "C"
import "github.com/nitrix/fastcgo"

func main() {
	fastcgo.UnsafeCall1(C.example, 42)
}
