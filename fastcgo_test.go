package fastcgo_test

import (
	"bytes"
	"fmt"
	"os"
	"os/exec"
	"testing"
)

func TestExample(t *testing.T) {
	buffer := bytes.Buffer{}

	location, err := exec.LookPath("go")
	if err != nil {
		t.Fail()
	}

	cmd := exec.Cmd{}
	cmd.Path = location
	cmd.Args = []string{location, "run", "./example"}
	cmd.Stdout = &buffer
	cmd.Stderr = os.Stderr
	err = cmd.Run()
	if err != nil {
		t.Fail()
	}

	output := buffer.String()

	if output != "Hello 42" {
		fmt.Fprintln(os.Stderr, output)
		t.Fail()
	}
}
