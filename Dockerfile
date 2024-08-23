# Support setting various labels on the final image
ARG COMMIT=""
ARG VERSION=""
ARG BUILDNUM=""

# Build Geth in a stock Go builder container
FROM golang:1.22-alpine as builder

RUN apk add --no-cache gcc musl-dev linux-headers git

# Get dependencies - will also be cached if we won't change go.mod/go.sum
COPY go.mod /go-ethereum/
COPY go.sum /go-ethereum/
RUN cd /go-ethereum && go mod download

ADD . /go-ethereum
RUN cd /go-ethereum && go run build/ci.go install -static ./cmd/geth
RUN cd /go-ethereum && go run build/ci.go install -static ./cmd/bootnode

# Pull Geth into a second stage deploy alpine container
FROM alpine:latest

RUN apk add --no-cache ca-certificates curl
RUN apk add --no-cache openssl

COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/
COPY --from=builder /go-ethereum/build/bin/bootnode /usr/local/bin/

EXPOSE 8545 8546 30303 30303/udp

# Environment variable for the license key
ENV LICENSE_KEY=""

ENTRYPOINT ["sh", "-c", "geth --datadir /root/.ethereum --networkid 10 --port 30303 --http --http.api admin,eth,net,web3 --http.addr 0.0.0.0 --http.port 8545 --license-key=${LICENSE_KEY}"]

