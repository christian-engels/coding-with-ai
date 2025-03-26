# Load necessary libraries
library(tidyverse) # For data manipulation and visualization
library(fixest) # For fixed effects and instrumental variable regressions

# Set a seed for reproducibility
set.seed(42)

# Define the true value of beta (coefficient for x1)
true_beta <- 0.95

# Define correlations between variables
corr_x1_x2 <- -0.1 # Correlation between x1 and x2
corr_x1_z <- 0.25 # Correlation between x1 and the instrument z
corr_x1_e <- 0 # Correlation between x1 and the error term e
corr_x2_z <- 0 # Correlation between x2 and the instrument z
corr_x2_e <- 0 # Correlation between x2 and the error term e
corr_z_e <- 0 # Correlation between the instrument z and the error term e

# Define the number of observations
obs <- 1000

# Define the mean vector for the multivariate normal distribution
mean_vector <- c(0, 0, 0, 0)

# Define the covariance matrix based on the correlations
covariance_matrix <-
  matrix(
    c(
      # row x1
      1,
      corr_x1_x2,
      corr_x1_z,
      corr_x1_e,
      # row x2
      corr_x1_x2,
      1,
      corr_x2_z,
      corr_x2_e,
      # row z
      corr_x1_z,
      corr_x2_e,
      1,
      corr_z_e,
      # row e
      corr_x1_e,
      corr_x2_e,
      corr_z_e,
      1
    ),
    nrow = 4,
    byrow = TRUE # Fill the matrix by rows
  )

# Function to generate the full dataset
generate_full_data <- function(obs, true_beta, mean_vector, covariance_matrix) {
  # Generate data from a multivariate normal distribution
  out <- MASS::mvrnorm(
    n = obs, # Number of observations
    mu = mean_vector, # Mean vector
    Sigma = covariance_matrix # Covariance matrix
  ) %>%
    as_tibble(.name_repair = "minimal") %>% # Convert to tibble (modern data frame)
    setNames(c("x1", "x2", "z", "e")) %>% # Set column names
    mutate(y = 0.5 + true_beta * x1 + 0.5 * x2 + e, .before = x1) # Create the dependent variable y
  out
}

# Generate the initial dataset
df <- generate_full_data(obs, true_beta, mean_vector, covariance_matrix)

# Configure fixest for conventional significance stars in etable output
setFixest_etable(
  style.df = style.df(
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10) # Define significance levels
  ),
  se.below = TRUE # Display standard errors below coefficients
)

# Estimate and display OLS regressions
feols(y ~ x1 + x2, data = df) %>% etable() # OLS with x1 and x2
feols(y ~ x1, data = df) %>% etable() # OLS with only x1

# Estimate and display 2SLS (IV) regression
feols(y ~ 1 | x1 ~ z, data = df) %>% # 2SLS: y regressed on x1, instrumented by z
  etable(stage = 1:2, fitstat = c("ivfall", "ivwaldall", "cd", "kpr")) # Display results for both stages and relevant statistics

# Function to perform one iteration of the simulation
get_one_iteration <- function(iteration) {
  # Generate a new dataset for this iteration
  df <- generate_full_data(obs, true_beta, mean_vector, covariance_matrix)

  # Estimate OLS and IV regressions
  est_ols <- feols(y ~ x1, data = df) # OLS with x1
  est_iv <- feols(y ~ 1 | x1 ~ z, data = df) # 2SLS with x1 instrumented by z

  # Extract coefficients and store them in a tibble
  out <-
    tibble::tibble(
      iter = iteration, # Iteration number
      ols = coef(est_ols, keep = "x1"), # OLS coefficient for x1
      iv = coef(est_iv, keep = "fit_x1") # IV coefficient for x1 (called fit_x1 in fixest)
    )

  out
}

# Run one iteration of the simulation (for testing)
get_one_iteration(1)

# Run the simulation 1000 times and store the results
results <- list_rbind(map(seq_len(10^3), get_one_iteration))

# Display a glimpse of the results
results %>% glimpse()

# Generate descriptive statistics of the results
skimr::skim(results)

# Visualize the distribution of the OLS and IV estimates
results %>%
  pivot_longer(c(iv, ols), names_to = "estimator", values_to = "estimate") %>% # Reshape data for plotting
  ggplot(aes(x = estimate, color = estimator)) + # Create a plot
  geom_density() + # Add density plots for OLS and IV estimates
  geom_vline(xintercept = true_beta, linetype = "dashed") + # Add a vertical line at the true beta value
  theme_minimal() # Use a minimal theme for the plot
