#!/bin/bash
echo "ON BUILD SCRIPT JUST STARTED!"

echo "loading environment"
set -o allexport
source build.env
set +o allexport

if [[ "$COMMIT_HASH" == "" ]]
then
    export COMMIT_HASH=`echo $(openssl rand -hex 20)`
fi

if [[ "$REPOSITORY_NAME" == "" ]]
then
    export REPOSITORY_NAME=`echo $LOCAL_REPOSITORY_NAME`
fi

# build image using buildx
if [[ "$BUILD_METHOD" == "buildx" ]]
then
    
    echo "create buildx with name crossx"
    docker buildx create --use --name crossx
    
    echo "bootstrapping buildx"
    docker buildx inspect --bootstrap
    
    echo "listing buildx"
    docker buildx ls;
    
    echo "build and push docker image with $ARCHITECTURE_LIST"
    docker buildx build -f Dockerfile-buildx --platform $ARCHITECTURE_LIST  \
        -t $REPOSITORY_NAME:$LATEST_IMAGE_TAG \
        -t $REPOSITORY_NAME:$COMMIT_HASH \
        --push .
    
    echo "listing docker image manifest"
    docker buildx imagetools inspect $REPOSITORY_NAME:$LATEST_IMAGE_TAG
fi

# build image manually and then wrap it by using manifest
if [[ "$BUILD_METHOD" == "manifest" ]]
then

    printf %s "docker manifest create $REPOSITORY_NAME:$LATEST_IMAGE_TAG" >> script-create-manifest-latest-tag.sh
    printf %s "docker manifest create $REPOSITORY_NAME:$COMMIT_HASH" >> script-create-manifest-commit-tag.sh
    chmod +x script-create-manifest-latest-tag.sh
    chmod +x script-create-manifest-commit-tag.sh

    export IFS=","
    for CURR_ARC in $ARCHITECTURE_LIST; do
        
        echo "build $REPOSITORY_NAME for $CURR_ARC architecture"
        docker build -f Dockerfile-manifest -t $REPOSITORY_NAME:manifest-$CURR_ARC --build-arg ARCH=$CURR_ARC .
        
        echo "pushing $REPOSITORY_NAME:manifest-$CURR_ARC"
        docker push $REPOSITORY_NAME:manifest-$CURR_ARC
        
        printf %s " $REPOSITORY_NAME:manifest-$CURR_ARC" >> script-create-manifest-latest-tag.sh
        printf %s " $REPOSITORY_NAME:manifest-$CURR_ARC" >> script-create-manifest-commit-tag.sh

    done

    echo "run script to create manifest"
    cat script-create-manifest-latest-tag.sh
    echo "\n"
    cat script-create-manifest-commit-tag.sh
    echo "\n"

    echo "start creating manifest"
    ./script-create-manifest-latest-tag.sh
    ./script-create-manifest-commit-tag.sh

    echo "pushing manifest $REPOSITORY_NAME:$LATEST_IMAGE_TAG"
    docker manifest push $REPOSITORY_NAME:$LATEST_IMAGE_TAG
    docker manifest push $REPOSITORY_NAME:$COMMIT_HASH

    echo "listing docker image manifest"
    docker buildx imagetools inspect $REPOSITORY_NAME:$LATEST_IMAGE_TAG

fi


## Insert on-build script below
echo "start your on-build script"
