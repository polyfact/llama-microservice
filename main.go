package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
)

type Model struct {
	Binary string
	Model  string
}

var modelsMap = map[string]Model{
	"llama": {
		Binary: os.Getenv("LLAMA_BIN"),
		Model:  os.Getenv("LLAMA_MODEL"),
	},
	"llama2": {
		Binary: os.Getenv("LLAMA2_BIN"),
		Model:  os.Getenv("LLAMA2_MODEL"),
	},
}

type RequestBody struct {
	Prompt      string   `json:"prompt"`
	Model       *string  `json:"model"`
	Temperature *float64 `json:"temperature"`
}

func generate(w http.ResponseWriter, r *http.Request) {
	var input RequestBody

	err := json.NewDecoder(r.Body).Decode(&input)
	if err != nil {
		http.Error(w, "400 Bad Request", http.StatusBadRequest)
	}

	model := "llama"

	if input.Model != nil {
		model = *input.Model
	}

	options, found := modelsMap[model]
	if !found {
		http.Error(w, "404 Unknown Model", http.StatusNotFound)
	}

	temp := 0.8
	if input.Temperature != nil {
		temp = *input.Temperature
	}

	ctx := context.Background()
	cmd := exec.CommandContext(
		ctx,
		options.Binary,
		"-m",
		options.Model,
		"--temp",
		fmt.Sprintf("%.6f", temp),
		"-p",
		input.Prompt,
	)
	reader, err := cmd.StdoutPipe()
	if err != nil {
		http.Error(w, "500 Internal Server Error", http.StatusInternalServerError)
		return
	}
	if err := cmd.Start(); err != nil {
		http.Error(w, "500 Internal Server Error", http.StatusInternalServerError)
		return
	}
	to_skip := len(input.Prompt) + 1
	var p []byte = make([]byte, 128)
	for {
		nb, err := reader.Read(p)
		if errors.Is(err, io.EOF) || err != nil {
			break
		}
		if to_skip < nb {
			start := 0
			if to_skip > 0 {
				start = to_skip
			}
			w.Write(p[start:nb])
			if f, ok := w.(http.Flusher); ok {
				f.Flush()
			}
		}
		to_skip -= nb
	}
}

func main() {
	http.HandleFunc("/", generate)

	fmt.Println("Started on port 8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
