package main

import (
	"context"
	"fmt"

	userpb "github.com/allen-woods/the-supertask/services/user/proto"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// The server struct of the User gRPC microservice.
type UserServiceServer struct{}

// The create method for User CRUD in the User gRPC microservice.
func (s *UserServiceServer) CreateUser(ctx context.Context, req *userpb.CreateUserReq) (*userpb.CreateUserRes, error) {
	user := req.GetUser()

	data := NewUserAccount{
		Email:    user.GetEmail(),
		Name:     user.GetName(),
		UserName: user.GetUserName(),
		Password: user.GetPassword(),
	}

	result, err := userdb.InsertOne(mongoCtx, data)
	if err != nil {
		return nil, status.Errorf(
			codes.Internal,
			fmt.Sprintf("Internal error: %v", err),
		)
	}

	id := result.InsertedID.(primitive.ObjectID)

	user.Id = id.Hex()

	return &userpb.CreateUserRes{NewUser: user}, nil
}
