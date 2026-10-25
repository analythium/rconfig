# Read INI Files

Read INI (`.ini` file extension) configuration files.

## Usage

``` r
read_ini(file, eval = NULL, ...)
```

## Arguments

- file:

  The name and path of the INI configuration file.

- eval:

  Logical, whether to evaluate `!expr` expressions. If `NULL`, use the
  `R_RCONFIG_EVAL` environment variable or `"rconfig.eval"` option.

- ...:

  Other arguments passed to the function (currently there is none).

## Value

The configuration value a named list, each element of the list being a
section of the INI file. Each element (section) containing the key-value
pairs from the INI file. When no value is provided in the file, the
value is `""`. Literal values are returned as character vectors. R
expressions following `!expr` are evaluated according to the settings of
the `R_RCONFIG_EVAL` environment variable or the option
`"rconfig.eval"`; their results retain the expression's type.

## Details

An INI configuration file consists of sections, each led by a
`[section]` header, followed by key/value entries separated by a
specific string (`=` or `:` by default). By default, section names are
case sensitive but keys are not. Leading and trailing whitespace is
removed from keys and values. Values can be omitted if the parser is
configured to allow it, in which case the key/value delimiter may also
be left out. Values can also span multiple lines, as long as they are
indented deeper than the first line of the value. Blank lines may be
treated as parts of multiline values or ignored. By default, a valid
section name can be any string that does not contain `\n` or `]`.
Configuration files may include comments, prefixed by specific
characters (`#` and `;` by default). Comments may appear on their own on
an otherwise empty line, possibly indented.

## Examples

``` r
inifile <- system.file("examples", "example.ini", package = "rconfig")

## not evaluating R expressions
ini <- rconfig::read_ini(file = inifile, eval = FALSE)
str(ini)
#> List of 7
#>  $ Simple Values           :List of 5
#>   ..$ key                        : chr "value"
#>   ..$ spaces in keys             : chr "allowed"
#>   ..$ spaces in values           : chr "allowed as well"
#>   ..$ spaces around the delimiter: chr "obviously"
#>   ..$ you can also use           : chr "to delimit keys from values"
#>  $ All Values Are Strings  :List of 5
#>   ..$ values like this                                : chr "1000000"
#>   ..$ or this                                         : chr "3.14159265359"
#>   ..$ are they treated as numbers?                    : chr "no"
#>   ..$ integers, floats and booleans are held as       : chr "strings"
#>   ..$ can use the API to get converted values directly: chr "true"
#>  $ Multiline Values        :List of 1
#>   ..$ chorus: chr [1:2] "I'm a lumberjack, and I'm okay" "I sleep all night and I work all day"
#>  $ No Values               :List of 2
#>   ..$ key_without_value      : chr ""
#>   ..$ empty string value here: chr ""
#>  $ You can use comments    : list()
#>  $ Sections Can Be Indented:List of 4
#>   ..$ can_values_be_as_well          : chr "True"
#>   ..$ does_that_mean_anything_special: chr "False"
#>   ..$ purpose                        : chr "formatting for readability"
#>   ..$ multiline_values               : chr [1:5] "are" "handled just fine as" "long as they are indented" "deeper than the first line" ...
#>  $ R specific pieces       :List of 4
#>   ..$ trials : chr "5"
#>   ..$ pi     : chr "3.14"
#>   ..$ dataset: chr "demo-data.csv"
#>   ..$ cores  : chr "!expr getOption(\"mc.cores\", 1L)"

## evaluating R expressions
ini <- rconfig::read_ini(file = inifile, eval = TRUE)
str(ini)
#> List of 7
#>  $ Simple Values           :List of 5
#>   ..$ key                        : chr "value"
#>   ..$ spaces in keys             : chr "allowed"
#>   ..$ spaces in values           : chr "allowed as well"
#>   ..$ spaces around the delimiter: chr "obviously"
#>   ..$ you can also use           : chr "to delimit keys from values"
#>  $ All Values Are Strings  :List of 5
#>   ..$ values like this                                : chr "1000000"
#>   ..$ or this                                         : chr "3.14159265359"
#>   ..$ are they treated as numbers?                    : chr "no"
#>   ..$ integers, floats and booleans are held as       : chr "strings"
#>   ..$ can use the API to get converted values directly: chr "true"
#>  $ Multiline Values        :List of 1
#>   ..$ chorus: chr [1:2] "I'm a lumberjack, and I'm okay" "I sleep all night and I work all day"
#>  $ No Values               :List of 2
#>   ..$ key_without_value      : chr ""
#>   ..$ empty string value here: chr ""
#>  $ You can use comments    : list()
#>  $ Sections Can Be Indented:List of 4
#>   ..$ can_values_be_as_well          : chr "True"
#>   ..$ does_that_mean_anything_special: chr "False"
#>   ..$ purpose                        : chr "formatting for readability"
#>   ..$ multiline_values               : chr [1:5] "are" "handled just fine as" "long as they are indented" "deeper than the first line" ...
#>  $ R specific pieces       :List of 4
#>   ..$ trials : chr "5"
#>   ..$ pi     : chr "3.14"
#>   ..$ dataset: chr "demo-data.csv"
#>   ..$ cores  : int 1
```
