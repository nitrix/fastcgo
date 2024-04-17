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
		t.Fail()
	}

	outputBytes, err := exec.Command(location, "run", "./example").Output()
	if err != nil {
		t.Fail()
	}

	outputStr := strings.TrimSpace(string(outputBytes))

	if outputStr != "18 5 10 17 | 18 5 10 17" {
		fmt.Println("Got:", outputStr)
		t.Fail()
	}
}
