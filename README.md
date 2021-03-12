# Flarum Docker

<p align="center">
  <a href="https://asciinema.org/a/QIWV9GTc4zmi4qjDj9W3HxJ92"><img width="60%" src="https://user-images.githubusercontent.com/4926565/110992620-02e00400-832b-11eb-922f-0a890759916c.png" /></a>
</p>

Make sure to have these installed

* [docker](https://docs.docker.com/engine/install/)
* [docker-compose](https://docs.docker.com/compose/install/)
* [just](https://github.com/casey/just) (Optional, and I may write a bash script to replace it at some point)

## Quickstart
This repo is meant to be a base repo for your flarum install.  
So, to use it the first step is to not clone it, but [duplicate the repo](https://docs.github.com/en/github/creating-cloning-and-archiving-repositories/duplicating-a-repository) to your own git repo.

Copy `docs/env.example` to `.env`, verify the HOSTNAME is correct, it will be written in `config.php` as `https://HOSTNAME`. If you're mounting it directly it might look like `domain.tld:4443` and if you're using a reverse proxy: `mydomain.tld`

```
docker-compose build
docker-compose up -d
docker-compose logs -f
```

Once it's up, run this to enter
If you don't want to install just, view the `justfile` to see what each command does.
For this one it's mostly just `docker-compose exec forum bash`

```
just enter
```

You're now root in the `/app` directory. Try running `php flarum info` to see what you're working with.
Make your changes, (such as installing a plugin) and exit out.

Run this to update `docker/composer.json` and `docker/composer.lock`

```
just update
```

Everything so far is temporary. Run this to build the image and pull it back up

```
docker-compose down
docker-compose build
docker-compose up -d
```

You should have a updated image now

## Customizing

This image uses `webdevops/php-nginx` as its base.

### Base

[Documentation](https://dockerfile.readthedocs.io/en/latest/content/DockerImages/dockerfiles/php-nginx.html)

Here you can override nginx and php configuration. To do this, create files in `docker/webserver_config` 

For example, to use the realip module in nginx you would place a file called `20-realip.conf` in `docker/webserver_config/20-realip.conf`
It would contain something like this:

```nginx
set_real_ip_from 172.0.0.0/8;
real_ip_header X-Forwarded-For;
real_ip_recursive on;
```

Then create a line in `docker/Dockerfile`, in the production section

```dockerfile
COPY webserver_config/20-realip.conf /opt/docker/etc/nginx/conf.d/20-realip.conf
```

Run `docker-compose build` and it should be using the realip module!

### Flarum

Everything is installed at `/app`. If you provided a `EXTIVERSE_TOKEN` in `.env`, you should be logged in to Extiverse when you are in the container. To enter the container run 

```
just enter
```

This enters into the container with the bash shell. On exit, it compares `composer.json` in the container to `docker/composer.json` to see if any changes were made. This could look something like this:

```
$ just enter
root@acc:/app# composer require fof/realtimedate
[...]
root@acc:/app# exit
>         "fof/realtimedate": "^0.2.1",
```

If you want to keep these changes, run

```
just update
```

This copies out `composer.json` and `composer.lock` from the container to `docker/` 

It also says what was changed.
To do a cycle of updating, rebuilding and re-entering run this command:

```
just cycle
```

This effectively does this:

```
  just update
  just stop
  docker-compose build
  just start
  just enter
```

## Deploying

It is important that when building, to build to target `production`  
`production` does not contain any special values (like your EXTIVERSE_TOKEN) but `builder` and `dev` stages do.
To build, run this

```
just build myflarumsite:latest
```

If you have a private repo at `https://dockerrepo.example.com` you would write like this (for example)

```
just build dockerrepo.example.com:v02.01.01
```

You don't have to use a repo. It's possible to [export and import a docker image as a tarball](https://stackoverflow.com/questions/23935141/how-to-copy-docker-images-from-one-host-to-another-without-using-a-repository)

It is possible to deploy with CI/CD as well

<details>
<summary>DroneCI example</summary>

```
---
kind: pipeline
type: docker
name: build
steps:
-   name: Build flarum docker image and push to registry
    image: plugins/docker
    settings:
        use_cache: true
        repo:
          from_secret: DOCKER_REGISTRY_REPO
        username:
          from_secret: DOCKER_REGISTRY_USERNAME
        password:
          from_secret: DOCKER_REGISTRY_PASSWORD
        registry:
          from_secret: DOCKER_REGISTRY_URL
        build_args_from_env:
          - EXTIVERSE_TOKEN
        tags:
          - latest
        dockerfile: docker/Dockerfile
        context: docker/
        target: production
    environment:
        EXTIVERSE_TOKEN:
          from_secret: EXTIVERSE_TOKEN
```
</details>



