library(httr2)
library(jsonlite)
library(gitcreds)

# Get GitHub token stored with gitcreds_set()
cred <- gitcreds::gitcreds_get()
if (is.null(cred$password)) {
  stop("No GitHub PAT found in git credentials!")
}
token <- cred$password

# Define owner, repo, issue number
owner <- "r-devel"
repo <- "r-dev-day"
issue_number <- 110

# GraphQL query
query <- sprintf(
  '
{
  repository(owner: "%s", name: "%s") {
    issue(number: %d) {
      comments(first: 100) {
        nodes { body }
      }
      timelineItems(first: 100, itemTypes: CROSS_REFERENCED_EVENT) {
        nodes {
          ... on CrossReferencedEvent {
            source {
              __typename
              ... on PullRequest { url title author { login } }
            }
          }
        }
      }
    }
  }
}',
  owner,
  repo,
  issue_number
)

# Send request via httr2
res <- request("https://api.github.com/graphql") |>
  req_headers(
    "Authorization" = paste("Bearer", token),
    "Content-Type" = "application/json"
  ) |>
  req_body_json(list(query = query)) |>
  req_perform() |>
  resp_body_json(simplifyVector = TRUE)

# Get PRs mentioned in the comments
comments <- res[[1]]$repository$issue$comments$nodes$body
pattern <- "https://github\\.com/[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+/pull/\\d+"
pr1 <- unlist(regmatches(comments, gregexpr(pattern, comments)))

# Get PRs that reference this issue
pr2 <- subset(
  res[[1]]$repository$issue$timelineItems$nodes$source,
  `__typename` == "PullRequest"
)$url
prs <- unique(sort(c(pr1, pr2)))

# Get GitHub repos and usernames to query
str_remove(prs, "https://github.com") |> str_split("/")

pr_df <- data.frame(
  url = prs,
  owner = str_remove(prs, "https://github.com") |>
    str_split("/") |>
    sapply(function(x) x[2]),
  repo = str_remove(prs, "https://github.com") |>
    str_split("/") |>
    sapply(function(x) x[3]),
  pr_number = str_remove(prs, "https://github.com") |>
    str_split("/") |>
    sapply(function(x) x[5])
)

# Get PR details for each PR
pr_details <- lapply(1:nrow(pr_df), function(i) {
  pr_url <- sprintf(
    "https://api.github.com/repos/%s/%s/pulls/%s",
    pr_df$owner[i],
    pr_df$repo[i],
    pr_df$pr_number[i]
  )
  res <- request(pr_url) |>
    req_headers(
      "Authorization" = paste("Bearer", token),
      "Content-Type" = "application/json"
    ) |>
    req_perform() |>
    resp_body_json(simplifyVector = TRUE)
  data.frame(
    url = pr_url,
    title = res$title,
    author = res$user$login,
    state = res$state,
    created_at = res$created_at,
    merged_at = (if (is.null(res$merged_at)) {
      NA
    } else {
      res$merged_at
    }),
    stringsAsFactors = FALSE
  )
}) |>
  unlist() |>
  do.call(rbind, .)

#Compare this list to the Google Sheets
library(googlesheets4)
sheet_url <- "https://docs.google.com/spreadsheets/d/1qL5s2okfQmh_ufwh3MS6rJPzIlLmJzIN2g9u2loFzkA/edit?gid=1451772479#gid=1451772479"
google_sheet <- googlesheets4::read_sheet(sheet_url)

google_sheet$PR_update <- NA


j <- 0
for (i in google_sheet$URL) {
  if (i %in% repo_names) {
    google_sheet$PR_update[google_sheet$URL == i] <- "Program update"
  }
}
