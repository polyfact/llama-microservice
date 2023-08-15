FROM alpine:3

# The first thing we do is download the llama models (for cache reason, given it's ~4GB we don't want to redownload it every time we build)
RUN apk add wget

WORKDIR /tmp/

RUN wget https://huggingface.co/Pi3141/alpaca-native-7B-ggml/resolve/397e872bf4c83f4c642317a5bf65ce84a105786e/ggml-model-q4_0.bin

ENV LLAMA_MODEL /tmp/ggml-model-q4_0.bin

RUN wget https://huggingface.co/TheBloke/Llama-2-7B-Chat-GGML/resolve/main/llama-2-7b-chat.ggmlv3.q2_K.bin

ENV LLAMA2_MODEL /tmp/llama-2-7b-chat.ggmlv3.q2_K.bin

# We then install git and the package required to build llama and the go app
RUN apk add go make git g++

# We make 2 llama.cpp directories (one will be used with an older version for alpaca compatibility and the other with llama 2)
RUN git clone https://github.com/ggerganov/llama.cpp.git
RUN cp -r llama.cpp llama2.cpp

WORKDIR /tmp/llama.cpp

# We use an older version which support the alpaca model we downloaded
RUN git checkout e7f6997f897a18b6372a6460e25c5f89e1469f1d

# We build llama
RUN make -j

# We set the env variables related to llama
ENV LLAMA_BIN /tmp/llama.cpp/main

WORKDIR /tmp/llama2.cpp

# We use a version which support the llama2 model we downloaded
RUN git checkout b5ffb2849d23afe73647f68eec7b68187af09be6

# We build llama
RUN make -j

# We set the env variables related to llama
ENV LLAMA2_BIN /tmp/llama2.cpp/main

# And we finally build the app
WORKDIR /go/src/github.com/polyfact/llama-microservice

COPY . /go/src/github.com/polyfact/llama-microservice/

RUN go get

RUN mkdir -p build

RUN go build -o build/server_start main.go

CMD ["sh", "-c", "cd /tmp/llama.cpp && make clean && make -j && cd /tmp/llama2.cpp && make clean && make -j && /go/src/github.com/polyfact/llama-microservice/build/server_start"]
