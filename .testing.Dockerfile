# 
ARG R_VER=${R_VER:-rocker/r-base}
FROM ${R_VER}
RUN apt update -y && apt upgrade -y && apt install -y pandoc
RUN install.r yaml jsonlite
COPY . ./rconfig
RUN R CMD build rconfig
# RUN R CMD check --as-cran rconfig_*.tar.gz

# docker build --build-arg R_VER=rocker/r-base -t crancheck -f .testing.Dockerfile --progress=plain .
# docker run -it --rm crancheck bash
# R CMD check --as-cran --no-manual rconfig_*.tar.gz
