package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/allen-woods/the-supertask/api/auth"
	"github.com/allen-woods/the-supertask/api/graph/generated"
	"github.com/allen-woods/the-supertask/api/graph/model"
	pb "github.com/allen-woods/the-supertask/services/user/proto"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"google.golang.org/grpc"
)

const (
	userServiceIP   = "0.0.0.0"
	userServicePort = 50051
)

var userServiceAddress string = fmt.Sprintf("%s:%d", userServiceIP, userServicePort)

func (r *mutationResolver) SignUpUser(ctx context.Context, input *model.NewUser) (*model.User, error) {
	// Resolver not authenticated to allow sign up.

	// Hash and salt the password first using authentication middleware.
	securePassword, err := auth.HashAndSalt(input.Password)
	if err != nil {
		log.Fatal("Failed to hash and salt password.")
	}

	// Dial the gRPC server dedicated to the User model.
	conn, err := grpc.Dial(userServiceAddress, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatal("did not connect: %v", err)
	}
	defer conn.Close()

	// Create a client for talking to the server we just dialed.
	c := pb.NewUserServiceClient(conn)

	ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	defer cancel()

	// Request to create the User, given the fields of "input" in our ctx.
	res, err := c.CreateUser(
		ctx,
		&pb.CreateUserReq{
			User: &pb.NewUser{
				Email:    input.Email,
				Name:     input.Name,
				UserName: input.UserName,
				Password: securePassword,
			},
		},
	)
	if err != nil {
		log.Fatal("Failed to create User over gRPC.")
	}

	// Parse the User from our response "res".
	createdUser := res.GetUser()

	// Sanitize our ObjectID value to make sure it's legitimate.
	idToInsert, err := primitive.ObjectIDFromHex(createdUser.Id)
	if err != nil {
		log.Fatalf("Corrupted ObjectID: %v", err)
	}

	// Build a valid User return value with an ommitted "password" field.
	u := &model.User{
		ID:       idToInsert,
		Email:    createdUser.Email,
		Name:     createdUser.Name,
		UserName: createdUser.UserName,
	}

	// Pass the verified ObjectID as hex into authentication middleware.
	auth.InsertUserID(u.ID.Hex())

	return u, nil
}

func (r *mutationResolver) LogInUser(ctx context.Context, email string, password string) (*model.User, error) {
	// Not authenticated to allow for login.
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) LogOutUser(ctx context.Context) (bool, error) {
	// Must be authenticated.
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) DeleteUser(ctx context.Context, id primitive.ObjectID, confirmDelete bool) (bool, error) {
	// Must be authenticated.
	panic(fmt.Errorf("not implemented"))
}

func (r *queryResolver) Me(ctx context.Context) (*model.User, error) {
	// Must be authenticated.
	panic(fmt.Errorf("not implemented"))
}

func (r *queryResolver) Users(ctx context.Context) ([]*model.User, error) {
	// Must be authenticated.
	panic(fmt.Errorf("not implemented"))
}

// Mutation returns generated.MutationResolver implementation.
func (r *Resolver) Mutation() generated.MutationResolver { return &mutationResolver{r} }

// Query returns generated.QueryResolver implementation.
func (r *Resolver) Query() generated.QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
