# Migrating to a Docker Installation

If you for any reason wish to migrate a source or OTP install to a Docker one,
this guide is for you.

You have a few options - your major one will be whether you want to keep your
reverse-proxy setup from before.

You probably should, in the first instance.

### Prepare the system

* Install Docker and Docker Compose
    * [Docker](https://docs.docker.com/engine/install/)
    * [Docker Compose](https://docs.docker.com/compose/install/)
    * This will usually just be a repository installation and a package manager invocation.

=== "Source"
```bash
git pull
```

=== "OTP"
Clone the `akkoma` repository

```bash
git clone https://akkoma.dev/AkkomaGang/akkoma.git -b stable
cd akkoma
```

### Back up your old database

Change the database name as needed

```bash
pg_dump -d akkoma_prod --format c > akkoma_backup.sql
```

### Getting your static files in the right place

This will vary by every installation. Copy your `instance` directory to `instance/` in
the Akkoma source directory - this is where the Docker container will look for it.

For *most* from-source installs it'll already be there.

And the same with `uploads`, make sure your uploads (if you have them on disk) are
located at `uploads/` in the Akkoma source directory.

If you have them on a different disk, you will need to mount that disk into the Docker Compose file,
with an entry that looks like this:

```yaml
akkoma:
  volumes:
  - .:/opt/akkoma # This should already be there
  - type: bind
    source: /path/to/your/uploads
    target: /opt/akkoma/uploads
```

### Set up basic configuration

```bash
cp docker-resources/env.example .env
echo "DOCKER_USER=$(id -u):$(id -g)" >> .env
```

This probably won't need to be changed, it's only there to set basic environment
variables for the Docker Compose file.

=== "From source"

You probably won't need to change your config. Provided your `config/prod.secret.exs` file
is still there, you're all good.

=== "OTP"
```bash
cp /etc/akkoma/config.exs config/prod.secret.exs
```

**BOTH**

Set the following config in `config/prod.secret.exs`:
```elixir
config :pleroma, Pleroma.Web.Endpoint,
   ...,
   http: [ip: {0, 0, 0, 0}, port: 4000]

config :pleroma, Pleroma.Repo,
  ...,
  username: "akkoma",
  password: "akkoma",
  database: "akkoma",
  hostname: "db"
```

### Building the container

The container provided is a thin wrapper around Akkoma's dependencies,
it does not contain the code itself. This is to allow for easy updates
and debugging if required.

```bash
./docker-resources/build.sh
```

This will generate a container called `akkoma` which we can use
in our Compose environment.

### Setting up the Docker resources

```bash
# These won't exist if you're migrating from OTP
rm -rf deps
rm -rf _build
```

```bash
mkdir pgdata
./docker-resources/manage.sh mix deps.get
./docker-resources/manage.sh mix compile
```

### Setting up the database

Now we can import our database to the container.

```bash
docker compose run --rm --user akkoma -d db
docker compose run --rm akkoma pg_restore -v -U akkoma -j $(grep -c ^processor /proc/cpuinfo) -d akkoma -h db akkoma_backup.sql
```

### Reverse proxies

If you're just reusing your old proxy, you may have to uncomment the line in
the Docker Compose file under `ports`. You'll find it.

Otherwise, you can use the same setup as the [Docker installation guide](./docker_en.md#reverse-proxies).

### Let's go

```bash
docker compose up -d
```

You should now be at the same point as you were before, but with a Docker install.

{! installation/frontends.include !}

See the [Docker installation guide](./docker_en.md) for more information on how to
update.

#### Further reading

{! installation/further_reading.include !}

{! support.include !}

