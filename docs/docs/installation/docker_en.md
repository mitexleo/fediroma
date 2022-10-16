# Installing in docker

{! installation/otp_vs_from_source_source.include !}

## Installation

This guide will show you how to get akkoma working in a docker container,
if you want isolation, or if you run a distribution not supported by the OTP
releases.

### Prepare the system

* Install docker and docker-compose
  * [Docker](https://docs.docker.com/engine/install/) 
  * [Docker-compose](https://docs.docker.com/compose/install/)
  * This will usually just be a repository installation and a package manager invocation.
* Clone the akkoma repository
  * `git clone https://akkoma.dev/AkkomaGang/akkoma.git -b stable`
  * `cd akkoma`

### Set up basic configuration

```bash
cp docker-resources/env.example .env
```

This probably won't need to be changed, it's only there to set basic environment
variables for the docker-compose file.

### Building the container

The container provided is a thin wrapper around akkoma's dependencies, 
it does not contain the code itself. This is to allow for easy updates
and debugging if required.

```bash
./docker-resources/build.sh
```

This will generate a container called `akkoma` which we can use
in our compose environment.

### Generating your instance

```bash
./docker-resources/manage.sh mix deps.get
./docker-resources/manage.sh mix compile
./docker-resources/manage.sh mix pleroma.instance gen
```

This will ask you a few questions - the defaults are fine for most things,
the database hostname is `db`. 

Now we'll want to copy over the config it just created

```bash
cp config/generated_config.exs config/prod.secret.exs
```

### Setting up the database 

We need to run a few commands on the database container, this isn't too bad

```bash
docker-compose run --rm -d db 
# Note down the name it gives here, it will be something like akkoma_db_run
docker-compose run --rm akkoma psql -h db -U akkoma -f config/setup_db.psql
docker stop akkoma_db_run # Replace with the name you noted down
```

Now we can actually run our migrations

```bash
./docker-resources/manage.sh mix ecto.migrate
# this will recompile your files at the same time, since we changed the config
```

### Start the server

We're going to run it in the foreground on the first run, just to make sure
everything start up.

```bash
docker-compose up
```
#### Create your first user

If your instance is up and running, you can create your first user with administrative rights with the following task:

```shell
doas -u akkoma env MIX_ENV=prod mix pleroma.user new <username> <your@emailaddress> --admin
```

{! installation/frontends.include !}

#### Further reading

{! installation/further_reading.include !}

{! support.include !}
