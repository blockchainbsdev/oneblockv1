# Build Geth in a stock Go builder container
FROM golang:1.22-alpine as builder

# Install necessary packages for building
RUN apk add --no-cache gcc musl-dev linux-headers git

# Set up working directory
WORKDIR /go-ethereum

# Get dependencies
COPY go.mod go.sum ./
RUN go mod download

# Copy the source code and build
COPY . .
RUN go run build/ci.go install -static ./cmd/geth
RUN go run build/ci.go install -static ./cmd/bootnode

# Pull Geth into a second stage deploy alpine container
FROM alpine:latest

# Install runtime dependencies
RUN apk add --no-cache ca-certificates curl openssl

# Copy the Geth binaries from the builder stage
COPY --from=builder /go-ethereum/build/bin/geth /usr/local/bin/
COPY --from=builder /go-ethereum/build/bin/bootnode /usr/local/bin/

# Copy configuration files
COPY datadir/static-nodes.json /root/.ethereum/static-nodes.json
COPY datadir/permission-config.json /root/.ethereum/permission-config.json

# Expose necessary ports
EXPOSE 8545 8546 30303 30303/udp

# Set environment variables for dynamic configuration
ENV NETWORK_ID=10
ENV HTTP_PORT=8545
ENV PORT=30303
ENV RAFT=true

# Default entry point for the container
ENTRYPOINT ["sh", "-c", "geth --datadir /root/.ethereum --networkid $NETWORK_ID --port $PORT --http --http.api admin,eth,net,web3 --http.addr 0.0.0.0 --http.port $HTTP_PORT --syncmode 'full' --raft=$RAFT"]







