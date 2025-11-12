# auto_fix_cran_notes

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
  TODO there may be more information in the rest of the note, on inspection these often look like missing escapes
- `other`: notes that do not fit into any of the above categories
