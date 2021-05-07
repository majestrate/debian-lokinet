export arch=${ARCH:-amd64}
export release=${RELEASE:-buster}

default_build="$(pwd)/build_${release}_${arch}"

export build=${BUILD_DIR:-$default_build}
