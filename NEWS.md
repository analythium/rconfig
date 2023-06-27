# Version 0.3.0

* Variable splitting did not consider the separator on the right hand side, now fixed.
* Added new function `read_ini` to read INI configuration files.

# Version 0.2.0

* Added functionality to substitute variables (#8).
* Nicer formatting for markdown code blocks (#10 by @eitsupi).

# Version 0.1.5

* Update date field (The Date field is over a month old).

# Version 0.1.4

* `value()` by default coerces the config value to the same storage type as the default value when the default value is not `NULL`.

# Version 0.1.3

* Empty flag is invalid and throws an error (#3).
* Allow verb arguments for sub-commands with a `command()` method to access these from within the scripts (#4).

# Version 0.1.2

* Added `value()` method (#2).

# Version 0.1.1

* Added `LICENSE.md` with explicit MIT text and `LICENSE` with 2 lines only.

# Version 0.1.0

* First (failed) CRAN submission.
