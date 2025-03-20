############################################################
#   Week 7: Working with Data (Python script translated from R)
#   Original Author: Dr Christian Engels
#   University of St Andrews Business School
#
#   This script demonstrates using pandas and related libraries
#   to wrangle and tidy data.
############################################################

# ----------------------------------------------------------
#   0. Installation & Library Load
# ----------------------------------------------------------

# Install required packages if needed (uncomment if required)
# !pip install pandas numpy matplotlib seaborn

from datetime import date, timedelta

import matplotlib.pyplot as plt
import numpy as np
# Import libraries
import pandas as pd
import seaborn as sns

# Load datasets
starwars = pd.read_csv('../data/starwars.csv')
flights = pd.read_csv('../data/flights.csv')
planes = pd.read_csv('../data/planes.csv')
billboard = pd.read_csv('../data/billboard.csv')

# Display starwars dataset
print(starwars)

# ----------------------------------------------------------
#   1. Introduction to Tidy Data
# ----------------------------------------------------------
# A quick reminder on "tidy" data:
# 1) Each variable in its own column.
# 2) Each observation in its own row.
# 3) Each observational unit in its own table.


# ----------------------------------------------------------
#   2. pandas basics (equivalent to dplyr)
# ----------------------------------------------------------
# The main five operations:
#   filter/query() - subset rows
#   sort_values() - reorder rows
#   select columns - subset columns
#   assign()/transform - create/transform columns
#   groupby().agg() - collapse rows with summary

# 2.1 Filter (equivalent to filter in dplyr)
humans_tall = starwars.query('species == "Human" and height >= 190')
print(humans_tall)

# Filtering for missing values
missing_height = starwars[starwars['height'].isna()]
print(missing_height)

# Removing missing values
not_missing_height = starwars[~starwars['height'].isna()]
print(not_missing_height)


# 2.2 Sort (equivalent to arrange in dplyr)
sorted_by_birth = starwars.sort_values('birth_year')  # ascending
print(sorted_by_birth.head())

sorted_desc_birth = starwars.sort_values('birth_year', ascending=False)  # descending
print(sorted_desc_birth.head())


# 2.3 Select columns
# Subset specific columns by name
# In R: starwars %>% select(name:skin_color, species, -height)
selected_cols = starwars.loc[:, ['name', 'height', 'mass', 'hair_color', 'skin_color', 'species']].drop(columns=['height'])
print(selected_cols.head())

# Renaming columns in the same step
renamed_subset = starwars[['name', 'homeworld', 'gender']].rename(
    columns={'name': 'alias', 'homeworld': 'crib', 'gender': 'sex'}
)
print(renamed_subset.head())

# Just renaming (without subsetting)
renamed_all = starwars.rename(
    columns={'name': 'alias', 'homeworld': 'crib', 'gender': 'sex'}
)
print(renamed_all.head())


# 2.4 Mutate (creating new columns)
# Creating new columns
birth_years = starwars[['name', 'birth_year']].copy()
birth_years['dog_years'] = birth_years['birth_year'] * 7
birth_years['comment'] = birth_years['name'] + " is " + birth_years['dog_years'].astype(str) + " in dog years."
print(birth_years.head())

# Using logicals and numpy.where (equivalent to ifelse)
skywalkers = starwars[starwars['name'].isin(['Luke Skywalker', 'Anakin Skywalker'])][['name', 'height']].copy()
skywalkers['tall1'] = skywalkers['height'] > 180
skywalkers['tall2'] = np.where(skywalkers['height'] > 180, 'Tall', 'Short')
print(skywalkers)

# Apply same function across multiple columns
char_cols = starwars.select_dtypes(include='object').columns
upper_chars = starwars.copy()
for col in char_cols:
    upper_chars[col] = upper_chars[col].str.upper()
print(upper_chars[['name', 'hair_color', 'skin_color', 'eye_color']].head(5))


# 2.5 Summarize (equivalent to summarise with group_by)
# Group by and aggregate
height_by_species_gender = starwars.groupby(['species', 'gender'])['height'].mean().reset_index()
print(height_by_species_gender.head())

# Mean of height (automatically ignoring NAs)
mean_height_with_na = starwars['height'].mean()
print(f"Mean height with NAs: {mean_height_with_na}")

# Summarize and apply across multiple numeric columns
numeric_cols = starwars.select_dtypes(include=np.number).columns
summary_by_species = starwars.groupby('species')[numeric_cols].mean()
print(summary_by_species.head())

# Quick practice:
human_birth_by_homeworld = (
    starwars[starwars['species'] == 'Human']
    .groupby('homeworld')['birth_year']
    .mean()
    .reset_index()
)
print(human_birth_by_homeworld)


# ----------------------------------------------------------
#   3. Combining Data Frames
# ----------------------------------------------------------

# 3.1 Appending (equivalent to bind_rows)
df1 = pd.DataFrame({'x': range(1, 4), 'y': range(4, 7)})
df2 = pd.DataFrame({
    'x': range(1, 5), 
    'y': range(10, 14), 
    'z': list('abcd')
})

combined = pd.concat([df1, df2], ignore_index=True)
print(combined)


# 3.2 Joins
# Rename planes['year'] to avoid confusion
planes_renamed = planes.rename(columns={'year': 'year_built'})

# Perform left join (equivalent to left_join in dplyr)
joined_data = flights.merge(
    planes_renamed,
    on='tailnum',
    how='left'
)

# Keep only certain columns to see results clearly
selected_joined = joined_data[['year', 'month', 'day', 'dep_time', 'arr_time', 
                              'carrier', 'flight', 'tailnum', 'year_built', 
                              'type', 'model']]
print(selected_joined.head(3))


# ----------------------------------------------------------
#   4. Pandas Reshaping (equivalent to tidyr)
# ----------------------------------------------------------

# 4.1 melt (equivalent to pivot_longer)
stocks = pd.DataFrame({
    'time': [date(2009, 1, 1) + timedelta(days=i) for i in range(2)],
    'X': np.random.normal(0, 1, 2),
    'Y': np.random.normal(0, 2, 2),
    'Z': np.random.normal(0, 4, 2)
})

print(stocks)
tidy_stocks = stocks.melt(
    id_vars=['time'],
    var_name='stock',
    value_name='price'
)
print(tidy_stocks)

# 4.2 pivot (equivalent to pivot_wider)
# Reversing melt operation
stocks_restored = tidy_stocks.pivot(
    index='time',
    columns='stock',
    values='price'
).reset_index()
print(stocks_restored)

stocks_by_date = tidy_stocks.pivot(
    index='stock',
    columns='time',
    values='price'
).reset_index()
print(stocks_by_date)


# 4.3 Real-world example: billboard data
# First, identify columns that start with 'wk'
week_cols = [col for col in billboard.columns if col.startswith('wk')]

# melt the data
billboard_long = billboard.melt(
    id_vars=[col for col in billboard.columns if col not in week_cols],
    value_vars=week_cols,
    var_name='week',
    value_name='rank'
)

# Clean up the 'week' column
billboard_long['week'] = billboard_long['week'].str.replace('wk', '').astype(int)
print(billboard_long.head())


# ----------------------------------------------------------
#   5. Other pandas utilities (equivalent to tidyr utilities)
# ----------------------------------------------------------
# - str.split(), str.cat(), fillna(), dropna(), explode(), etc.

# Example of separating a column (equivalent to separate)
# df['col1'], df['col2'] = zip(*df['combined'].str.split('-').tolist())

# Example of uniting columns (equivalent to unite)
# df['combined'] = df['col1'].str.cat(df['col2'], sep='-')


# ----------------------------------------------------------
#   6. End of Script
# ----------------------------------------------------------

print("All done! The demonstrations from the slides have now been executed.")