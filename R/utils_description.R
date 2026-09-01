# NOTE: don't do any of this! Use `read.dcf` for working with DESCRIPTION files.
#' Obtain Encoding from DESCRIPTION file
#'
#' @param package Data frame with package metadata or string with package name.
#'
#' @returns Package Encoding.
#' @export
#'
#' @examples
#' description_encoding("tools")
#' description_encoding("dplyr")
# description_encoding <- function(package) {
#   if ("data.frame" %in% class(package)) {
#     getElement(package, "Encoding")
#   } else if ("character" %in% class(package)) {
#     return(.description_encoding.character(package))
#   } else {
#     stop("Unrecognised class for the given `package`")
#   }
# }

#' Get element from DESCRIPTION file
#'
#' @param description DESCRIPTION file contents.
#' @param label String with label in the DESCRIPTION content.
#'
#' @returns Value from the DESCRIPTION file.
#' @keywords internal
# .description_element <- function(description, label) {
#   description |>
#     stringr::str_subset(paste0("^", label, ":")) |>
#     stringr::str_remove_all(paste0("^", label, ":")) |>
#     stringr::str_squish()
# }

# .description_encoding.character <- function(package) {
#   encoding <- NULL
#   if (dir.exists(package)) {
#     encoding <- readLines(file.path(package, "DESCRIPTION")) |>
#       .description_element("Encoding")
#   } else {
#     # attempt downloading package's DESCRIPTION file
#     encoding <- tools::CRAN_package_db() |>
#       subset(Package == package) |>
#       getElement("Encoding")
#   }
#   if (length(encoding) == 0) {
#     encoding <- NULL
#   }
#   return(encoding)
# }
