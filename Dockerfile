#########################################################################################################
#
# Dockerfile for:
#   * Theano v1.0.2
#   * CUDA9.0 + cuDNN7.0 + NCCL2.2
#   * Keras v2.2.2
#
# This image is based on "honghu/intelpython3:gpu-cu9.0-dnn7.2-18.09",
# where "Intel® Distribution for Python" is installed.
#
#########################################################################################################
#
# More Information
#   * Intel® Distribution for Python:
#       https://software.intel.com/en-us/distribution-for-python
#
#########################################################################################################
#
# Software License Agreement
#   If you use the docker image built from this Dockerfile, it means 
#   you accept the following agreements:
#     * Intel® Distribution for Python:
#         https://software.intel.com/en-us/articles/end-user-license-agreement
#     * NVIDIA cuDNN:
#         https://docs.nvidia.com/deeplearning/sdk/cudnn-sla/index.html
#     * NVIDIA NCCL:
#         https://docs.nvidia.com/deeplearning/sdk/nccl-sla/index.html
#
#########################################################################################################
FROM honghu/intelpython3:gpu-cu9.0-dnn7.2-18.09
LABEL maintainer="Chi-Hung Weng <wengchihung@gmail.com>"

ARG THEANO_VER=1.0.2
ARG LIBGPUARRAY_VER=v0.7.6
ARG CUDNN_VER=7.0.5.15-1+cuda9.0
ARG KERAS_VER=2.2.2

# Downgrade cuDNN to v7.0, as cuDNN v7.2 is newer than the newest version of Theano.
RUN apt install -y --allow-downgrades --allow-change-held-packages libcudnn7=7.0.5.15-1+cuda9.0 libcudnn7-dev=7.0.5.15-1+cuda9.0

# Obtain libgpuarray  & pygpu.
RUN git clone https://github.com/Theano/libgpuarray.git /opt/libgpuarray && \
    git -C /opt/libgpuarray checkout ${LIBGPUARRAY_VER}

WORKDIR /opt/libgpuarray

# Build and Install libgpuarray & pygpu.
RUN mkdir Build && \
    cd Build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    cd .. && \
    python setup.py build && \
    python setup.py install

# Build and Install Theano
RUN pip --no-cache-dir install Theano==${THEANO_VER}

ENV THEANO_FLAGS 'device=cuda,floatX=float32'
# FP32 is used by default. You can always reset this flag.

# Install Keras.
RUN pip --no-cache-dir install keras==${KERAS_VER} && \
    rm -rf /tmp/pip* && \
    rm -rf /root/.cache

# Tell Keras to use Theano as its backend.
RUN mkdir /root/.keras && \
    wget -O /root/.keras/keras.json https://raw.githubusercontent.com/chi-hung/DockerbuildsKeras/master/keras-cntk.json && \
    sed -i -e 's/cntk/theano/g' /root/.keras/keras.json

# Add a MNIST example.
WORKDIR /workspace
RUN wget -O /workspace/DemoKerasMNIST.ipynb https://raw.githubusercontent.com/chi-hung/PythonDataMining/master/code_examples/KerasMNISTDemo.ipynb