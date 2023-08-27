#!/usr/bin/env bash

docker images --format "{{.Repository}}:{{.Tag}}" >dockerimages.txt

while read line; do
    # Remove private images
    if [[ $line == *"<none>"* ]] || [[ $line == *"cocos"* ]] || [[ $line == *"ghcr.io/0x6flab/"* ]] || [[ $line == *"clients"* ]]; then
        continue
    fi
    echo "docker pull $line"

done <dockerimages.txt >images.sh

rm dockerimages.txt

chmod +x images.sh
