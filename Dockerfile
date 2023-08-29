FROM alpine:3

RUN apt update

# The first thing we do is download the llama models (for cache reason, given it's ~4GB we don't want to redownload it every time we build)
RUN apt-get install -y wget

WORKDIR /tmp/

ENV CODELLAMA_MODEL /var/models/codellama-7b-instruct.Q2_K.gguf

ENV LLAMA2_MODEL /var/models/llama-2-7b-chat.gguf.q2_K.bin

ENV LLAMA_MODEL /var/models/llama-7b.gguf.q4_0.bin

# We then install git and the package required to build llama and the go app
RUN apt-get install -y golang make git g++

# We make 2 llama.cpp directories (one will be used with an older version for alpaca compatibility and the other with llama 2)
RUN git clone https://github.com/ggerganov/llama.cpp.git

WORKDIR /tmp/llama.cpp

# We use a version which support the llama2 model we downloaded
RUN git checkout bcce96ba4dd95482824700c4ce2455fe8c49055a

# We build llama
RUN make -j

# We set the env variables related to llama
ENV LLAMA_BIN /tmp/llama.cpp/main

# And we finally build the app
WORKDIR /go/src/github.com/polyfact/llama-microservice

COPY . /go/src/github.com/polyfact/llama-microservice/

RUN go get

RUN mkdir -p build

RUN go build -o build/server_start main.go

CMD ["sh", "-c", "cd /tmp/llama.cpp && make clean && make -j && /go/src/github.com/polyfact/llama-microservice/build/server_start"]
