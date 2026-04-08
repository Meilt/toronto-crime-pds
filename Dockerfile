FROM rocker/tidyverse:latest

WORKDIR /app

COPY . /app

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('jsonlite','dotenv','randomForest','cluster','corrplot'), repos='https://cloud.r-project.org')"

CMD ["Rscript", "scripts/01_acquire.R"]