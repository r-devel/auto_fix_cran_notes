# Auto-fix CRAN NOTES

## Background
The purpose of this repo is to work on the development of scripts/functions
to automatically fix CRAN NOTES related to documentation.

For example, the following is commonly used in documentation, but this results
in a NOTE:

```r
\itemize{
  \item{First}{This is the first item}
  \item{Second}{This is the second item}
  .
  .
  .
}
```

The above has (at least) two possible fixes:

1. Replace `\itemize` with `\describe`, the latter supports `\item` entries with
both a label and a description.

    ```r
    \describe{
      \item{First}{This is the first item}
      \item{Second}{This is the second item}
      .
      .
      .
    }
    ```

2. Update each `\item` to remove the 'label' portion: `\item{}{}` >> `\item{}`:

    ```r
    \itemize{
      \item{First: This is the first item}
      \item{Second: This is the second item}
      .
      .
      .
    }
    ```

More details about the CRAN NOTES can be found in the following issues:

- [r-devel/r-dev-day/issues/110](https://github.com/r-devel/r-dev-day/issues/110)
- [r-devel/r-dev-day/issues/131](https://github.com/r-devel/r-dev-day/issues/131)
- [r-devel/r-dev-day/issues/132](https://github.com/r-devel/r-dev-day/issues/132)

## Categorising Notes

`categorise_notes.R` is a quick attempt to categorise the notes returned by
`tools::CRAN_check_details`. It creates a dataframe with one row per note and columns
for the Package, file_name and line numbers the note refers to and
splits the notes into the following categories:

- `itemize`: notes that can be fixed by exchanging `\itemize{}` for `\describe` in the Rd file
- `enumerate`: notes that can be fixed by exchanging `\enumerate{}` for `\describe` in the Rd file
- `itemize_value`: notes specifying a different issue in `itemize{}` sections
- `enumerate_value`: notes specifying a different issue in `enumerate{}` sections
- `escaped_latex_specials`: notes about LaTeX special characters
- `missing_escapes`: notes about missing escapes. E.g. `code` should be `\code`
- `no_suggestion`: notes that do not offer an immediate clear suggestion for fixing them. 

  > **TODO** there may be more information in the rest of the note, on inspection these often look like missing escapes
- `other`: notes that do not fit into any of the above categories
