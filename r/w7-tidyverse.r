############################################################
#   Week 7: Working with Data (R script from slides)
#   Author: Dr Christian Engels
#   University of St Andrews Business School
#
#   This script demonstrates using the tidyverse (dplyr, tidyr)
#   to wrangle and tidy data.
############################################################

# ----------------------------------------------------------
#   0. Installation & Library Load
# ----------------------------------------------------------

# Install if needed (uncomment lines if required)
# install.packages("tidyverse")
# install.packages("nycflights13")
# install.packages("pacman")

# Load libraries
if (!require(pacman)) {
  install.packages("pacman", repos = "https://cran.rstudio.com")
}
pacman::p_load(tidyverse, nycflights13)


# ----------------------------------------------------------
#   1. Introduction to Tidy Data
# ----------------------------------------------------------
# A quick reminder on "tidy" data:
# 1) Each variable in its own column.
# 2) Each observation in its own row.
# 3) Each observational unit in its own table.

# The starwars data set (from dplyr) is used for practice:
starwars


# ----------------------------------------------------------
#   2. dplyr basics
# ----------------------------------------------------------
# The main five verbs:
#   filter()   - subset rows
#   arrange()  - reorder rows
#   select()   - subset columns
#   mutate()   - create/transform columns
#   summarise() (with group_by()) - collapse rows with summary

# 2.1 filter
starwars %>%
  filter(species == "Human", height >= 190)

# Filtering for missing values
starwars %>%
  filter(is.na(height))

# Removing missing values (negation !)
starwars %>%
  filter(!is.na(height))


# 2.2 arrange
starwars %>%
  arrange(birth_year) # ascending

starwars %>%
  arrange(desc(birth_year)) # descending


# 2.3 select
# Subset specific columns by name
starwars %>%
  select(name:skin_color, species, -height) %>%
  head()

# Renaming columns in the same step
starwars %>%
  select(alias = name, crib = homeworld, sex = gender) %>%
  head()

# Just renaming (without subsetting)
starwars %>%
  rename(alias = name, crib = homeworld, sex = gender) %>%
  head()


# 2.4 mutate
# Creating new columns
starwars %>%
  select(name, birth_year) %>%
  mutate(dog_years = birth_year * 7) %>%
  mutate(comment = paste0(name, " is ", dog_years, " in dog years.")) %>%
  head()

# Using logicals and ifelse()
starwars %>%
  select(name, height) %>%
  filter(name %in% c("Luke Skywalker", "Anakin Skywalker")) %>%
  mutate(tall1 = height > 180) %>%
  mutate(tall2 = ifelse(height > 180, "Tall", "Short"))


# mutate + across (applying same function across multiple columns)
starwars %>%
  select(name:eye_color) %>%
  mutate(across(where(is.character), toupper)) %>%
  head(5)


# 2.5 summarise
# Summaries often go hand-in-hand with group_by
starwars %>%
  group_by(species, gender) %>%
  summarise(mean_height = mean(height, na.rm = TRUE)) %>%
  head()

# Danger of ignoring NA
starwars %>%
  summarise(mean_height = mean(height))

# With na.rm = TRUE
starwars %>%
  summarise(mean_height = mean(height, na.rm = TRUE))

# summarise and across
starwars %>%
  group_by(species) %>%
  summarise(across(where(is.numeric), ~ mean(.x, na.rm = TRUE))) %>%
  head()


# Quick practice (uncomment to test):
# starwars %>%
#   filter(species == "Human") %>%
#   group_by(homeworld) %>%
#   summarise(avg_birth = mean(birth_year, na.rm = TRUE))

# ----------------------------------------------------------
#   3. Combining Data Frames
# ----------------------------------------------------------

# 3.1 Appending (bind_rows)
df1 <- data.frame(x = 1:3, y = 4:6)
df2 <- data.frame(x = 1:4, y = 10:13, z = letters[1:4])

bind_rows(df1, df2)


# 3.2 Joins
# Use by= to specify join columns, or rely on matching names.
# We'll use nycflights13 for demonstration.

head(flights)
head(planes)

# Example of a left join
# (Planes has year = year built, flights has year = flight year)
# We'll rename planes$year to avoid confusion

joined_data <- left_join(
  flights,
  planes %>% rename(year_built = year),
  by = "tailnum" # join on tailnum
)

# Keep only certain columns to see results clearly:
joined_data %>%
  select(
    year,
    month,
    day,
    dep_time,
    arr_time,
    carrier,
    flight,
    tailnum,
    year_built,
    type,
    model
  ) %>%
  head(3)


# ----------------------------------------------------------
#   4. tidyr Basics
# ----------------------------------------------------------
# pivot_longer, pivot_wider, etc.

# 4.1 pivot_longer
stocks <- data.frame(
  time = as.Date("2009-01-01") + 0:1,
  X = rnorm(2, 0, 1),
  Y = rnorm(2, 0, 2),
  Z = rnorm(2, 0, 4)
)

stocks
tidy_stocks <- stocks %>%
  pivot_longer(cols = -time, names_to = "stock", values_to = "price")
tidy_stocks

# 4.2 pivot_wider
# Reversing pivot_longer
tidy_stocks %>%
  pivot_wider(names_from = stock, values_from = price)

tidy_stocks %>%
  pivot_wider(names_from = time, values_from = price)


# 4.3 Real-world example: billboard data
billboard
billboard_long <- billboard %>%
  pivot_longer(
    cols = starts_with("wk"),
    names_to = "week",
    values_to = "rank",
    names_prefix = "wk" # remove the prefix "wk"
  ) %>%
  mutate(week = as.numeric(week))

head(billboard_long)


# ----------------------------------------------------------
#   5. Other tidyr utilities
# ----------------------------------------------------------
# - separate(), unite(), fill(), drop_na(), expand(), nest(), unnest()
# Check ?tidyr for details and usage

# Example: separate a column into two
# Suppose we have "A-B" in a col, we can separate into "A" and "B"
# df %>% separate(col, into = c("A", "B"), sep = "-")

# Example: unite two columns with a separator
# df %>% unite("col_name", c(A, B), sep = "-")

# ----------------------------------------------------------
#   6. End of Script
# ----------------------------------------------------------

message("All done! The demonstrations from the slides have now been executed.")
