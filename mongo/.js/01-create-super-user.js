/* Make sure we're using the admin database. */
db = db.getSiblingDB('admin');

if (
  db.system.users
    .find({
      user: '$MONGO_GLOBAL_SUPER_USERNAME',
    })
    .count() < 1
) {
  /* We need to create the superUser account. */
  db.createUser({
    user: {
      user: '$MONGO_GLOBAL_SUPER_USERNAME',
      pwd: '$MONGO_GLOBAL_SUPER_PASSWORD',
      customData: {
        description:
          'A global administration account for all databases within this MongoDB server.',
      },
      roles: [
        {
          role: 'root',
          db: 'admin',
        },
        'readWriteAnyDatabase',
      ],
    },
  });
  /* Remove the default "root" user. */
  db.removeUser('root');
}
/* Exit this shell session. */
quit();
