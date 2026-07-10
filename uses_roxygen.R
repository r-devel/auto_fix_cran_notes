# Find packages that use roxygen2 (taking DESCRIPTION from CRAN online)
pkg_uses_roxygen_cran <- function(pkgname) {
  pkg_desc_url <- paste0(
    "https://cran.r-project.org/web/packages/",
    pkgname,
    "/DESCRIPTION"
  )
  DESC_roxygen <- read.dcf(
    url(pkg_desc_url),
    fields = c("RoxygenNote", "Config/roxygen2/version")
  )
  !all(is.na(DESC_roxygen))
}

# `path` to local package source root
pkg_uses_roxygen_local <- function(path) {
  DESC_roxygen <- read.dcf(
    file.path(path, "DESCRIPTION"),
    fields = c("RoxygenNote", "Config/roxygen2/version")
  )
  !all(is.na(DESC_roxygen))
}
