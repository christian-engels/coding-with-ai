# Load Libraries
library(tidyverse)
library(tidyfinance)
library(tsibble)
library(fable)
library(feasts)
library(scales)

# Download Apple Stock Data
aapl <-
  download_data(
    "stock_prices",
    symbols = "AAPL",
    start = "2010-01-01",
    end = "2020-01-01"
  )
aapl %>% glimpse()

# Prepare Closing Price Data
closing_price <-
  aapl %>%
  rename(price = adjusted_close) %>%
  select(symbol, date, price) %>%
  as_tsibble(index = date, regular = FALSE) %>%
  glimpse()

# Calculate Logarithmic Returns
log_returns <-
  closing_price %>%
  mutate(
    lprice = log(price),
    lreturn = difference(lprice, lag = 1, differences = 1)
  ) %>%
  glimpse()

# Visualize Prices and Returns
# Price Over Time
log_returns %>% autoplot(.vars = price)

# Log Price Over Time
log_returns %>% autoplot(.vars = lprice)

# Log Returns Over Time
log_returns %>% autoplot(.vars = lreturn)

# Quantile Analysis
quantile_05 <-
  quantile(
    log_returns %>%
      remove_missing() %>%
      pull(lreturn),
    probs = 0.05
  )
quantile_05

# Plot Distribution of Daily Returns
log_returns %>%
  ggplot(aes(x = lreturn)) +
  geom_histogram(bins = 100) +
  geom_vline(aes(xintercept = quantile_05),
    linetype = "dashed"
  ) +
  labs(
    x = NULL,
    y = NULL,
    title = "Distribution of daily Apple stock returns"
  ) +
  scale_x_continuous(labels = percent)

# Aggregate Weekly Log Returns
log_returns_weekly <-
  log_returns %>%
  index_by(yearweek = ~ yearweek(.)) %>%
  summarise(lreturn = sum(lreturn)) %>%
  glimpse()

log_returns_weekly %>% autoplot()

# Aggregate Monthly Log Returns
log_returns_monthly <-
  log_returns %>%
  index_by(yearmonth = ~ yearmonth(.)) %>%
  summarise(lreturn = sum(lreturn)) %>%
  glimpse()

log_returns_monthly %>% autoplot()
