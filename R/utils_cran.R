#' List packages on CRAN with documentation notes
#'
#' @returns Data frame with list of packages and associated metadata
#' @export
list_packages_with_notes <- function() {
  # code source: https://github.com/r-devel/r-dev-day/issues/110
  # get check information and identify packages with Rd files NOTE
  details <- tools::CRAN_check_details(flavors = "r-devel-linux-x86_64-debian-gcc")
  Rd_NOTE <- subset(details, Check == "Rd files" & Status == "NOTE")
  # merge in package info (lose a few that we don't have info for)
  pdb <- tools::CRAN_package_db()
  Rd_NOTE <- merge(Rd_NOTE, pdb)
  # restrict "Lost braces" and packages that use GitHub to report issues
  public_repo_regex <- "https?://(www.)?(github.com|gitlab.com|bitbucket.org|.*github[.]io/)"
  Rd_NOTE |>
    subset(
      (grepl(public_repo_regex, BugReports) | grepl(public_repo_regex, URL))
      # & grepl("Lost braces", Output, fixed = TRUE)
    )
}

#' List notes for a given package
#'
#' @param package Either a row from `list_packages_with_notes()` or a path to a
#'     package (notes will be generated with `tools::checkRd()`)
#'
#' @returns Data frame with metadata for each note, including: Rd file name,
#'     line number, category (e.g., Lost braces') and note details
#' @export
#'
#' @examples
#' list_packages_with_notes() |>
#'   dplyr::slice(1) |>
#'   list_notes()
list_notes <- function(package) {
  if ("data.frame" %in% class(package)) {
    return(.list_notes.data.frame(package))
  } else if ("character" %in% class(package)) {
    return(.list_notes.character(package))
  } else {
    stop("Unrecognised class for the given `package`")
  }
}

.list_notes.character <- function(package) {

}

.list_notes.data.frame <- function(package) {
  package |>
    purrr::pmap(function(Output, ...) {
      message(Output)
      Output |>
        stringr::str_split(pattern = "[\n]*checkRd:", simplify = TRUE) |>
        stringr::str_subset(pattern = ".+") |>
        # split into Rd filename, line number, note
        purrr::map(function(string) {
          aux <- stringr::str_split(string, , pattern = ":", n = 3)
          note_details <- stringr::str_split(aux[[1]][3], pattern = "\n", n = 2)
          # tibble::as_tibble(aux[[1]],.name_repair = "minimal")
          tibble::tibble(
            rd_file = aux[[1]][1] |>
              stringr::str_remove_all("^[\\(\\)\\d-\\s]*"),
            line_number = as.numeric(aux[[1]][2]),
            category = stringr::str_squish(note_details[[1]][1]),
            note = note_details[[1]][2]
          )
        }) |>
        purrr::list_c()
    })
}
