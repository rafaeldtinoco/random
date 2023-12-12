package main

import (
	"context"
	"fmt"
	"net"
	"log"

	"google.golang.org/grpc"

	pb "github.com/rafaeldtinoco/helloworld/helloworld"
)

type server struct {
	pb.UnimplementedGreeterServer
}

func (s *server) SayHello(ctx context.Context, in *pb.HelloRequest) (*pb.HelloReply, error) {
	message := fmt.Sprintf("Hello %s! Nice to see you!", in.GetName())
	return &pb.HelloReply {Message: message}, nil
}

func main() {
	l, err := net.Listen("tcp", ":8332")
	if err != nil {
		log.Fatal(err)
	}
	defer l.Close()

	s := grpc.NewServer()
	defer s.Stop()
	pb.RegisterGreeterServer(s, &server{})

	err = s.Serve(l)
	if err != nil {
		log.Fatal(err)
	}
}
