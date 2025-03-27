# EVENT STUDY SCRIPT
# This script performs an event study to analyze the impact of COVID  on S&P 500 stock returns.
# It downloads stock price data, estimates a market model, calculates abnormal returns,
# and performs a t-test to assess the significance of the cumulative abnormal returns.

# Load necessary libraries
library(tidyverse) # For data manipulation and visualization
library(tidyfinance) # For financial data analysis
library(fixest) # For regression models
library(rstatix) # For t-tests tests

# Download and prepare MSCI World index data
msci_world <-
  download_data(
    # Download data using tidyfinance package
    "stock_prices", # Specify data type as stock prices
    "XWD.TO", # Specify the stock symbol
    start_date = "2019-01-01", # Set start date
    end_date = "2025-03-01" # Set end date
  ) %>%
  mutate(
    # Create new variables
    log_adj_close = log(adjusted_close), # Calculate log of adjusted close price
    log_return_msci_world = log_adj_close - lag(log_adj_close) # Calculate log returns
  ) %>%
  remove_missing() %>% # Remove rows with missing values
  select(date, log_return_msci_world) %>% # Select relevant columns
  glimpse() # Display the structure of the data frame

# Download and prepare S&P 500 constituents data
sp500_constituents <-
  download_data(
    # Download data using tidyfinance package
    "constituents", # Specify data type as constituents
    index = "S&P 500" # Specify the index
  ) %>%
  mutate(location = "United States") %>% # Add a location column
  glimpse() # Display the structure of the data frame

# Download and prepare stock prices data for S&P 500 constituents
prices <-
  download_data(
    # Download data using tidyfinance package
    "stock_prices", # Specify data type as stock prices
    symbols = sp500_constituents %>% pull(symbol), # Specify stock symbols
    start_date = "2019-01-01", # Set start date
    end_date = "2025-03-01" # Set end date
  ) %>%
  glimpse() # Display the structure of the data frame

# Calculate stock returns and merge with MSCI World index returns
returns <-
  prices %>%
  inner_join(sp500_constituents, by = "symbol") %>% # Join with S&P 500 constituents data
  arrange(symbol, date) %>% # Sort by symbol and date
  group_by(symbol) %>% # Group by symbol
  mutate(
    # Create new variables
    log_adj_close = log(adjusted_close), # Calculate log of adjusted close price
    log_return = log_adj_close - lag(log_adj_close) # Calculate log returns
  ) %>%
  select(symbol, date, log_return) %>% # Select relevant columns
  left_join(msci_world, by = "date") %>% # Join with MSCI World index returns
  remove_missing(finite = TRUE) %>% # Remove rows with missing values
  glimpse() # Display the structure of the data frame

# Estimate the market model for each stock using data from 2019
model_estimation <-
  returns %>%
  filter(year(date) == 2019) %>% # Filter data for the year 2019
  group_by(symbol) %>% # Group by symbol
  nest() %>% # Create a nested data frame
  mutate(
    # Create a new variable
    est = map(data, ~ feols(log_return ~ log_return_msci_world, data = .x)) # Estimate the market model using fixest package
  ) %>%
  select(symbol, est) %>% # Select relevant columns
  glimpse() # Display the structure of the data frame

# Calculate abnormal returns
abnormal_returns <-
  returns %>%
  group_by(symbol) %>% # Group by symbol
  nest() %>% # Create a nested data frame
  left_join(model_estimation, by = "symbol") %>% # Join with model estimation results
  filter(!map_lgl(est, is.null)) %>% # Filter out stocks with missing model estimations
  mutate(expected_return = map2(est, data, ~ predict(.x, newdata = .y))) %>% # Predict expected returns using the estimated model
  select(symbol, data, expected_return) %>% # Select relevant columns
  unnest(cols = c(data, expected_return)) %>% # Unnest the data and expected return columns
  mutate(abnormal_return = log_return - expected_return) %>% # Calculate abnormal returns
  glimpse() # Display the structure of the data frame

# Calculate cumulative abnormal returns (CAR)
cumulative_abnormal_returns <-
  abnormal_returns %>%
  filter(between(date, ymd("2020-01-01"), ymd("2020-06-30"))) %>% # Filter data for the event window
  group_by(symbol) %>% # Group by symbol
  mutate(abnormal_return = if_else(row_number() == 1, 0, abnormal_return)) %>% # Set the first abnormal return to 0
  mutate(car = cumsum(abnormal_return)) %>% # Calculate cumulative abnormal returns
  ungroup() # Ungroup the data

# Plot cumulative abnormal returns
cumulative_abnormal_returns %>%
  ggplot(aes(date, car)) + # Create a ggplot object
  stat_summary(fun.y = mean, geom = "line") + # Plot the mean CAR over time as a line
  stat_summary(fun.y = mean, geom = "point") + # Plot the mean CAR over time as points
  geom_vline(
    # Add vertical lines to mark event dates
    xintercept = ymd("2020-01-30"), # Specify the x-intercept
    color = "blue", # Set the color
    linetype = "solid" # Set the line type
  ) +
  geom_vline(
    # Add vertical lines to mark event dates
    xintercept = ymd("2020-03-11"), # Specify the x-intercept
    color = "red", # Set the color
    linetype = "dashed" # Set the line type
  ) +
  scale_x_date(date_breaks = "1 month", date_labels = "%b") + # Format the x-axis
  scale_y_continuous(labels = scales::percent) + # Format the y-axis
  labs(
    # Add labels
    x = "Date", # Set the x-axis label
    y = NULL, # Set the y-axis label
    subtitle = "Cumulative Abnormal Returns" # Set the subtitle
  )

# Perform a t-test on the CARs
car_t_test <-
  cumulative_abnormal_returns %>%
  filter(between(date, ymd("2020-01-03"), ymd("2020-02-07"))) %>% # Filter data for the test period
  group_by(date) %>% # Group by date
  t_test(car ~ 1, detailed = TRUE) %>% # Perform a t-test
  adjust_pvalue(method = "bonferroni") %>% # Adjust p-values using Bonferroni correction
  add_significance(
    # Add significance symbols
    "p.adj", # Specify the p-value column
    cutpoints = c(0, 0.01, 0.05, 0.10, 1), # Specify the cutpoints
    symbols = c("***", "**", "*", "ns") # Specify the symbols
  ) %>%
  print(n = Inf) # Print the results
