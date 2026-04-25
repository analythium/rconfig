# Changelog

## Version 0.3.0

CRAN release: 2023-06-27

- Variable splitting did not consider the separator on the right hand
  side, now fixed.
- Added new function `read_ini` to read INI configuration files.

## Version 0.2.0

CRAN release: 2023-02-11

- Added functionality to substitute variables
  ([\#8](https://github.com/analythium/rconfig/issues/8)).
- Nicer formatting for markdown code blocks
  ([\#10](https://github.com/analythium/rconfig/issues/10) by
  [@eitsupi](https://github.com/eitsupi)).

## Version 0.1.5

CRAN release: 2022-11-02

- Update date field (The Date field is over a month old).

## Version 0.1.4

- [`value()`](https://hub.analythium.io/rconfig/reference/rconfig.md) by
  default coerces the config value to the same storage type as the
  default value when the default value is not `NULL`.

## Version 0.1.3

CRAN release: 2022-06-22

- Empty flag is invalid and throws an error
  ([\#3](https://github.com/analythium/rconfig/issues/3)).
- Allow verb arguments for sub-commands with a
  [`command()`](https://hub.analythium.io/rconfig/reference/rconfig.md)
  method to access these from within the scripts
  ([\#4](https://github.com/analythium/rconfig/issues/4)).

## Version 0.1.2

CRAN release: 2022-04-15

- Added
  [`value()`](https://hub.analythium.io/rconfig/reference/rconfig.md)
  method ([\#2](https://github.com/analythium/rconfig/issues/2)).

## Version 0.1.1

CRAN release: 2022-02-21

- Added `LICENSE.md` with explicit MIT text and `LICENSE` with 2 lines
  only.

## Version 0.1.0

- First (failed) CRAN submission.
