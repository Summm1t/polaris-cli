# polaris-cli

A Docker image that packages the [Apache Polaris](https://polaris.apache.org/) command-line
interface, so you can run `polaris` commands without installing Python or the CLI locally.

Apache Polaris is a catalog service for Apache Iceberg. The CLI (published on PyPI as
[`apache-polaris`](https://pypi.org/project/apache-polaris/)) talks to a Polaris REST catalog
server to manage catalogs, principals, roles, and grants. Full command and option reference:
https://polaris.incubator.apache.org/in-dev/unreleased/command-line-interface/

## Image overview

The `Dockerfile` uses a two-stage build on `alpine:3.23.5`:

1. **`build-stage`** — installs Python 3 and creates a virtualenv at `/app/venv`, then installs
   `apache-polaris` into it with `pip` using the pinned version from
   [`requirements.txt`](requirements.txt) (currently `1.7.0`).
2. **`runtime-stage`** — a fresh Alpine base with only `python3`, `jq`, and `curl`, into which the
   populated virtualenv is copied from the build stage. This keeps the final image free of build
   tooling.

`PATH` includes `/app/venv/bin`, so the `polaris` executable is available directly. The default
`CMD` is `/app/venv/bin/polaris -h`.

There is no `ENTRYPOINT`, only `CMD`, so any arguments passed to `docker run` **replace** the
default command entirely — you need to include `polaris` yourself when running commands (see
examples below).

## Prerequisites

- Docker (or a compatible container runtime)

## Building the image

From the repository root:

```bash
docker build -t polaris-cli .
```

Optionally tag it for your own registry:

```bash
docker build -t <registry>/polaris-cli:<tag> .
```

## Running the CLI

Show the CLI help (default command):

```bash
docker run --rm polaris-cli
```

Run any other `polaris` subcommand by specifying it explicitly, since it replaces the default
`CMD`:

```bash
docker run --rm polaris-cli polaris --version
docker run --rm polaris-cli polaris catalogs list
```

### Connecting to a Polaris server

Most commands need connection details for a running Polaris server (host/port and
authentication, e.g. an OAuth2 client ID/secret or access token). Pass these as CLI options
per the [CLI reference](https://polaris.incubator.apache.org/in-dev/unreleased/command-line-interface/),
for example:

```bash
docker run --rm polaris-cli polaris \
  --host polaris.example.com --port 8181 \
  --client-id "$POLARIS_CLIENT_ID" --client-secret "$POLARIS_CLIENT_SECRET" \
  catalogs list
```

You can also run multiple commands in a bash shell, and make use of `jq` to parse JSON output:

```bash
POLARIS_CLIENT_ID=root
POLARIS_CLIENT_SECRET=s3cr3t
docker run --rm --env CLIENT_ID="$POLARIS_CLIENT_ID" --env CLIENT_SECRET="$POLARIS_CLIENT_SECRET" polaris-cli bash -c "\
  CATALOG_NAMES=\$(polaris --host host.docker.internal catalogs list | jq '.name'); \
  echo \"Catalog names are: \$CATALOG_NAMES\" \
  "
```

## License

Licensed under the Apache License, Version 2.0. See [LICENSE](LICENSE).
