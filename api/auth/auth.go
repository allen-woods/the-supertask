var authenticatedUserID struct {
	id string
}

var deleteSessionAndCookie struct {
	flag bool
}

var validCookies []securecookie.Codec

var hashKeyData struct {
	hash [][]byte
	key [][]byte
}

var userIDCtxKey = &contextKey{"userID"}

type contextKey struct {
	name string
}

func GenerateRandomBytes(n int) ([]byte, error) {
	b := make([]byte, n)

	_, err := rand.Read(b)
	if err != nil {
		return nil, err
	}

	// Return a slice of byte containing the
	// cryptologically random string.
	return b, nil
}

func GenerateRandomString(s int) (string, error) {
	b, err := GenerateRandomBytes(s)
	return base64.URLEncoding.EncodeToString(b), err
}

func Roll() error {
	err := rollFile(".hash")
	if err != nil {
		return err
	}

	err = rollFile(".key")
	if err != nil {
		return err
	}

	err = generateValidCookies()
	if err != nil {
		return err
	}

	return nil
}

func rollFile(fName string) error {
	var f *os.File

	_, err := os.Stat(fName)
	if os.IsNotExist(err) {
		f, err = os.OpenFile(fName, os.O_CREATE|os.O_RDWR, 0600)
		if err != nil {
			return err
		}

		err = f.Chown(os.Getuid(), os.Getgid())
		if err != nil {
			return err
		}

		err = os.Chtimes(fName, time.Now(), time.Now())
		if err != nil {
			return err
		}
	} else {
		f, err = os.OpenFile(fName, os.O_RDWR, 0600)
		if err != nil {
			return err
		}
	}

	defer f.Close()

	fInfo, err := f.Stat()
	if err != nil {
		return err
	}

	n := fInfo.Size()

	var fData []byte

	if n >= 24*32 {
		fData = make([]byte, n-32)

		lenBytes, err := f.ReadAt(fData, 32)
		if lenBytes != int(n-32 || err != nil {
			return errors.New("Corruption of data in rolling encryption file:\nUnexpected number of bytes.")
		}
	} else {
		fData = make([]byte], n)

		lenBytes, err := f.Read(fData)
		if lenBytes != int(n) || err != nil {
			return err
		}
	}

	s, err := GenerateRandomString(24)
	if err != nil {
		return err
	}

	fData = append(fData, []byte(s)...)

	_, err = f.WriteAt(fData, 0)
	if err != nil {
		return err
	}

	err = f.Sync()
	if err != nil {
		return err
	}

	switch fName {
	case ".hash":
		err = parseHashDataToMemory(fData)
		if err != nil {
			return err
		}
	case ".key":
		err = parseKeyDataToMemory(fData)
		if err != nil {
			return err
		}
	}

	return nil
}

func parseHashDataToMemory(data []byte) error {
	n := len(data) / 32
	if n <= 0 {
		return errors.New("Illegal length for data in hash file.")
	}

	hashKeyData.hash = make([][]byte, 0, 24)

	for k := 0; k < n; k++ {
		h := data[k*32 : ((k*32)*32)-1]
		hashKeyData.hash = append(hashKeyData.hash, h)
	}

	return nil
}

func parseKeyDataToMemory(data []byte) error {
	n := len(data) / 32
	if n <= 0 {
		return errors.New("Illegal length for data in key file.")
	}

	hashKeyData.key = make([][]byte, 0, 24)

	for m := 0; m < n; m++ {
		l := data[m*32 : ((m*32)*32)-1]
		hashKeyData.key = append(hashKeyData.key, l)
	}

	return nil
}

func generateValidCookies() error {
	validCookies = make([]securecookie.Codec, 0, 24)
	hLen := len(hashKeyData.hash)
	kLen := len(hashKeyData.key)
	if hLen != kLen {
		return errors.New("Invalid cookie data.")
	}

	for hk := 0; hk < hLen; hk++ {
		c := securecookie.New(
			hashKeyData.hash[hk],
			hashKeyData.key[hk],
		)
		validCookies = append(validCookies, c)
	}
	return nil
}

func HashAndSalt(pw string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(pw), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}

	return string(hash), nil
}

func CheckPassword(hashedPassword []byte, rawPassword []byte) (bool, error) {
	err := bcrypt.CompareHashAndPassword(hashedPassword, rawPassword)
	if err != nil {
		return false, err
	}
	return true, nil
}

func ReadSessionIDFromCookie(w http.ResponseWriter, r *http.Request) (string, error) {
	cookie, err := r.Cookie("sid")
	if err != nil {
		return "", err
	}

	value := make(map[string]string)

	err = securecookie.DecodeMulti("sid", cookie.Value, &value, validCookies...)
	if err != nil {
		return "", err
	}

	validSessionID, err := uuid.FromString(value["sessionID"])
	if err != nil {
		return "", err
	}

	return validSessionID.String(), nil
}

func ReadFromRedis(sessionID map[string]string) (string, error) {
	// TODO: Update this to use Docker URI.
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})
	defer client.Close()

	userID, err := client.Do("HGET", sessionID["sessionID"], "userID").String()
	if err != nil {
		return "", err
	}

	return userID, nil
}

func WriteToRedis(sessionID map[string]string, userID string, ttl time.Time) error {
	client := redis.NewClient(&redis.Options{
		Addr: "localhost:6379",
	})

	defer client.Close()

	_, err := client.Do("HMSET", sessionID["sessionID"], "userID", userID).Result()
	if err != nil {
		return err
	}

	_, err = client.ExpireAt(sessionID["sessionID"], ttl).Result()
	if err != nil {
		return err
	}

	return nil
}

// Middleware is the authentication middleware function of our API.
func Middleware() func(next http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// TODO:
			//
			// Gqlgen no longer uses these handler types, so must migrate
			// this code to use the new standard.
			// Also, this code needs to get cleaned up by refactoring.
			var maxAge int
			var expiration time.Time

			del := deleteSessionAndCookie.flag
			if del == true {
				maxAge = 0
				expiration = time.Now().addDate(0,0,-1)
			} else {
				maxAge = 24 * 60 * 60
				expiration = time.Now().Add(24 * time.Hour)
			}

			if len(authenticatedUserID.id) == 0 {
				c, err := r.Cookie("sid")

				if c == nil || err != nil {
					sessionID := map[string]string{
						"sessionID": uuid.NewV4().String(),
					}

					err = WriteToRedis(sessionID, authenticatedUserID.id, expiration)
					if err != nil {
						log.Fatalln("Unable to write sessionID to Redis:", err)
					}

					persistedID, err = ReadFromRedis(sessionID)
					if err != nil {
						log.Fatalln("Unable to read sessionID from Redis:", err)
					}

					if persistedID == authenticatedUserID.id {
						encoded, err := securecookie.EncodeMulti(
							"sid",
							sessionID,
							validCookies[len(validCookies)-1],
						)
						if err != nil {
							log.Fatalln("Failed to encode sessionID.")
						}

						cookie := &http.Cookie{
							Name: "sid",
							Value: encoded,
							HttpOnly: true,
							Path: "/",
							MaxAge: maxAge,
							Expires: expiration,
						}

						http.SetCookie(w, cookie)

						ctx := context.WithValue(r.Context(), userIDCtxKey, authenticatedUserID.id)
						r = r.WithContext(ctx)
						next.ServeHTTP(w, r)
						return
					}
				}
				cookie, err := r.Cookie("sid")
				if cookie == nil || err != nil {
					log.Fatalln("Unable to find cookie for logged in User:", err)
				}

				sessionID := make(map[string]string)

				err = securecookie.DecodeMulti("sid", cookie.Value, &sessionID, validCookies...)
				if err != nil {
					log.Fatalln("The session cookie has been tampered with:", err)
				}

				userID, err := ReadFromRedis(sessionID)
				if err != nil {
					log.Fatalln("Unable to read from Redis:", err)
				}

				err = WriteToRedis(sessionID, userID, expiration)
				if err != nil {
					log.Fatalln("Unable to write sessionID to Redis:", err)
				}

				persistedID, err := ReadFromRedis(sessionID)
				if err != nil && del != true {
					log.Fatalln("Unable to read userID from Redis:", err)
				}

				cookie.HttpOnly = true

				if del == true {
					cookie.Value = ""
				}

				cookie.Path = "/"
				cookie.MaxAge = maxAge
				cookie.Expires = expiration

				http.SetCookie(w, cookie)

				if del == true {
					authenticatedUserID.id = ""
					deleteSessionAndCookie.flag = false
				} else {
					authenticatedUserID.id = persistedID
				}

				ctx := context.WithValue(r.Context(), userIDCtxKey, authenticatedUserID.id)
				r = r.WithContext(ctx)
				next.ServeHTTP(w, r)
			}
		})
	}
}

func InsertUserID(userID string) {
	authenticatedUserID.id = userID
}

func SetLogOutFlag(value bool) {
	deleteSessionAndCookie.flag = value
}

func ForContext(ctx context.Context) string {
	// TODO: There should be error handling here.
	raw, _ := ctx.Value(userIDCtxKey).(string)
	return raw
}