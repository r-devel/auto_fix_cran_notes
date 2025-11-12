library(tools)
library(dplyr)
library(stringr)

# get check information and identify packages with Rd files NOTE

details <- tools::CRAN_check_details(flavors = "r-devel-linux-x86_64-debian-gcc")
Rd_NOTE <- subset(details, Check == "Rd files" & Status == "NOTE")

pdb <- CRAN_package_db()
Rd_NOTE <- merge(Rd_NOTE, pdb)

# restrict "Lost braces" and packages that use GitHub to report issues
TODO <- Rd_NOTE[grepl("^http?s://(github.com|gitlab.com|bitbucket.org).*issues",
                      Rd_NOTE$BugReports),]

# Find packages with "Lost braces" in the Rd NOTE
Rd_NOTE_lb <- TODO[grep("Lost braces", TODO$Output),]

revdeps <- strsplit(Rd_NOTE_lb$`Reverse depends`, ",")
n_revdeps <- lengths(revdeps)
n_revdeps[is.na(revdeps)] <- 0

get_note_strings <- function(note_details) {
  # Split the note details by 'checkRd:' and return the parts after the first
  strings <- strsplit(note_details, 'checkRd: \\(-1\\)')
  lapply(strings, function(s) s[-1])
}

notes <- get_note_strings(Rd_NOTE_lb$Output)

notes_per_package <- sapply(notes, length)



# Some simple pattern matching to classify the errors
cat_note <- function(note) {
  itemize <- str_detect(note, pattern = "\\\\itemize; meant \\\\describe \\?")
  itemize_value <- str_detect(note, "\\\\itemize; \\\\value handles \\\\item\\{\\}\\{\\} directly")
  missing_escapes <- str_detect(note, "missing escapes or markup\\?")
  escaped_latex_specials <- str_detect(note, "Escaped LaTeX specials")
  enumerate <- str_detect(note, "\\\\enumerate; meant \\\\describe \\?")
  enumerate_value <- str_detect(note, "\\\\enumerate; \\\\value handles \\\\item\\{\\}\\{\\} directly")
  # Many notes simply state Lost braces and then show the context. On inspection
  # these often look like missing escapes
  no_suggestion <- str_detect(note, "Lost braces\\n")
  out <- character(length(note))
  out[itemize] <- "itemize"
  out[itemize_value] <- "itemize_value"
  out[missing_escapes] <- "missing_escapes"
  out[escaped_latex_specials] <- "escaped_latex_specials"
  out[enumerate] <- "enumerate"
  out[enumerate_value] <- "enumerate_value"
  out[no_suggestion] <- "no_suggestion"
  out[!(itemize | itemize_value | missing_escapes | escaped_latex_specials | enumerate | enumerate_value | no_suggestion)] <- "other"
  return(out)
}


notes_df <- tibble(
  Package = rep(Rd_NOTE_lb$Package, times = notes_per_package),
  note = trimws(unlist(notes))
) %>%
  mutate(file_name = stringr::str_extract(note, pattern = regex(".*\\.Rd")),
         line_numbers = stringr::str_extract(note, pattern = regex("(?<=:)[0-9]+(-[0-9]+)?")),
         note_category = cat_note(note))

# Counts of different note categories
notes_df %>%
  group_by(note_category) %>%
  summarise(n = n())

# Info on specific package
notes_df %>%
  filter(Package == "EHR") %>%
  select(Package, file_name, line_numbers, note_category, note)

# Packages by number of notes
notes_df %>%
  group_by(Package) %>%
  summarise(n = n()) %>%
  arrange(-n)

notes_df %>%
  group_by(Package, note_category) %>%
  summarise(n())





