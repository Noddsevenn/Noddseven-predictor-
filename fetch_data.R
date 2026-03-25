library(worldfootballR)
library(googlesheets4)
library(dplyr)
library(tidyr)

gs4_auth(path = NULL, email = "noddseven-robot@noddseven-predictor.iam.gserviceaccount.com")

sheet_id <- "1-F_mFs3sdZa-_qd7pX9Sudu0cZuUoXGNta24qmX3ass"

leagues <- c("ENG-Premier League", "ESP-La Liga", "ITA-Serie A", "GER-Bundesliga", "FRA-Ligue 1", "TUR-Super Lig", "NED-Eredivisie")
seasons <- c("2023/2024", "2024/2025")

all_matches <- list()

for(league in leagues) {
  for(season in seasons) {
    cat("Fetching", league, season, "\n")
    tryCatch({
      matches <- fb_match_results(country = strsplit(league, "-")[[1]][1], 
                                 gender = "M", 
                                 season_end_year = as.numeric(substr(season, 6, 9)))
      if(!is.null(matches) && nrow(matches) > 0) {
        all_matches[[length(all_matches)+1]] <- matches
      }
    }, error = function(e) {
      cat("Error fetching", league, season, ":", e$message, "\n")
    })
  }
}

combined_matches <- bind_rows(all_matches)
combined_matches <- combined_matches %>% distinct()

existing <- read_sheet(sheet_id, sheet = "DATABASE")

new_matches <- combined_matches %>% 
  anti_join(existing, by = c("Date", "Home", "Away"))

if(nrow(new_matches) > 0) {
  sheet_append(sheet_id, new_matches, sheet = "DATABASE")
  cat("Added", nrow(new_matches), "new matches\n")
} else {
  cat("No new matches found\n")
}
