#!/bin/sh

MODEL_DIR=./models/
ROOT_DIR=$(pwd)

mkdir -p $MODEL_DIR

cd $MODEL_DIR && wget https://huggingface.co/gotzmann/LLaMA-GGML-v3/resolve/main/llama-7b-ggml-v3-q4_0.bin && cd $ROOT_DIR

cd $MODEL_DIR && wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q2_K.bin && cd $ROOT_DIR

cd $MODEL_DIR && wget https://huggingface.co/TheBloke/CodeLlama-7B-Instruct-GGUF/resolve/main/codellama-7b-instruct.Q2_K.gguf && cd $ROOT_DIR

git clone https://github.com/ggerganov/llama.cpp.git

cd llama.cpp && git checkout bcce96ba4dd95482824700c4ce2455fe8c49055a && cd ..

# We install the python3 packages required to convert the llama2 model to gguf
RUN pip install -r requirements.txt

# We convert the llama2 model from ggmlv3 to gguf
python llama.cpp/convert-llama-ggmlv3-to-gguf.py --input $MODEL_DIR/llama-2-7b-chat.ggmlv3.q2_K.bin --output $MODEL_DIR/llama-2-7b-chat.gguf.q2_K.bin
rm $MODEL_DIR/llama-2-7b-chat.ggmlv3.q2_K.bin


# We convert the llama2 model from ggmlv3 to gguf
python convert-llama-ggmlv3-to-gguf.py --input $MODEL_DIR/llama-7b-ggml-v3-q4_0.bin --output $MODEL_DIR/llama-7b.gguf.q4_0.bin
rm $MODEL_DIR/llama-7b-ggml-v3-q4_0.bin

