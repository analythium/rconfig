FROM rocker/r-bspm:20.04
RUN apt update -y && apt upgrade -y && apt install -y libxml2-dev && install.r languageserver httpgd plumber rlog rconfig
