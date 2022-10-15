FROM quay.io/pypa/manylinux_2_28_x86_64 as main

ADD https://github.com/mozilla/sccache/releases/download/v0.3.0/sccache-v0.3.0-x86_64-unknown-linux-musl.tar.gz /
RUN tar xf /sccache-v0.3.0-x86_64-unknown-linux-musl.tar.gz \
 && chmod +x /sccache-v0.3.0-x86_64-unknown-linux-musl/sccache \
 && mv /sccache-v0.3.0-x86_64-unknown-linux-musl/sccache /usr/local/bin \
 && rm -rf /sccache-v0.3.0-x86_64-unknown-linux-musl

WORKDIR /src
ARG PYTHON=python3.10
ENV PYTHON=${PYTHON} URL="git+https://github.com/cmake-wheel"
RUN --mount=type=cache,target=/root/.cache ${PYTHON} -m pip install simple503

ENV SCCACHE_REDIS=redis://asahi CMAKE_C_COMPILER_LAUNCHER=sccache CMAKE_CXX_COMPILER_LAUNCHER=sccache
ENV CMEEL_TEMP_DIR=/ws CTEST_PARALLEL_LEVEL=6

FROM main as cmeel

ADD cmeel .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip wheel --extra-index-url file:///wh -w /wh .

FROM main as cmeel-example

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-example .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as eigen

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-eigen .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as boost

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-boost .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as eigenpy

COPY --from=eigen /wh /wh
COPY --from=boost /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD eigenpy .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-eigen \
    cmeel-boost \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as assimp

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-assimp .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as octomap

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-octomap .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as hpp-fcl

COPY --from=assimp /wh /wh
COPY --from=octomap /wh /wh
COPY --from=eigenpy /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD hpp-fcl .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-assimp \
    cmeel-eigen \
    cmeel-octomap \
    eigenpy \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as urdfdom-headers

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-urdfdom-headers .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .


FROM main as console-bridge

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-console-bridge .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as tinyxml

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-tinyxml .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as urdfdom

COPY --from=urdfdom-headers /wh /wh
COPY --from=tinyxml /wh /wh
COPY --from=console-bridge /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-urdfdom .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-urdfdom-headers \
    cmeel-tinyxml \
    cmeel-console-bridge \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as pinocchio

COPY --from=hpp-fcl /wh /wh
COPY --from=urdfdom /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD pinocchio .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-eigen \
    cmeel-console-bridge \
    cmeel-tinyxml \
    cmeel-urdfdom \
    cmeel-urdfdom-headers \
    hpp-fcl \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as example-robot-data

COPY --from=pinocchio /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
WORKDIR /example-robot-data
ADD example-robot-data .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-eigen \
    cmeel-urdfdom-headers \
    pin \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as eiquadprog

COPY --from=eigen /wh /wh
COPY --from=boost /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD eiquadprog .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-eigen \
    cmeel-boost \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as tsid

COPY --from=eiquadprog /wh /wh
COPY --from=pinocchio /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD tsid .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-urdfdom-headers \
    eiquadprog \
    pin \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as ndcurves

COPY --from=pinocchio /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD ndcurves .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-eigen \
    cmeel-urdfdom-headers \
    pin \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as cppad

COPY --from=cmeel /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD cmeel-cppad .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as pycppad

COPY --from=eigenpy /wh /wh
COPY --from=cppad /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD pycppad .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-cppad \
    cmeel-eigen \
    eigenpy \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as crocoddyl

COPY --from=example-robot-data /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh
ADD crocoddyl .
RUN --mount=type=cache,target=/root/.cache sccache -s \
 && ${PYTHON} -m pip install --extra-index-url file:///wh \
    cmeel-eigen \
    cmeel-urdfdom-headers \
    example-robot-data \
    scipy \
 && ${PYTHON} -m pip wheel --no-build-isolation --extra-index-url file:///wh -w /wh .

FROM main as wh

COPY --from=cmeel-example /wh /wh
COPY --from=example-robot-data /wh /wh
COPY --from=tsid /wh /wh
COPY --from=ndcurves /wh /wh
COPY --from=cppad /wh /wh
COPY --from=crocoddyl /wh /wh
RUN ${PYTHON} -m simple503 -B file:///wh /wh

FROM python:3.10

COPY --from=wh /wh /wh
ENV PYTHON=python
RUN --mount=type=cache,target=/root/.cache ${PYTHON} -m pip install --extra-index-url file:///wh \
    example-robot-data \
    ndcurves \
    tsid \
    crocoddyl
ADD meta/test.py .
RUN ${PYTHON} test.py
RUN assimp