FROM ubuntu:20.04

LABEL name=Manticore
LABEL src="https://github.com/trailofbits/manticore"
LABEL creator="Trail of Bits"
LABEL dockerfile_maintenance=trailofbits

ENV LANG C.UTF-8

RUN apt-get -y update && DEBIAN_FRONTEND=noninteractive apt-get -y install git \
 wget vim software-properties-common tzdata curl cmake unzip

RUN add-apt-repository ppa:deadsnakes/ppa \
 && apt-get -y install python3.7 python3.7-dev python3-pip python3.7-distutils

RUN python3.7 -m pip install -U pip \
  && pip install solc-select \
  && solc-select install 0.7.6 \
  && solc-select install 0.8.13 \
  && solc-select use 0.7.6

ADD . /manticore
RUN cd manticore && python3.7 -m pip install .[native]

# Install smt-solvers (Z3 is already installed as a Python dependency)
# (1) yices2
RUN wget https://yices.csl.sri.com/releases/2.6.4/yices-2.6.4-x86_64-pc-linux-gnu.tar.gz \
  && tar -xzvf yices-2.6.4-x86_64-pc-linux-gnu.tar.gz \
  && rm yices-2.6.4-x86_64-pc-linux-gnu.tar.gz \
  && cd yices-2.6.4 \
  && ./install-yices

# (2) cvc4
RUN mkdir cvc4-solver && cd cvc4-solver
RUN cd cvc4-solver && wget https://github.com/CVC4/CVC4/releases/download/1.8/cvc4-1.8-x86_64-linux-opt \
  && mv cvc4-1.8-x86_64-linux-opt cvc4 \
  && chmod +x cvc4

ENV PATH=/cvc4-solver:$PATH

# (3) boolector
RUN git clone https://github.com/boolector/boolector \
  && cd boolector \
  && ./contrib/setup-lingeling.sh \
  && ./contrib/setup-btor2tools.sh \
  && ./configure.sh && cd build && make

ENV PATH=/boolector/build/bin:$PATH

CMD ["/bin/bash"]
