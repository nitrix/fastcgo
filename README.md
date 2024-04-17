# fastcgo

Fast (but unsafe) Cgo calls via an assembly trampoline. 

It executes C on the "system stack" of the current thread running the current goroutine where it's invoked on. This completely makes the thread unsuitable for other purposes and doesn't play nice with the scheduler not the GC.

## Supported

* OSes: `Windows`, `Linux` and `MacOS`.
* Architechtures: `x86_64` and `ARM64`.

## Why?

Few reasons:

* Workaround for a [scheduling issue](https://dqlite.io/docs/explanation/faq#why-c-7) when the call lasts longer than 20 microseconds which is causing me visible stutter when calling [glfwSwapBuffers()](https://github.com/go-gl/glfw) with VSync enabled.
* Bring down the [Cgo overhead](https://github.com/golang/go/issues/19574) from 50ns to 3ns (see below).
* May unblock [others]() running into similar problems. 

## Benchmark

With `go test -run=- -bench=. ./bench`:

```
cpu: Intel(R) Core(TM) i7-7700K CPU @ 4.20GHz
BenchmarkGO-8           1000000000               0.4139 ns/op
BenchmarkCGO-8          23076256                 51.72 ns/op
BenchmarkFastCGO-8      414632949                2.885 ns/op
```

## Example


```go
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
```

Also found [there](`example/main.go`) just in case.

## License

This is free and unencumbered software released into the public domain. See the [UNLICENSE](UNLICENSE) file for more details.