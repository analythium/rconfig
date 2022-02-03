# rconfig

> Manage R Configuration at the Command Line

```bash
Rscript --vanilla index.R --some.value 22

R_CONFIG_ACTIVE=production Rscript --vanilla index.R --some.value 22

R_CONFIG_ACTIVE=production Rscript --vanilla index.R --test --some.value 22 --another.value abc def --another.stuff 99

```


R_RCONFIG_FILE

R_RCONFIG_EVAL (eval.expr yaml.eval.expr option)

R_RCONFIG_SEP separator for txt file parser (=)



Sys.setenv("R_RCONFIG_EVAL"="FALSE")
options("rconfig.eval"=TRUE)
do_eval()
Sys.unsetenv("R_RCONFIG_EVAL"="")
options("rconfig.eval"=NULL)


Sys.setenv("R_RCONFIG_SEP"=":")
options("rconfig.sep"="~")
txt_sep()
Sys.unsetenv("R_RCONFIG_SEP")
options("rconfig.sep"=NULL)
