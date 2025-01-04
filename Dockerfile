FROM python:3.12-slim AS dev-builder

ENV PIP_DISABLE_PIP_VERSION_CHECK=1 \
    POETRY_NO_INTERACTION=1 \
    POETRY_CACHE_DIR=/tmp/poetry_cache \
    POETRY_VIRTUALENVS_CREATE=1 \
    POETRY_VIRTUALENVS_IN_PROJECT=1\
    VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"\
    DEV_ENV=1

RUN --mount=type=cache,target=/root/.cache apt-get update \
    && apt-get install --no-install-recommends -y gcc gnupg2 python3-dev\
    && apt-get clean \
    && pip install --upgrade pip \
    && pip install poetry

WORKDIR /app
COPY pyproject.toml ./
RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --only main --no-ansi



# TARGET: PROD with src folders 
FROM python:3.12-slim AS prod
EXPOSE 8000
WORKDIR /app

ENV VIRTUAL_ENV=/app/.venv \
    PATH="/app/.venv/bin:$PATH"


COPY --from=dev-builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}
COPY ./src /app
CMD ["gunicorn", "curioz_project.wsgi"]

# TARGET: DEV ⚙️
FROM dev-builder AS dev
RUN --mount=type=cache,target=$POETRY_CACHE_DIR poetry install --only dev 
COPY ./src /app

EXPOSE 8000
VOLUME [ "/app" ]

VOLUME [ "/app" ]
CMD ["python3", "manage.py", "runserver", "0.0.0.0:8000"]