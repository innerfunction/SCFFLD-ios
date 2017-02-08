#!/bin/bash
# Publish the pod spec
if [ "$1" == "--private" ]; then
    echo "Publishing to innerfunction private pod spec repo"
    pod repo push if-podspecs SCFFLD.podspec --allow-warnings
else
    echo "Publishing to public pod spec repo"
    pod trunk push SCFFLD.podspec --allow-warnings
fi

