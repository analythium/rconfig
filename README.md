# rconfig

> Manage R Configuration at the Command Line

[![Build
status](https://github.com/analythium/rconfig/actions/workflows/check.yml/badge.svg)](https://github.com/analythium/rconfig/actions)
[![CRAN
version](http://www.r-pkg.org/badges/version/rconfig)](https://CRAN.R-project.org/package=rconfig)
[![CRAN RStudio mirror
downloads](http://cranlogs.r-pkg.org/badges/grand-total/rconfig)](https://hub.analythium.io/rconfig/)

Manage R configuration using files (YAML, JSON, INI, TXT) JSON strings
and command line arguments. Command line arguments can be used to
override configuration. Period-separated command line flags are parsed
as hierarchical lists. Environment variables, R global variables, and
configuration values can be substituted.

*Try rconfig in your browser: click the Gitpod button, then
`cd inst/examples` in the VS Code terminal to run the `Rscript` example
from this README!*

[![Open in
Gitpod](https://gitpod.io/button/open-in-gitpod.svg)](https://gitpod.io/#https://github.com/analythium/rconfig)

- [Install](#install)
- [Another config package?](#another-config-package)
- [Usage](#usage)
  - [R command line usage](#r-command-line-usage)
  - [Variable substitution](#variable-substitution)
  - [Using with Rscript](#using-with-rscript)
  - [Shiny](#shiny)
  - [Plumber](#plumber)
- [License](#license)

## Install

``` r
# CRAN version
install.packages("rconfig")

# Development version from R-universe
install.packages("rconfig", repos = "https://analythium.r-universe.dev")
```

## Another config package?

There are other R packages to manage configs:

- [config](https://rstudio.github.io/config/) has nice inheritance
  rules, and it even scans parent directories for YAML config files
- [configr](https://CRAN.R-project.org/package=configr) has nice
  substitution/interpolation features and supports YAML, JSON, TOML, and
  INI file formats

These package are fantastic if you are managing deployments at different
stages of the life cycle, i.e. testing/staging/production.

However, when you use `Rscript` from the command line, you often do not
want to manage too many configuration files, but want a quick way to
override some of the default settings.

The rconfig package provides various ways to override defaults, and
instead of changing the active configuration (as in the config package),
you can merge lists in order to arrive at a final configuration. These
are very similar concepts, but not quite the same.

The rconfig package has the following features:

- uses default configuration file
- file based override with the `-f` or `--file` flags (accepts JSON,
  YAML, INI, and plain text files)
- JSON string based override with the `-j` or `--json` flags
- other command line arguments are merged too, e.g. `--cores 4`
- heuristic rules are used to coerce command line values to the right
  type
- R expressions starting with `!expr` are evaluated by default, this
  behavior can be turned off (same feature can be found in the yaml and
  config packages, but here it works with plain text and JSON too)
- period-separated command line arguments are parsed as hierarchical
  lists, e.g. `--user.name Joe` will be added as `user$name` to the
  config list
- nested configurations can also be flattened
- command line flags without a value will evaluate to `TRUE`,
  e.g. `--verbose`
- environment variables (`${VALUE}`), R global variables (`@{VALUE}`),
  and configuration values (`#{VALUE}`) can be substituted
- differentiates verb/noun syntax, where verbs are sub-commands
  following the R script file name and preceding the command line flags
  (starting with `-` or `--`)

This looks very similar to what
[littler](https://CRAN.R-project.org/package=littler),
[getopt](https://CRAN.R-project.org/package=getopt), and
[optparse](https://CRAN.R-project.org/package=optparse) are supposed to
do. You are right. These packages offer amazing command line experience
once you have a solid interface. In an iterative and evolving research
and development situation, however, rconfig gives you agility.

Moreover, the rconfig package offers various ways for substituting
environment variables, R global variables, and even substituting
configuration values. The
[GetoptLong](https://CRAN.R-project.org/package=GetoptLong/vignettes/variable_interpolation.html)
package has similar functionality but its focus is on command line
interfaces and not configuration. Other tools, such as `sprintf`,
[glue](https://CRAN.R-project.org/package=glue),
[rprintf](https://CRAN.R-project.org/package=rprintf), and
[whiskers](https://CRAN.R-project.org/package=whisker) are aimed at
substituting values from R expressions.

If you are not yet convinced, here is a quick teaser. This is the
content of the default configuration file, `rconfig.yml`:

``` yaml
trials: 5
dataset: "demo-data.csv"
cores: !expr getOption("mc.cores", 1L)
user:
  name: "demo"
description: |
  This is a multi line
  description.
```

Let’s use a simple R script to print out the configs:

``` r
#!/usr/bin/env Rscript
options("rconfig.debug"=TRUE)
str(rconfig::rconfig())
```

Now you can override the default configuration using another file, a
JSON string, and some other flags. Notice the variable substitution for
user name!

``` bash
export USER=Jane

Rscript --vanilla test.R deploy \
  -f rconfig-prod.yml \
  -j '{"trials":30,"dataset":"full-data.csv"}' \
  --user.name $USER \
  --verbose
# List of 6
#  $ trials     : int 30
#  $ dataset    : chr "full-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "Jane"
#  $ description: chr "This is a multi line\ndescription."
#  $ verbose    : logi TRUE
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 4
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig-prod.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "json"
#   .. .. ..$ value: chr "{\"trials\":30,\"dataset\":\"full-data.csv\"}"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "deploy --user.name Jane --verbose"
#  - attr(*, "command")= chr "deploy"
#  - attr(*, "class")= chr "rconfig"
```

The package was inspired by the config package,
docker-compose/kubectl/caddy and other CLI tools, and was motivated by
some real world need when managing background processing on cloud
instances.

## Usage

### R command line usage

Open the project in RStudio or set the work directory to the folder root
after cloning/downloading the repository.

``` r
str(rconfig::rconfig())
# List of 5
#  $ trials     : int 5
#  $ dataset    : chr "demo-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "demo"
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"

str(rconfig::rconfig(
    file = "rconfig-prod.yml"))
# List of 5
#  $ trials     : int 30
#  $ dataset    : chr "full-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "real_We4$#z*="
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"

str(rconfig::rconfig(
    file = c("rconfig.json",
             "rconfig-prod.txt"),
    list = list(user = list(name = "Jack"))))
# List of 5
#  $ trials     : int 30
#  $ dataset    : chr "full-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "Jack"
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"

str(rconfig::rconfig(
    file = c("rconfig.json",
             "rconfig-prod.txt"),
    list = list(user = list(name = "Jack")),
    flatten = TRUE))
# List of 5
#  $ trials     : int 30
#  $ dataset    : chr "full-data.csv"
#  $ cores      : int 1
#  $ user.name  : chr "Jack"
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

Set defaults in case some values are undefined:

``` r
CONFIG <- rconfig::rconfig(
    file = "rconfig-prod.yml")

rconfig::value(CONFIG$cores, 2L)   # set to 1L
# [1] 1
rconfig::value(CONFIG$test)        # unset
# NULL
rconfig::value(CONFIG$test, FALSE) # use default
# [1] FALSE
```

The default values are used to ensure type safety:

``` r
str(rconfig::value(CONFIG$trials, 0L))    # integer
#  int 30
str(rconfig::value(CONFIG$trials, 0))     # numeric
#  num 30
str(rconfig::value(CONFIG$trials, "0"))   # character
#  chr "30"
str(rconfig::value(CONFIG$trials, FALSE)) # logical
#  logi TRUE
```

Using alongside of the config package:

``` r
conf <- config::get(
    config = "production",
    file = "config.yml",
    use_parent = FALSE)

str(rconfig::rconfig(
    file = "rconfig.yml",
    list = conf))
# List of 5
#  $ trials     : int 30
#  $ dataset    : chr "data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "demo"
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

### Variable substitution

The rconfig package interprets 3 kinds of substitution patterns:

- environment variables (`${VALUE}`): these variables are already
  present when the configurations is read from the calling environment
  or from `.Renviron` file in the project specific or home folder, set
  variables can be null or not-null
- R global variables (`@{VALUE}`): the rconfig package looks for
  variables in the global environment at the time of configuration
  evaluation, however, expressions are not evaluated (unlike the `!expr`
  option for values)
- configuration values (`#{VALUE}`): the configuration level variables
  are evaluated last, thus these values can refer to existing keys that
  are already substituted

The substitution pattern can set defaults or error messages, following
[bash](https://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_06_02)
and [Docker](https://docs.docker.com/compose/environment-variables/)
conventions:

|           | `a` is set & not null | `a` set but null | `a` is unset   |
|-----------|-----------------------|------------------|----------------|
| `${a:-b}` | substitute `a`        | substitute `b`   | substitute `b` |
| `${a-b}`  | substitute `a`        | substitute null  | substitute `b` |
| `${a:?b}` | substitute `a`        | error, exit      | error, exit    |
| `${a?b}`  | substitute `a`        | substitute null  | error, exit    |

The following YAML example has all 3 kinds of variable substitution
pattern:

``` yaml
trials: 30
unset:
this-is-null: ""
env:
  dataset: "full-${DATA:-data}.csv"
  url: "https://www.${URL-example}.com"
  user:
    name: "${USER:?Define user name}"
    access: "${ACCESS?Define user access}"
conf:
  path: "#{env.url}/api/v1/"
  text: "User: #{env.user.name} (#{env.user.access})"
  lang: "#{renv.lang}"
renv:
  lang: "@{Lang:-EN}"
  type: "@{Type?Type must be set}"
```

Set the following variables:

``` r
Sys.setenv(USER="Adele")
Sys.setenv(ACCESS="admin")
Type <- "simple"
Lang <- "HU"
```

This is the substituted version:

``` yaml
trials: 30
this-is-null: ''
env:
  dataset: full-data.csv
  url: https://www.example.com
  user:
    name: Adele
    access: admin
conf:
  path: https://www.example.com/api/v1/
  text: 'User: Adele (admin)'
  lang: HU
renv:
  lang: HU
  type: simple
```

### Using with Rscript

Set the work directory to the `inst/examples` folder cloning/downloading
the repo.

Default config if found (the script has debug mode on):

``` bash
Rscript test.R
# List of 5
#  $ trials     : int 5
#  $ dataset    : chr "demo-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "demo"
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "file"
#   ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig.yml"
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

Default with debug mode off:

``` bash
R_RCONFIG_DEBUG="FALSE" Rscript test.R
# List of 5
#  $ trials     : int 5
#  $ dataset    : chr "demo-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "demo"
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

Change default config file:

``` bash
R_RCONFIG_FILE="rconfig-prod.yml" Rscript test.R
# List of 3
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ user   :List of 1
#   ..$ name: chr "real_We4$#z*="
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "file"
#   ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig-prod.yml"
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

Change default config file and debug off:

``` bash
R_RCONFIG_FILE="rconfig-prod.yml" R_RCONFIG_DEBUG="FALSE" Rscript test.R
# List of 3
#  $ trials : int 30
#  $ dataset: chr "full-data.csv"
#  $ user   :List of 1
#   ..$ name: chr "real_We4$#z*="
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

Use file and other props to override default:

``` bash
Rscript test.R -f rconfig-prod.yml --user.name "unreal_Zh5z*$#="
# List of 5
#  $ trials     : int 30
#  $ dataset    : chr "full-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "unreal_Zh5z*0="
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 3
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig-prod.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "--user.name unreal_Zh5z*0="
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

Use JSON string and other props to override default:

``` bash
Rscript test.R \
  -j '{"trials":30,"dataset":"full-data.csv","user":{"name": "real_We4$#z*="}}' \
  --user.name "unreal_Zh5z*$#="
# List of 5
#  $ trials     : int 30
#  $ dataset    : chr "full-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "unreal_Zh5z*0="
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 3
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "json"
#   .. .. ..$ value: chr "{\"trials\":30,\"dataset\":\"full-data.csv\",\"user\":{\"name\": \"real_We4$#z*=\"}}"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "--user.name unreal_Zh5z*0="
#  - attr(*, "command")= chr(0) 
#  - attr(*, "class")= chr "rconfig"
```

rconfig also interprets verb/noun syntax, where verbs are sub-commands
following the R script file name and preceding the command line flags
(starting with `-` or `--`):

``` bash
Rscript test.R deploy --user.name "unreal_Zh5z*$#="
# List of 5
#  $ trials     : int 5
#  $ dataset    : chr "demo-data.csv"
#  $ cores      : int 1
#  $ user       :List of 1
#   ..$ name: chr "unreal_Zh5z*0="
#  $ description: chr "This is a multi line\ndescription."
#  - attr(*, "trace")=List of 2
#   ..$ kind : chr "merged"
#   ..$ value:List of 2
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "file"
#   .. .. ..$ value: chr "/Users/Peter/git/github.com/analythium/rconfig/inst/examples/rconfig.yml"
#   .. ..$ :List of 2
#   .. .. ..$ kind : chr "args"
#   .. .. ..$ value: chr "deploy --user.name unreal_Zh5z*0="
#  - attr(*, "command")= chr "deploy"
#  - attr(*, "class")= chr "rconfig"
```

For a more realistic but still small example, let’s use the `iris` data
and get summaries by species using command line arguments:

``` bash
Rscript iris.R --species virginica
#   Sepal.Length    Sepal.Width     Petal.Length    Petal.Width   
#  Min.   :4.900   Min.   :2.200   Min.   :4.500   Min.   :1.400  
#  1st Qu.:6.225   1st Qu.:2.800   1st Qu.:5.100   1st Qu.:1.800  
#  Median :6.500   Median :3.000   Median :5.550   Median :2.000  
#  Mean   :6.588   Mean   :2.974   Mean   :5.552   Mean   :2.026  
#  3rd Qu.:6.900   3rd Qu.:3.175   3rd Qu.:5.875   3rd Qu.:2.300  
#  Max.   :7.900   Max.   :3.800   Max.   :6.900   Max.   :2.500
```

``` bash
Rscript iris.R --species setosa --verbose
# 2023-06-02 19:24:06 - Started
# Getting summaries for species setosa
#   Sepal.Length    Sepal.Width     Petal.Length    Petal.Width   
#  Min.   :4.300   Min.   :2.300   Min.   :1.000   Min.   :0.100  
#  1st Qu.:4.800   1st Qu.:3.200   1st Qu.:1.400   1st Qu.:0.200  
#  Median :5.000   Median :3.400   Median :1.500   Median :0.200  
#  Mean   :5.006   Mean   :3.428   Mean   :1.462   Mean   :0.246  
#  3rd Qu.:5.200   3rd Qu.:3.675   3rd Qu.:1.575   3rd Qu.:0.300  
#  Max.   :5.800   Max.   :4.400   Max.   :1.900   Max.   :0.600  
# 2023-06-02 19:24:06 - Done
```

``` bash
Rscript iris.R --species maxima --verbose
# 2023-06-02 19:24:06 - Started
# Error: Provide a valid species
# Execution halted
```

``` bash
Rscript iris.R
# Error: Species not provided
# Execution halted
```

Check out the [`iris_rlog.R`](inst/examples/iris_rlog.R) file to see an
example with proper logging.

Another illustration using the `mtcars` data set to fit linear models to
different variables:

``` bash
Rscript mtcars.R
# (Intercept)         cyl        disp          hp        drat          wt 
# 12.30337416 -0.11144048  0.01333524 -0.02148212  0.78711097 -3.71530393 
#        qsec          vs          am        gear        carb 
#  0.82104075  0.31776281  2.52022689  0.65541302 -0.19941925
```

``` bash
Rscript mtcars.R --verbose --vars cyl
# 2023-06-02 19:24:06 - Started
# (Intercept)         cyl 
#    37.88458    -2.87579 
# 2023-06-02 19:24:06 - Done
```

``` bash
Rscript mtcars.R --verbose --vars cal
# 2023-06-02 19:24:06 - Started
# Error: Not valid variable
# Execution halted
```

``` bash
Rscript mtcars.R --vars cyl disp hp
# (Intercept)         cyl        disp          hp 
# 34.18491917 -1.22741994 -0.01883809 -0.01467933
```

Let’s see how to use sub-commands:

``` bash
## This will print messages:
Rscript commands.R model

## This will not print messages:
Rscript commands.R model --silent
# Model ...
```

``` bash
Rscript commands.R predict
# Predict ...
```

``` bash
Rscript commands.R fit
# Error: Command fit not found.
# Execution halted
```

``` bash
Rscript commands.R
# Error: Specify a command.
# Execution halted
```

Here is how to make the R script executable on Linux (of course you’ll
need rconfig installed for this to work):

``` bash
sudo cp ./inst/examples/commands.R /usr/local/bin/
sudo chmod +x /usr/local/bin/commands.R
```

Make sure that the R script has the shebang (`#!/usr/bin/env Rscript`)
as the 1st line, and now can drop the `Rscript` part and use the script
as `commands.R model`.

### Shiny

An example to configure a [Shiny app](https://shiny.rstudio.com/) with
command line flags:

``` bash
Rscript shiny/app.R

Rscript shiny/app.R \
  --test \
  --value 1000 \
  --color 'pink' \
  --title 'Only Testing'
```

An example to configure a Shiny app using the
[golem](https://golemverse.org/) with command line flags:

``` r
# app.R
CONFIG <- rconfig()
yourpkg::run_app(
  title = value(CONFIG$title, "Hello Shiny!"),
  test = value(CONFIG$test, FALSE),
  color = value(CONFIG$color, "purple"),
  options = list(port = value(CONFIG$port, 8080)))
```

``` bash
## then in terminal
Rscript app.R \
  --test \
  --value 1000 \
  --color 'pink' \
  --title 'Only Testing' \
  --port 3838
```

### Plumber

An example to configure a [Plumber API](https://www.rplumber.io/) with
command line flags:

``` bash
cd plumber

Rscript index.R

# httr::POST("http://127.0.0.1:8080/echo?msg=Cool") |> httr::content()
# httr::GET("http://127.0.0.1:8080/test") |> httr::content()

Rscript index.R \
  --test \
  --port 8000 \
  --title 'The echoed message is'

# httr::POST("http://127.0.0.1:8000/echo?msg=Cool") |> httr::content()
# httr::GET("http://127.0.0.1:8000/test") |> httr::content()
```

## License

[MIT License](./LICENSE) © 2022 Peter Solymos and Analythium Solutions
Inc.
