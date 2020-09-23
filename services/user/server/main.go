package main

import (
	"context"
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"

	userpb "../proto"
	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
)

// UserCRUDService is the server struct of the User gRPC microservice.
type UserCRUDService struct{}

// CreateUser is the "create" method for User CRUD in the User gRPC microservice.
func (s *UserCRUDService) CreateUser(ctx context.Context, req *userpb.CreateUserReq) (*userpb.CreateUserRes, error) {
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

	response := &userpb.CreateUserRes{
		User: &userpb.User{
			Id:       id.Hex(),
			Email:    data.Email,
			Name:     data.Name,
			UserName: data.UserName,
		},
	}

	return response, nil
}

// ReadUser is the "read" method for User CRUD in the User gRPC microservice.
func (s *UserCRUDService) ReadUser(ctx context.Context, req *userpb.ReadUserReq) (*userpb.ReadUserRes, error) {
	id, err := primitive.ObjectIDFromHex(req.GetId())
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, fmt.Sprintf("Could not convert to ObjectId: %v", err))
	}

	result := userdb.FindOne(ctx, bson.M{"_id": id})

	data := UserAccount{}

	if err := result.Decode(&data); err != nil {
		return nil, status.Errorf(codes.NotFound, fmt.Sprintf("Could not find user with Object ID %s: %v", req.GetId(), err))
	}

	response := &userpb.ReadUserRes{
		User: &userpb.User{
			Id:       id.Hex(),
			Email:    data.Email,
			Name:     data.Name,
			UserName: data.UserName,
		},
	}

	return response, nil
}

// UpdateUser is the "update" method for User CRUD in the User gRPC microservice.
func (s *UserCRUDService) UpdateUser(ctx context.Context, req *userpb.UpdateUserReq) (*userpb.UpdateUserRes, error) {
	user := req.GetUser()

	id, err := primitive.ObjectIDFromHex(user.GetId())
	if err != nil {
		return nil, status.Errorf(
			codes.InvalidArgument,
			fmt.Sprintf("Could not convert the supplied user id to a MongoDB ObjectId: %v", err),
		)
	}

	update := bson.M{
		"email":    user.GetEmail(),
		"name":     user.GetName(),
		"userName": user.GetUserName(),
		"password": user.GetPassword(),
	}

	filter := bson.M{"_id": id}

	result := userdb.FindOneAndUpdate(ctx, filter, bson.M{"$set": update}, options.FindOneAndUpdate().SetReturnDocument(1))

	decoded := UserAccount{}

	err = result.Decode(&decoded)
	if err != nil {
		return nil, status.Errorf(
			codes.NotFound,
			fmt.Sprintf("Could not find user with supplied ID: %v", err),
		)
	}

	return &userpb.UpdateUserRes{
		User: &userpb.User{
			Id:       decoded.ID.Hex(),
			Email:    decoded.Email,
			Name:     decoded.Name,
			UserName: decoded.UserName,
		},
	}, nil
}

// DeleteUser is the "delete" method for User CRUD in the User gRPC microservice.
func (s *UserCRUDService) DeleteUser(ctx context.Context, req *userpb.DeleteUserReq) (*userpb.DeleteUserRes, error) {
	id, err := primitive.ObjectIDFromHex(req.GetId())
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, fmt.Sprintf("Could not convert ObjectId: %v", err))
	}

	_, err = userdb.DeleteOne(ctx, bson.M{"_id": id})
	if err != nil {
		return nil, status.Errorf(codes.NotFound, fmt.Sprintf("Could not find/delete user with ID %s: %v", req.GetId(), err))
	}

	return &userpb.DeleteUserRes{
		Success: true,
	}, nil
}

// ListUsers is the "index" method for the User gRPC microservice.
func (s *UserCRUDService) ListUsers(req *userpb.ListUsersReq, stream userpb.UserCRUDService_ListUsersServer) error {
	data := &UserAccount{}

	cursor, err := userdb.Find(context.Background(), bson.M{})
	if err != nil {
		return status.Errorf(codes.Internal, fmt.Sprintf("Unknown internal error: %v", err))
	}

	defer cursor.Close(context.Background())

	for cursor.Next(context.Background()) {
		err := cursor.Decode(data)
		if err != nil {
			return status.Errorf(codes.Unavailable, fmt.Sprintf("Could not decode data: %v", err))
		}

		stream.Send(&userpb.ListUsersRes{
			User: &userpb.User{
				Id:       data.ID.Hex(),
				Email:    data.Email,
				Name:     data.Name,
				UserName: data.UserName,
			},
		})
	}

	if err := cursor.Err(); err != nil {
		return status.Errorf(codes.Internal, fmt.Sprintf("Unknown cursor error: %v", err))
	}

	return nil
}

// NewUserAccount is the struct used for a new User signing up. It contains hashed and salted password information.
type NewUserAccount struct {
	Email    string `bson:"email"`
	Name     string `bson:"name"`
	UserName string `bson:"userName"`
	Password string `bson:"password"`
}

// UserAccount is the struct used for registered User accounts. It does not contain password information.
type UserAccount struct {
	ID       primitive.ObjectID `bson:"_id,omitempty"`
	Email    string             `bson:"email"`
	Name     string             `bson:"name"`
	UserName string             `bson:"userName"`
}

// EditUserAccount is the struct used for an account that needs to be updated by its owner. It contains hashed and salted password information because this user is "Me" in the API.
type EditUserAccount struct {
	ID       primitive.ObjectID `bson:"_id,omitempty"`
	Email    string             `bson:"email"`
	Name     string             `bson:"name"`
	UserName string             `bson:"userName"`
	Password string             `bson:"password"`
}

var db *mongo.Client
var userdb *mongo.Collection
var mongoCtx context.Context

func main() {
	log.SetFlags(log.LstdFlags | log.Lshortfile)

	// Use the default port for a gRPC microservice (50051).
	servicePort := 50051

	// Use the preferred IP of 0.0.0.0 rather than "localhost".
	serviceIP := "0.0.0.0"

	// Use the default port for MongoDB.
	mongoPort := 27017

	fmt.Printf("Starting server on port :%d...", servicePort)

	listenPort := fmt.Sprintf(":%d", servicePort)

	listener, err := net.Listen("tcp", listenPort)
	if err != nil {
		log.Fatalf("Unable to listen on port %d: %v", servicePort, err)
	}

	opts := []grpc.ServerOption{}

	s := grpc.NewServer(opts...)

	srv := &userpb.UserCRUDService{}

	userpb.RegisterUserCRUDService(s, srv)

	fmt.Println("Connecting to MongoDB...")

	mongoCtx = context.Background()

	mongoURI := fmt.Sprintf("mongodb://%s:%d", serviceIP, mongoPort)

	db, err = mongo.Connect(mongoCtx, options.Client().ApplyURI(mongoURI))
	if err != nil {
		log.Fatal(err)
	}
	err = db.Ping(mongoCtx, nil)
	if err != nil {
		log.Fatalf("Could not connect to MongoDB:\n%v\n", err)
	} else {
		fmt.Println("Connected to MongoDB!")
	}

	userdb = db.Database("theSupertask").Collection("users")

	go func() {
		if err := s.Serve(listener); err != nil {
			log.Fatalf("Failed to serve: %v", err)
		}
	}()
	successMsg := fmt.Sprintf("Server successfully started on port :%d", servicePort)
	fmt.Println(successMsg)

	c := make(chan os.Signal)

	signal.Notify(c, os.Interrupt)

	<-c

	fmt.Println("\nStopping the server...")
	s.Stop()
	listener.Close()
	fmt.Println("Closing MongoDB connection...")
	db.Disconnect(mongoCtx)
	fmt.Println("Done.")
}
