library(tidyverse) # For data manipulation and visualization
library(skimr) # For quick data summaries
library(panelView) # For visualizing panel data
library(fixest) # For fixed effects regressions

# Data: State-level health insurance coverage and Medicaid expansion status
# dins: % of low-income adults w/o children who have health insurance per state
# yexp2: year state expanded Medicaid under ACA (NA if never expanded)
# year: observation year
# stfips: unique state identifier code

data_file <- "data/ehec_data.dta" # Define the data file path

if (!file.exists(data_file)) {
  # Check if the data file exists
  download.file(
    # If not, download it from the specified URL
    "https://raw.githubusercontent.com/Mixtape-Sessions/Advanced-DID/main/Exercises/Data/ehec_data.dta", # nolintr
    destfile = data_file # Save the downloaded file to the specified path
  )
}

ehec_data <- haven::read_dta(data_file) # Read the data from the .dta file
ehec_data %>% skim() # Get a quick summary of the data
ehec_data %>% print() # Print the data to the console
ehec_data %>% count(yexp2) # Count the number of observations for each expansion year

df <- # Create a new data frame called df
  ehec_data %>% # Start with the ehec_data data frame
  glimpse() %>% # Print the structure of the data frame
  mutate(
    # Create new variables
    post = case_when(
      # Create a post-treatment indicator
      is.na(yexp2) ~ 0, # Never treated units: post = 0
      year >= yexp2 ~ 1, # Treated units in post-treatment period: post = 1
      year < yexp2 ~ 0 # Treated units in pre-treatment period: post = 0
    ),
    treat = ifelse(!is.na(yexp2), 1, 0), # Create a treatment indicator (1 if ever treated, 0 if never treated)
    post_treat = post * treat, # Create an interaction term between post and treat
    etime = year - yexp2 # Calculate the event time (years relative to treatment)
  ) %>%
  glimpse() # Print the structure of the updated data frame

# Plot treatment rollout
panelview(
  # Use the panelView function to visualize the treatment rollout
  data = df, # Specify the data frame
  formula = dins ~ post, # Specify the formula to plot
  index = c("stfips", "year"), # Specify the index variables (state and year)
  pre.post = FALSE, # Do not show pre/post treatment periods
  by.timing = TRUE # Show treatment adoption by timing
)

# Document how many units in each treated cohort
df %>% # Start with the df data frame
  count(yexp2) %>% # Count the number of observations for each expansion year
  rename(
    # Rename the columns
    year_of_treatment = yexp2, # Rename yexp2 to year_of_treatment
    count = n # Rename n to count
  ) %>%
  mutate(percent = 100 * count / sum(count)) # Calculate the percentage of units in each cohort

pl_event_study <- # Create a new plot called pl_event_study
  df %>% # Start with the df data frame
  filter(etime >= -4 & etime <= 3) %>% # Filter the data to include event times between -4 and 3
  ggplot(aes(
    # Create a ggplot object
    etime, # x-axis: event time
    dins # y-axis: insurance coverage
  )) +
  stat_summary() + # Add a summary statistic (mean)
  geom_vline(xintercept = 0, linetype = "dashed", color = "red") + # Add a vertical line at event time 0
  labs(
    # Add labels
    x = "Time to Treatment", # x-axis label
    y = "Insurance Coverage (%)" # y-axis label
  )

pl_event_study # Display the plot

pl_event_study_cohorts <- pl_event_study + facet_wrap(~yexp2) # Create a new plot with facets for each cohort
pl_event_study_cohorts # Display the plot

setFixest_etable(
  # Set the style for the etable function
  style.df = style.df(
    # Define the style
    signif.code = c("***" = 0.01, "**" = 0.05, "*" = 0.10) # Define the significance codes
  ),
  se.below = TRUE # Display standard errors below the coefficients
)

est_did_static <- feols(dins ~ post_treat | stfips + year, data = df) # Estimate a static difference-in-differences model
#dins ~ post_treat: regressing insurance coverage on the interaction between post-treatment and treatment status
#stfips + year: state and year fixed effects
est_did_static %>% etable() # Display the results

est_did_twfe <- feols(
  # Estimate a two-way fixed effects model
  dins ~ i(etime, ref = -1) | stfips + year, #dins regressed on event time, state fixed effects and year fixed effects
  data = df %>% mutate(etime = ifelse(is.na(etime), -100, etime)) # Use the df data frame, replacing missing etime values with -100
)
est_did_twfe %>% etable() # Display the results

iplot(
  # Create an event study plot
  est_did_twfe, # Use the est_did_twfe model
  xlim = c(-5, 2), # Set the x-axis limits
  ylim = c(-0.05, 0.10), # Set the y-axis limits
  ref.line = -0.5, # Add a horizontal reference line at -0.5
  ref = -1 # Set the reference category for event time to -1
)

est_did_sunab <- # Estimate a Sun & Abraham event study model
  feols(
    # Use the feols function
    dins ~ sunab(yexp2, etime, ref.p = c(.F, -1)) | stfips + year, #dins regressed on yexp2 and etime, state fixed effects and year fixed effects
    data = df %>% mutate(etime = ifelse(is.na(etime), -100, etime)) # Use the df data frame, replacing missing etime values with -100
  )

est_did_sunab %>% etable() # Display the results

iplot(
  # Create an event study plot
  est_did_sunab, # Use the est_did_sunab model
  xlim = c(-5, 2), # Set the x-axis limits
  ylim = c(-0.05, 0.10), # Set the y-axis limits
  ref.line = -0.5, # Add a horizontal reference line at -0.5
  ref = -1 # Set the reference category for event time to -1
)
