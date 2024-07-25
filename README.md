# Postgres

## Default values

```ini
TZ         = UTC
LANG       = en_US.UTF-8
PGDATABASE = postgres
PGUSER     = postgres
PGPASSWORD = postgres
PGDATA     = /var/pgsql/data
```

## Quick run

```shell
docker run --rm -it \
  -e TZ=Brazil/East \
  -e LANG=pt_BR.UTF-8 \
  -e PGDATABASE=my_db \
  -e PGUSER=user \
  -e PGPASSWORD=password \
  -p 5432:5432 \
  postgres:15.4
```

Using Docker Secrets

```shell
docker run --rm -it \
  -e TZ=Brazil/East \
  -e LANG=pt_BR.UTF-8 \
  -e PGDATABASE=my_db \
  -e PGUSER=user \
  -v ./pgpassword.secret:/run/secrets/pgpassword \
  -v pg_data:/var/pgsql/data \
  -p 5432:5432 \
  postgres:15.4
```
