#!/usr/bin/env bash
CAFFE_USE_MPI=${1:-OFF}
CAFFE_MPI_PREFIX=${MPI_PREFIX:-""}

# update the submodules: Caffe and Dense Flow
git submodule update --remote

# install Caffe dependencies
sudo apt-get -qq install libprotobuf-dev libleveldb-dev libsnappy-dev libhdf5-serial-dev protobuf-compiler libatlas-base-dev
sudo apt-get -qq install --no-install-recommends libboost-all-dev
sudo apt-get -qq install libgflags-dev libgoogle-glog-dev liblmdb-dev

# install Dense_Flow dependencies
sudo apt-get -qq install libzip-dev

# install common dependencies: OpenCV
# adpated from OpenCV.sh
version="2.4.13"

echo "Building OpenCV" $version
[[ -d 3rd-party ]] || mkdir 3rd-party/
cd 3rd-party/

if [ ! -d "opencv-$version" ]; then
    echo "Installing OpenCV Dependenices"
    sudo apt-get -qq install libopencv-dev build-essential checkinstall cmake pkg-config yasm libjpeg-dev libjasper-dev libavcodec-dev libavformat-dev libswscale-dev libdc1394-22-dev libgstreamer0.10-dev libgstreamer-plugins-base0.10-dev libv4l-dev python-dev python-numpy libtbb-dev libqt4-dev libgtk2.0-dev libfaac-dev libmp3lame-dev libopencore-amrnb-dev libopencore-amrwb-dev libtheora-dev libvorbis-dev libxvidcore-dev x264 v4l-utils

    echo "Downloading OpenCV" $version
    wget -O OpenCV-$version.zip https://github.com/Itseez/opencv/archive/$version.zip

    echo "Extracting OpenCV" $version
    unzip OpenCV-$version.zip
fi

echo "Building OpenCV" $version
cd opencv-$version
[[ -d build ]] || mkdir build
cd build
cmake -D CMAKE_CXX_COMPILER=/usr/bin/g++-5 -D CMAKE_C_COMPILER=/usr/bin/gcc-5 -D CMAKE_BUILD_TYPE=RELEASE -D WITH_TBB=ON  -D WITH_V4L=ON -D CUDA_GENERATION=Kepler -D WITH_CUDA=ON -D WITH_CUBLAS=ON -D CUDA_FAST_MATH=ON -D BUILD_TIFF=ON -D WITH_NVCUVID=ON  -D CMAKE_INSTALL_PREFIX=/usr/local ..
if make -j4 ; then
    cp lib/cv2.so ../../../
    echo "OpenCV" $version "built."
else
    echo "Failed to build OpenCV. Please check the logs above."
    exit 1
fi

# build dense_flow
cd ../../../

echo "Building Dense Flow"
cd lib/dense_flow
[[ -d build ]] || mkdir build
cd build
OpenCV_DIR=../../../3rd-party/opencv-$version/build/ cmake -D CMAKE_CXX_COMPILER=/usr/bin/g++-5 -D CMAKE_C_COMPILER=/usr/bin/gcc-5 -D CUDA_USE_STATIC_CUDA_RUNTIME=OFF ..
if make -j ; then
    echo "Dense Flow built."
else
    echo "Failed to build Dense Flow. Please check the logs above."
    exit 1
fi

# build caffe
echo "Building Caffe, MPI status: ${CAFFE_USE_MPI}"
cd ../../caffe-action
[[ -d build ]] || mkdir build
cd build
if [ "$CAFFE_USE_MPI" == "MPI_ON" ]; then
OpenCV_DIR=../../../3rd-party/opencv-$version/build/ cmake -D CMAKE_CXX_COMPILER=/usr/bin/g++-5 -D CMAKE_C_COMPILER=/usr/bin/gcc-5 -DUSE_MPI=ON -DMPI_CXX_COMPILER="${CAFFE_MPI_PREFIX}/bin/mpicxx" -D CUDA_USE_STATIC_CUDA_RUNTIME=OFF ..
else
OpenCV_DIR=../../../3rd-party/opencv-$version/build/ cmake -D CUDA_USE_STATIC_CUDA_RUNTIME=OFF -D CMAKE_CXX_COMPILER=/usr/bin/g++-5 -D CMAKE_C_COMPILER=/usr/bin/gcc-5 ..
fi
if make -j4 install ; then
    echo "Caffe Built."
    echo "All tools built. Happy experimenting!"
    cd ../../../
else
    echo "Failed to build Caffe. Please check the logs above."
    exit 1
fi
