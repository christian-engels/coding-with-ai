# Load Libraries
library(tidyverse)
library(tidyfinance)
library(tsibble)
library(fable)

# Download Data
fred <- download_data("fred", series = c("GDP", "CPIAUCNS"))

# View Data
View(fred)
fred %>% View()

# Summary of Data
fred %>% glimpse()

# Filter CPIAUCNS Series
fred_cpi <- fred %>% filter(series == "CPIAUCNS")

# Summary Statistics for CPIAUCNS
fred_cpi_summary <-
  fred_cpi %>%
  summarise(
    date_min = min(date),
    date_max = max(date),
    value_mean = mean(value)
  )

# Summary for All Series
fred_summary <-
  fred %>%
  group_by(series) %>%
  summarise(
    date_min = min(date),
    date_max = max(date),
    value_mean = mean(value)
  )

# Yearly Mean Value
fred_yearly_mean <-
  fred %>%
  group_by(series, year = year(date)) %>%
  summarise(value_mean = mean(value))

# Pivot Yearly Mean Data
fred_pivot <-
  fred_yearly_mean %>%
  pivot_wider(
    id_cols = year,
    names_from = series,
    values_from = value_mean
  )

# Summarize and Reshape Yearly Data
fred_yearly <-
  fred_yearly_mean %>%
  pivot_wider(
    id_cols = year,
    names_from = series,
    values_from = value_mean
  ) %>%
  remove_missing()

# Inspect GDP Data
df_gdp <-
  fred_yearly %>%
  select(year, GDP) %>%
  glimpse()

# Plot GDP Over Time
df_gdp %>%
  as_tsibble(index = year) %>%
  autoplot(.vars = GDP)

# Logarithmic GDP Analysis
df_gdp %>%
  as_tsibble(index = year) %>%
  mutate(log_GDP = log(GDP)) %>%
  autoplot(.vars = log_GDP)
