FROM rocker/r-ver:4.3.2

WORKDIR /app

COPY . /app

RUN apt-get update && apt-get install -y libcurl4-openssl-dev libssl-dev libxml2-dev && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c('tidyverse','lubridate','httr','jsonlite','dotenv','randomForest','cluster','corrplot'), repos='https://cloud.r-project.org')"

CMD ["Rscript", "scripts/01_acquire.R"]
