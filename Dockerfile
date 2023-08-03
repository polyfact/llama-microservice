FROM alpine:3

# The first thing we do is download the llama model (for cache reason, given it's ~4GB we don't want to redownload it every time we build)
RUN apk add wget

WORKDIR /tmp/

RUN wget https://huggingface.co/Pi3141/alpaca-native-7B-ggml/resolve/397e872bf4c83f4c642317a5bf65ce84a105786e/ggml-model-q4_0.bin

# We then install git and the package required to build llama and the go app
RUN apk add go make git g++

RUN git clone https://github.com/ggerganov/llama.cpp.git

WORKDIR /tmp/llama.cpp

# We use an older version which support the model we downloaded
RUN git checkout e7f6997f897a18b6372a6460e25c5f89e1469f1d

# We build llama
RUN make -j

# We set the env variables related to llama
ENV LLAMA_BIN /tmp/llama.cpp/main
ENV LLAMA_MODEL /tmp/ggml-model-q4_0.bin

# And we finally build the app
WORKDIR /go/src/github.com/polyfact/llama-microservice

COPY . /go/src/github.com/polyfact/llama-microservice/

RUN go get

RUN mkdir -p build

RUN go build -o build/server_start main.go

ENTRYPOINT /go/src/github.com/polyfact/llama-microservice/build/server_start
