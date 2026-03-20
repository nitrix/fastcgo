package fastcgo_test

import (
	"fmt"
	"os/exec"
	"strings"
	"testing"
)

func TestExample(t *testing.T) {
	location, err := exec.LookPath("go")
	if err != nil {
		fmt.Println("Error1:", err)
		t.Fail()
	}

	cmd := exec.Command(location, "run", "./example")
	outputBytes, err := cmd.CombinedOutput()
	if err != nil {
		fmt.Println("Error2:", err)
		t.Fail()
	}

	outputStr := strings.TrimSpace(string(outputBytes))

	if outputStr != "18 5 10 17 | 18 5 10 17" {
		fmt.Println("Got:", outputStr)
		t.Fail()
	}
}
