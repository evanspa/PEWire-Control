#!/bin/bash

readonly PROJECT_NAME="PEWire-Control"
readonly SDK_VERSION="8.3"
readonly ARCH="i386"
export LC_CTYPE=en_US.UTF-8


xcodebuild \
-workspace ${PROJECT_NAME}.xcworkspace \
-scheme ${PROJECT_NAME}Tests \
-configuration Debug \
-sdk iphonesimulator${SDK_VERSION} \
-arch ${ARCH} test
