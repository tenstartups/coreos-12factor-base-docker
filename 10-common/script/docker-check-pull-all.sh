#!/bin/bash
set -e

# Set environment variables
DOCKER_IMAGE_NAME_REGEX="^\s*DOCKER_IMAGE_([_A-Z]+)=(.+)\s*$"

# Pull the latest version of all required images
while read -r docker_image_name ; do
  /12factor/bin/docker-check-pull $docker_image_name
done < <(env | grep -E "${DOCKER_IMAGE_NAME_REGEX}" | sed -E "s/${DOCKER_IMAGE_NAME_REGEX}/\1/")

# Pull the latest version of all tagged images
# docker images | grep -v -e "^<none>" -e "REPOSITORY" | while read -r image_desc ; do
#   DOCKER_IMAGE_DESC="$image_desc" /12factor/bin/docker-check-pull
# done
