#
# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.
#
ARG ALPINE_VERSION=20260805

FROM alpine:${ALPINE_VERSION} AS build-stage

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/venv/bin:$PATH"

WORKDIR /app

RUN apk update && apk upgrade && apk add --no-cache python3 py3-pip py3-virtualenv
RUN python3 -m venv /app/venv
COPY requirements.txt .
RUN pip install -r requirements.txt

## -----------------------------------------------------
FROM alpine:${ALPINE_VERSION} AS runtime-stage

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PATH="/app/venv/bin:$PATH"

WORKDIR /app
RUN apk update && apk upgrade && apk add --no-cache bash python3 curl jq
COPY --from=build-stage /app/venv /app/venv
RUN rm -Rf /app/venv/lib/python*/site-packages/pip-* && \
    rm -Rf /app/venv/lib/python*/site-packages/pip && \
    rm -Rf /app/venv/lib/python*/site-packages/setuptools-* && \
    rm -Rf /app/venv/lib/python*/site-packages/wheel-*

CMD ["/app/venv/bin/polaris", "-h"]
