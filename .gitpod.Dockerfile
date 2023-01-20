FROM eddelbuettel/r2u:22.04
RUN apt update -y && apt upgrade -y && apt install -y libxml2-dev git
RUN install.r languageserver httpgd plumber shiny rlog remotes
RUN installGithub.r analythium/rconfig
