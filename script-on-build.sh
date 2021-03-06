#!/bin/bash
echo "ON BUILD SCRIPT JUST STARTED!"

# we loading the build.env as an environment variables
echo "loading environment"
set -o allexport
source build.env
set +o allexport

# this is handle for local running, commit hash is used to tagging the image
# the commit hash is automatic generated by the CloudBuild and CodeBuild
# but for the local running, we will use random hash by using openssl
if [[ "$COMMIT_HASH" == "" ]]
then
    export COMMIT_HASH=`echo $(openssl rand -hex 20)`
fi

# this is handle for local running, repository name is the github repository name,
# in local running, we expect you to add LOCAL_REPOSITORY_NAME in your build.env
# either it is remote repository or your local repository name, e.g.
# repository name aashari/nodejs, once the image pushed, the image will pushed into 
# docker hub aashari account
if [[ "$REPOSITORY_NAME" == "" ]]
then
    export REPOSITORY_NAME=`echo $LOCAL_REPOSITORY_NAME`
fi

# build image using buildx
if [[ "$BUILD_METHOD" == "buildx" ]]
then
    
    # we create new buildx environment with name crossx
    # we set the deffault buildx environment to crossx
    echo "create buildx with name crossx"
    docker buildx create --use --name crossx
    
    # we build all dependencies needed for buildx
    echo "bootstrapping buildx"
    docker buildx inspect --bootstrap
    
    # listing buildx architecture support
    echo "listing buildx"
    docker buildx ls;
    
    # start build the image by using buildx environment
    # we tag the image by using latest image tag and commit hash tag (2 tags for 1 images)
    # we push the build image into the repository
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

    # we will 2 manifest, 1 manifest with latest tag and 1 for commit hash tag (2 tags for 1 images)
    # we store it into temporary file to be executed later
    printf %s "docker manifest create $REPOSITORY_NAME:$LATEST_IMAGE_TAG" >> script-create-manifest-latest-tag.sh
    printf %s "docker manifest create $REPOSITORY_NAME:$COMMIT_HASH" >> script-create-manifest-commit-tag.sh
    
    # we set the permission of the script to be able to execute
    chmod +x script-create-manifest-latest-tag.sh
    chmod +x script-create-manifest-commit-tag.sh

    # we build the image by using native build for each architecture set in ARCHITECTURE_LIST
    export IFS=","
    for CURR_ARC in $ARCHITECTURE_LIST; do
        
        # we build the image for the specific architecture
        echo "build $REPOSITORY_NAME for $CURR_ARC architecture"
        docker build -f Dockerfile-manifest -t $REPOSITORY_NAME:manifest-$CURR_ARC --build-arg ARCH=$CURR_ARC .
        
        # we push the image for the specific architecture to the repository
        echo "pushing $REPOSITORY_NAME:manifest-$CURR_ARC"
        docker push $REPOSITORY_NAME:manifest-$CURR_ARC
        
        # we append the specific image build url for the architecture into the file
        printf %s " $REPOSITORY_NAME:manifest-$CURR_ARC" >> script-create-manifest-latest-tag.sh
        printf %s " $REPOSITORY_NAME:manifest-$CURR_ARC" >> script-create-manifest-commit-tag.sh

    done

    echo "run script to create manifest"
    cat script-create-manifest-latest-tag.sh
    echo "\n"
    cat script-create-manifest-commit-tag.sh
    echo "\n"

    # we run the docker manifest create with 2 tags for 1 image
    echo "start creating manifest"
    ./script-create-manifest-latest-tag.sh
    ./script-create-manifest-commit-tag.sh

    # we push the manifest image into the repository
    echo "pushing manifest $REPOSITORY_NAME:$LATEST_IMAGE_TAG"
    docker manifest push $REPOSITORY_NAME:$LATEST_IMAGE_TAG
    docker manifest push $REPOSITORY_NAME:$COMMIT_HASH

    echo "listing docker image manifest"
    docker buildx imagetools inspect $REPOSITORY_NAME:$LATEST_IMAGE_TAG

fi


## Insert on-build script below
echo "start your on-build script"
