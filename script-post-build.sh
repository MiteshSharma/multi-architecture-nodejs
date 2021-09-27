#!/bin/bash
echo "POST BUILD SCRIPT JUST STARTED!"

echo "loading environment"
set -o allexport
source build.env
set +o allexport

## Insert post-build script below
echo "start your post-build script"
