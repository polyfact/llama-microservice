package main

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"os"
	"os/exec"
)

var (
	LLAMA_BIN   = os.Getenv("LLAMA_BIN")
	LLAMA_MODEL = os.Getenv("LLAMA_MODEL")
)

type RequestBody struct {
	Prompt string `json:"prompt"`
}

func generate(w http.ResponseWriter, r *http.Request) {
	var input RequestBody

	err := json.NewDecoder(r.Body).Decode(&input)
	if err != nil {
		http.Error(w, "400 Bad Request", http.StatusBadRequest)
	}

	ctx := context.Background()
	cmd := exec.CommandContext(ctx, LLAMA_BIN, "-m", LLAMA_MODEL, "-p", input.Prompt)
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

	log.Fatal(http.ListenAndServe(":8080", nil))
}
