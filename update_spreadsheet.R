library(googlesheets4)
library(tools)
library(dplyr)
library(stringr)

details <- tools::CRAN_check_details(
  flavors = "r-devel-linux-x86_64-debian-gcc"
)
Rd_NOTE <- subset(details, Check == "Rd files" & Status == "NOTE")

pdb <- CRAN_package_db()
Rd_NOTE <- merge(Rd_NOTE, pdb)

# restrict "Lost braces" and packages that use GitHub to report issues
TODO <- Rd_NOTE[
  grepl(
    "^http?s://(github.com|gitlab.com|bitbucket.org).*issues",
    Rd_NOTE$BugReports
  ),
]

# Find packages with "Lost braces" in the Rd NOTE
Rd_NOTE_lb <- TODO[grep("Lost braces", TODO$Output), ]

revdeps <- strsplit(Rd_NOTE_lb$`Reverse depends`, ",")
n_revdeps <- lengths(revdeps)
n_revdeps[is.na(revdeps)] <- 0

get_note_strings <- function(note_details) {
  # Split the note details by 'checkRd:' and return the parts after the first
  strings <- strsplit(note_details, 'checkRd: \\(-1\\)')
  lapply(strings, function(s) s[-1])
}

notes <- get_note_strings(Rd_NOTE_lb$Output)

# CRAN info for GoogleSheet
from_CRAN <- Rd_NOTE_lb |>
  select(Package, Version, Maintainer, Output, URL, BugReports)

# Additional info for GoogleSheet
# Latest_CRAN_status_lb - Not pure CRAN status, but in relation to lost braces
# Can get this from seeing which packages in current_sheet are in from_CRAN (NOTE if there, FIXED if not)
# downloads_last_month
# keep priority_per_TODO_reverse_dependency_number
# PR_Status to be updated by GitHub API
# Version and Output should also be programmatically updated

# Comparing current GoogleSheet with latest from CRAN

# PLAN: update current_sheet in R, then overwrite in GoogleSheets

# read in sheet
# TODO: column spec (avoid mutate, and deal with Version)
current_sheet <- read_sheet(
  "https://docs.google.com/spreadsheets/d/1qL5s2okfQmh_ufwh3MS6rJPzIlLmJzIN2g9u2loFzkA/edit?gid=1451772479#gid=1451772479"
) |>
  mutate(
    priority_per_TODO_reverse_dependency_number = as.integer(
      priority_per_TODO_reverse_dependency_number
    ),
    downloads_last_month = as.integer(downloads_last_month)
  )

# This works, e.g. amapGeocode is still here, even though fixed in CRAN,
# because it has a PR_status
# Hmm, aLFQ is gone, but archived on CRAN, rather than fixed
current_sheet |>
  filter_out((Package %notin% from_CRAN$Package) & is.na(PR_status))

# TODO: for remaining packages, if Version is the same, no more to do
# if Version is different, need to update

# Packages with new NOTEs
add_to_sheet <- from_CRAN |>
  filter(Package %notin% current_sheet$Package)

# TODO: For packages that are not in from_CRAN but do have a PR_status in current_sheet,
# set Latest_CRAN_status_lb to FIXED. Otherwise, set to NOTE.
# BUT, some packages are archived, so maybe, set to has_lb_CRAN_NOTE, as logical

t1 <- tibble(a = 1, b = 2, c = 3)
t2 <- tibble(a = 4, c = 5)
bind_rows(t1, t2)

# Current hack:
# Look at spreadsheet
browseURL(
  "https://docs.google.com/spreadsheets/d/1qL5s2okfQmh_ufwh3MS6rJPzIlLmJzIN2g9u2loFzkA/edit?gid=1451772479#gid=1451772479"
)
# Find package without PR_status with highest downloads
# Check if there is still a problem
from_CRAN |>
  filter(Package == "RNeXML")
# Send PR if so
# Update spreadsheet
