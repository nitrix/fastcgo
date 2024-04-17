package fastcgo_test

import (
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

	if outputStr != "42 26" {
		t.Fail()
	}
}
