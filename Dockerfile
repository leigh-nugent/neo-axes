# https://jtreminio.com/blog/running-docker-containers-as-current-host-user/
FROM rocker/geospatial:3.6.3
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    imagemagick \
    jq \
    python3-venv \
    python3-pip \
    moreutils
ENV RENV_VERSION 0.12.2
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_github('rstudio/renv@${RENV_VERSION}')"
COPY --chown=rstudio:rstudio . /home/rstudio/neo-axes
WORKDIR /home/rstudio/neo-axes
RUN make .venv && chown -R rstudio:rstudio .venv
USER rstudio
RUN R -e "renv::consent(provided = TRUE)"
RUN R -e "renv::restore()"
