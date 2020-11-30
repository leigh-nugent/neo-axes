FROM rocker/geospatial:4.0.3
RUN /rocker_scripts/install_python.sh
RUN apt-get update \
  && apt-get install -y --no-install-recommends \
    imagemagick \
    jq \
    moreutils
ENV RENV_VERSION 0.12.3
RUN R -e "install.packages('remotes', repos = c(CRAN = 'https://cloud.r-project.org'))"
RUN R -e "remotes::install_version('renv', '${RENV_VERSION}')"
WORKDIR /home/rstudio/neo-axes
COPY . .
RUN tlmgr install $(cat tlmgr_installed | tr '\n' ' ')
RUN make clean \
  && make venv \
  && touch -r requirements.txt venv venv/bin/activate
RUN chown -R rstudio:rstudio .
