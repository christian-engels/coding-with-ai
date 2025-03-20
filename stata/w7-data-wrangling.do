/***************************************************************************
 Week 7: Working with Data (Stata version)
 Author: (Translated from Dr Christian Engels's R script)
 University of St Andrews Business School

 This script demonstrates using Stata to wrangle and tidy data,
 mirroring the examples from the R tidyverse (dplyr, tidyr).
***************************************************************************/

/*---------------------------------------------------------------------------
 0. Setup: Clear environment, set path
---------------------------------------------------------------------------*/
* clear all
cd ..   // Change to your working directory containing data/

// For reproducibility
set seed 12345

/***************************************************************************
 1. Introduction to Tidy Data
   We assume "starwars.csv" is stored in data/starwars.csv
***************************************************************************/

// Let’s load starwars
import delimited "data/starwars.csv", clear

// Quickly list the first few observations
list in 1/6, clean

/***************************************************************************
 2. Basic data wrangling in Stata (dplyr-like steps)
   filter => keep if
   arrange => sort or gsort
   select => keep or drop
   rename
   mutate => generate or replace
   group_by + summarise => collapse or by/egen
***************************************************************************/

//
// 2.1 filter()
//

/* Filter rows: keep only Humans >= 190 in height */
import delimited "data/starwars.csv", clear numericc(2 3 7)
list if species=="Human" & height >= 190, clean

/* Filter to see only rows where height is missing */
list if missing(height), clean

/* Remove (drop) missing height */
list if !missing(height), clean


//
// 2.2 arrange()
//

/* Ascending sort by birth_year */
import delimited "data/starwars.csv", clear numericc(2 3 7)
gsort +birth_year
list name birth_year in 1/10, clean

/* Descending sort by birth_year */
gsort -birth_year
list name birth_year in 1/10, clean

//
// 2.3 select()
//

// Suppose we want columns from name through skin_color, plus species,
// but exclude height
import delimited "data/starwars.csv", clear numericc(2 3 7)

// You can drop variables that you do not need.
// If starwars.csv includes the columns in the same order as the R version,
// you might do something like:
keep name hair_color skin_color species

// If you need to keep them by a range, you'll do something like
//   drop height
//   (since Stata doesn't support exactly "name:skin_color" syntax)
// Then verify the result:
desc

/* Renaming columns in Stata */
import delimited "data/starwars.csv", clear numericc(2 3 7)
rename name aka
rename homeworld crib
list aka crib in 1/6, clean

//
// 2.4 mutate()
//

// Creating new columns in Stata:
import delimited "data/starwars.csv", clear numericc(2 3 7)
keep name birth_year
generate dog_years = birth_year * 7

// Combining text from multiple columns
// Stata requires string concatenation. We'll convert dog_years to string.
tostring dog_years, format(%9.0g) force replace
generate strL comment = name + " is " +  dog_years + " in dog years."
list in 1/10, clean

/* Using if/else logic to classify 'height' */
import delimited "data/starwars.csv", clear numericc(2 3 7)
keep name height
// Example: keep only Luke Skywalker & Anakin Skywalker
keep if inlist(name, "Luke Skywalker", "Anakin Skywalker")

generate tall1 = (height > 180)  // will be 1 for > 180, 0 otherwise

generate str5 tall2 = ""
replace tall2 = "Tall" if height > 180
replace tall2 = "Short" if height <= 180 & !missing(height)

list

//
// 2.5 summarise() + group_by()
//

// One typical approach in Stata is to collapse data by groups
import delimited "data/starwars.csv", clear numericc(2 3 7)
collapse (mean) height, by(species gender)
rename height mean_height
list in 1/10, clean

// Another approach: by-group mean without collapsing:
import delimited "data/starwars.csv", clear numericc(2 3 7)
bysort species gender: egen mean_height = mean(height)
list species gender mean_height in 1/15, clean

/***************************************************************************
 3. Combining Data Frames (Appending & Joins)
***************************************************************************/

//
// 3.1 Appending (bind_rows => append)
//
clear
input x y
1 4
2 5
3 6
end
tempfile df1
save `df1', replace

clear
input x y z str1 letter
1 10 . "a"
2 11 . "b"
3 12 . "c"
4 13 . "d"
end
tempfile df2
save `df2', replace

// In Stata, appending is done via 'append using ...'
use `df1', clear
append using `df2'
list

//
// 3.2 Joins (left_join => merge)
// Using nycflights13 data: flights.csv, planes.csv
// We rename 'planes.year' to 'year_built' to avoid confusion with flight year.
// Then do a left merge on tailnum
//

// Step 1: Prepare planes.dta with renamed 'year' => 'year_built'
import delimited "data/planes.csv", clear
rename year year_built
save "data/planes_prepped.dta", replace

// Step 2: Merge into flights as a left join on tailnum
import delimited "data/flights.csv", clear
merge m:1 tailnum using "data/planes_prepped.dta", nogenerate

// Keep only a few columns to mirror the R example:
keep year month day dep_time arr_time carrier flight tailnum ///
     year_built type model
list in 1/3

/***************************************************************************
 4. tidyr Basics: pivot_longer, pivot_wider => reshape
***************************************************************************/

//
// 4.1 pivot_longer => reshape long
// We'll create a small "stocks" dataset in memory as in the R example.
//

clear
set obs 2
generate time = mdy(1,1,2009) + _n - 1 // Jan 1, 2009 plus 0 or 1
format time %tdNN/DD/CCYY

// X ~ N(0,1), Y ~ N(0,2), Z ~ N(0,4)
generate stock1 = rnormal(0,1)
generate stock2 = rnormal(0,2)
generate stock3 = rnormal(0,4)

list

// Reshape long (similar to pivot_longer)
reshape long stock, i(time) j(n) string
rename stock price
rename n stock

list, clean

//
// 4.2 pivot_wider => reshape wide
//
reshape wide price, i(time) j(stock) string
list, clean

/* 
   Similarly, you can reshape by other columns. 
   The key is to identify i() = your ID cols, j() = pivoted col, 
   and use reshape wide / long with an appropriate stub name. 
*/

//
// 4.3 Real-world example: billboard data => pivot_longer
// The billboard data in R has columns like artist, track, date.entered, wk1...
// So let's do something similar in Stata with 'reshape long'.
// 
// Example (assuming billboard.csv has columns 'artist', 'track', 'date.entered', 'wk1', 'wk2', etc.)
//

import delimited "data/billboard.csv", clear stringc(1 2 3) numericc(4/79)
gen date_entered = date(dateentered, "YMD"), before(wk1)
format date_entered %td
drop dateentered

desc  // see the variable names

/*
 Suppose the wide columns are wk1, wk2, wk3, ... = rank on each "week".
 We'll do something like:
    reshape long wk, i(artist track date.entered ...) j(week)
    rename wk rank
*/

// We'll guess your ID variables and wide stubs:
reshape long wk, i(artist track date_entered) j(week)
rename wk rank

list in 1/10, clean

/***************************************************************************
 5. Other tidyr utilities
   - separate(), unite(), fill(), drop_na(), etc.
   In Stata:
     - separate => split by substring or parse out parts (e.g. 'split' command)
     - unite => generate a combined variable (string concatenation)
     - drop_na => drop if missing(var)
***************************************************************************/

// Example of splitting "A-B" into A and B
// In Stata, you'd do something like:
//   generate str20 col = "A-B"
//   split col, parse("-") destring

// Example of uniting columns A and B with '-'
//   generate col_name = A + "-" + B

/***************************************************************************
 6. End of Script
***************************************************************************/

disp "All done! Demonstrations analogous to the R code are complete."
