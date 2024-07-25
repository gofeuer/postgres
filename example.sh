# Password file
docker run \
  -e TZ=Brazil/East \
  -e LANG=pt_BR.UTF-8 \
  -e PGDATABASE=my_db \
  -e PGUSER=user \
  -v ./pgpassword.secret:/run/secrets/pgpassword \
  -v my_db:/var/pgsql/data \
  -p 5432:5432 \
  postgres:15.4

# Password on environment variable
docker run -it \
  -e TZ=Brazil/East \
  -e LANG=pt_BR.UTF-8 \
  -e PGDATABASE=my_db \
  -e PGUSER=user \
  -e PGPASSWORD=password \
  -v my_db:/var/pgsql/data \
  -p 5432:5432 \
  postgres:15.4
  