package graph

// This file will be automatically regenerated based on the schema, any resolver implementations
// will be copied through when generating and any unknown code will be moved to the end.

import (
	"context"
	"fmt"

	generated1 "github.com/allen-woods/the-supertask/api/graph/generated"
	model1 "github.com/allen-woods/the-supertask/api/graph/model"
	"go.mongodb.org/mongo-driver/bson/primitive"
)

func (r *mutationResolver) SignUpUser(ctx context.Context, input *model1.NewUser) (*model1.User, error) {
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) LogInUser(ctx context.Context, email string, password string) (*model1.User, error) {
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) LogOutUser(ctx context.Context) (bool, error) {
	panic(fmt.Errorf("not implemented"))
}

func (r *mutationResolver) DeleteUser(ctx context.Context, id primitive.ObjectID, confirmDelete bool) (bool, error) {
	panic(fmt.Errorf("not implemented"))
}

func (r *queryResolver) Me(ctx context.Context) (*model1.User, error) {
	panic(fmt.Errorf("not implemented"))
}

func (r *queryResolver) Users(ctx context.Context) ([]*model1.User, error) {
	panic(fmt.Errorf("not implemented"))
}

// Mutation returns generated1.MutationResolver implementation.
func (r *Resolver) Mutation() generated1.MutationResolver { return &mutationResolver{r} }

// Query returns generated1.QueryResolver implementation.
func (r *Resolver) Query() generated1.QueryResolver { return &queryResolver{r} }

type mutationResolver struct{ *Resolver }
type queryResolver struct{ *Resolver }
