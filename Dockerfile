# https://jtreminio.com/blog/running-docker-containers-as-current-host-user/
FROM rocker/geospatial:4.0.3
RUN /rocker_scripts/install_python.sh
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    imagemagick \
    jq \
    moreutils
ENV RENV_VERSION 0.12.2
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"
WORKDIR /project
COPY . .
RUN make .venv
