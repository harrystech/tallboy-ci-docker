# Tallboy CI Docker

Create Docker image that we can use with Tallboy for CI/CD.

This image has Java, sbt and Scala at fixed versions.

## Build

```shell
docker build --tag tallboy-ci-docker:latest .
```

## Use

Change into the directory with your source code, then
```shell
docker run --rm --interactive --tty --volume `pwd`:/home/harrys/scala tallboy-ci-docker:latest
```
and
```shell
cd scala
sbt run
```
