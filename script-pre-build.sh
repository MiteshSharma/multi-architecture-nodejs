#!/bin/bash
echo "PRE BUILD SCRIPT JUST STARTED!"

echo "loading environment"
set -o allexport
source build.env
set +o allexport

# Installing official buildx plugin for docker
export DOCKER_BUILDKIT=1;
docker build --platform=local -o . git://github.com/docker/buildx;
mkdir -p ~/.docker/cli-plugins;
mv buildx ~/.docker/cli-plugins/docker-buildx;
chmod a+x ~/.docker/cli-plugins/docker-buildx;
docker run --privileged --rm tonistiigi/binfmt --install all;
docker buildx ls;

## Insert pre-build script below
echo "start your pre-build script"
