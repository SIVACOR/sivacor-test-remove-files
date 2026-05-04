# Load necessary libraries
library(httr)
library(jsonlite)
library(dplyr)
library(ggplot2)
library(readr)
library(lubridate)

# 1. Read the API key from environment variables
apikey <- Sys.getenv("FRED_APIKEY")

# Safety check: Stop if the API key isn't set
if (apikey == "") {
  stop("Environment variable 'FRED_APIKEY' not found. Please set it before running.")
}

# 2. Create directories if they don't exist
paths <- c("data", "results")
for (path in paths) {
  if (!dir.exists(path)) {
    dir.create(path)
  }
}

# 3. Define parameters and URL
series <- "SP500"
start  <- "2019-01-01"
end    <- "2024-01-01"

url <- paste0(
  "https://api.stlouisfed.org/fred/series/observations?",
  "series_id=", series,
  "&api_key=", apikey,
  "&observation_start=", start,
  "&observation_end=", end,
  "&file_type=json"
)

# 4. API Request
r <- GET(url)
stop_for_status(r)

# 5. Parse JSON and Save
json_data <- content(r, as = "parsed", type = "application/json")
write_json(json_data, "data/sp500.json", pretty = TRUE, auto_unbox = TRUE)

# 6. Convert to DataFrame and Clean
df <- as_tibble(do.call(rbind, lapply(json_data$observations, as.data.frame)))

df <- df %>%
  select(-realtime_start, -realtime_end) %>%
  filter(value != ".") %>%
  mutate(
    date = as.Date(date),
    value = as.numeric(value)
  )

# 7. Save to CSV
write_csv(df, "data/sp500.csv")

# 8. Plot and Save
p <- ggplot(df, aes(x = date, y = value)) +
  geom_line(color = "steelblue") +
  labs(
    title = "S&P 500 (2019-2024)",
    x = "Date",
    y = "Index Value"
  ) +
  theme_minimal()

ggsave("results/sp500.png", plot = p, width = 8, height = 5)
