package model

import (
	"errors"
	"io"
	"log"
	"strconv"

	graphql "github.com/99designs/gqlgen/graphql"
	primitive "go.mongodb.org/mongo-driver/bson/primitive"
)

func MarshalID(id primitive.ObjectID) graphql.Marshaler {
	return graphql.WriterFunc(func(w io.Writer) {
		json, err := id.MarshalJSON()

		if err != nil {
			log.Fatal("Error:", err)
		}

		io.WriteString(w, strconv.Quote(string(json)))
	})
}

func UnmarshalID(v interface{}) (primitive.ObjectID, error) {
	var id primitive.ObjectID

	json, ok := v.(string)
	if !ok {
		// Return the zero value of ObjectID (empty)
		return id, errors.New("ids must be strings")
	}

	err := id.UnmarshalJSON([]byte(strconv.Quote(json)))
	if err != nil {
		// Return the zero value of ObjectID (empty)
		return id, errors.New("ids must be valid JSON")
	}

	return id, nil
}
