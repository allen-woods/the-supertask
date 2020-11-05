package main

import (
	"log"

	"github.com/alexedwards/argon2id"
)

func main() {
	params := &argon2id.Params{
		Memory:      32 * 1024,
		Iterations:  14,
		Parallelism: 4,
		SaltLength:  16,
		KeyLength:   32,
	}

	hash, err := argon2id.CreateHash("sh1ttyPa$$w0rd", params)
	if err != nil {
		log.Fatal(err)
	}

	match, err := argon2id.ComparePasswordAndHash("sh1ttyPa$$w0rd", hash)
	if err != nil {
		log.Fatal(err)
	}

	log.Printf("Match: %v", match)
}
