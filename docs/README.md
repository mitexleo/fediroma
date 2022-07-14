# Pleroma documentation

This project contains a documentation skeleton and a script to fill it in with data, the resulting documentation can be viewed at <https://akkoma.dev/main>.

## Contributing to the documentation

If you want to suggest an edit, please refer to the `AkkomaGang/akkoma` and `AkkomaGang/pleroma-fe` repos.

We use [mkdocs](https://www.mkdocs.org/) to build the documentation and have the [admonition](https://squidfunk.github.io/mkdocs-material/extensions/admonition/) extensions that make it possible to add block-styled side content like example summaries, notes, hints or warnings. If you are unsure of how a specific syntax should look like, feel free to look through the docs for an example.

## Building the docs

You don't need to build and test the docs as long as you make sure the syntax is correct. But in case you do want to build the docs, feel free to do so.

You'll need to install mkdocs for which you can check the [mkdocs installation guide](https://www.mkdocs.org/#installation). Generally it's best to install it using `pip`. You'll also need to install the correct dependencies.

To build the docs you can clone this project and use the `manage.sh` script.

### Example using a Debian based distro

#### 1. Install pipenv and dependencies

```shell
pip install pipenv
pipenv sync
```

#### 2. (Optional) Activate the virtual environment

Since dependencies are installed in a virtual environment, you can't use them directly. To use them you should either prefix the command with `pipenv run`, or activate the virtual environment for current shell by executing `pipenv shell` once.

#### 3. Build the docs using the script

```shell
git clone https://git.pleroma.social/pleroma/docs
cd docs
[pipenv run] ./manage.sh all
```

`./manage.sh all` will fetch the docs from the pleroma and pleroma-fe repos and build the documentation locally. To see what other options you have, do `./manage.sh --help`.

#### 4. Serve the files

A folder `site` containing the static html pages will have been created. You can serve them from a server by pointing your server software (nginx, apache...) to this location. During development, you can run locally with

```shell
[pipenv run] mkdocs serve
```

This handles setting up an http server and rebuilding when files change. You can then access the docs on <http://127.0.0.1:8000>

