.PHONY: all
all:

CC := clang

protob:
	protoc \
		--go_out=. \
		--go_opt=paths=source_relative \
		--go-grpc_out=. \
		--go-grpc_opt=paths=source_relative \
		./helloworld/helloworld.proto

%: ./hello-%/main.go | protob
	go build -o $@ $<

.PHONY: clean
clean:
	rm -f helloworld/*.pb.go client server
