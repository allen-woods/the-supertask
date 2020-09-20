package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.

import (
	"context"
	"fmt"
	"log"

	graph_gen "github.com/allen-woods/the-supertask/api/graph/generated"
	graph_model "github.com/allen-woods/the-supertask/api/graph/model"
	"go.mongodb.org/mongo-driver/bson/primitive"
	"google.golang.org/grpc"
)

func (r *mutationResolver) SignUpUser(ctx context.Context, input *graph_model.NewUser) (*graph_model.User, error) {
	// Not authenticated to allow sign up.

	// Define any user data to be sent over gRPC.

	// Dial the gRPC server for the User model.
	conn, err := grpc.Dial(address, grpc.WithInsecure(), grpc.WithBlock())
	if err != nil {
		log.Fatal("did not connect: %v", err)
	}
	defer conn.Close()

	// c := pb.NewSignUpClient
	// ctx, cancel := context.WithTimeout(context.Background(), time.Second)
	// defer cancel()

	// Send the data
	// r, err := c.SayHello(ctx, &pb.HelloRequest{Name: name})
	// if err != nil {
	// 	log.Fatalf("could not sign up: %v", err)
	// }

	// Process any results returned by the gRPC server.
	// log.Printf("Signed up: %s", r.GetMessage())
}

func (r *mutationResolver) LogInUser(ctx context.Context, email string, password string) (*graph_model.User, error) {
	// Not authenticated to allow login.
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) LogOutUser(ctx context.Context) (bool, error) {
	// Fails if not authenticated.
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) DeleteUser(ctx context.Context, id primitive.ObjectID, confirmDelete bool) (bool, error) {
	// Fails if not authenticated.
	panic(fmt.Errorf("not implemented"))
}

func (r *queryResolver) Me(ctx context.Context) (*graph_model.User, error) {
	// Fails if not authenticated.
	panic(fmt.Errorf("not implemented"))
}

func (r *queryResolver) Users(ctx context.Context) ([]*graph_model.User, error) {
	// Fails if not authenticated.
	panic(fmt.Errorf("not implemented"))
}

// Mutation returns graph_gen.MutationResolver implementation.
func (r *Resolver) Mutation() graph_gen.MutationResolver { return &mutationResolver{r} }

// Query returns graph_gen.QueryResolver implementation.
func (r *Resolver) Query() graph_gen.QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
