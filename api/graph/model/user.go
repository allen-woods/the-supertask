package model

import (
	"go.mongodb.org/mongo-driver/bson/primitive"
)

type NewUser struct {
	Email    string
	Name     string
	UserName string
	Password string
}

type User struct {
	ID       primitive.ObjectID `bson:"_id,omitempty"`
	Email    string
	Name     string
	UserName string
	Password string
}
