
**# Preparations (only once) --------------------------------

* set directories for ado files
sysdir set PLUS "ado"
sysdir set PERSONAL "ado"

* Install ftools (remove program if it existed previously)
cap ado uninstall ftools
net install ftools, from("https://raw.githubusercontent.com/sergiocorreia/ftools/master/src/")

* Install reghdfe 6.x
cap ado uninstall reghdfe
net install reghdfe, from("https://raw.githubusercontent.com/sergiocorreia/reghdfe/master/src/")

* Install parallel
cap ado uninstall parallel
net install parallel, from(https://raw.github.com/gvegayon/parallel/stable/) replace
mata mata mlib index

* Install ivreghdfe
cap ado uninstall ivreghdfe
cap ssc install ivreg2 // Install ivreg2, the core package
net install ivreghdfe, from(https://raw.githubusercontent.com/sergiocorreia/ivreghdfe/master/src/)

* Install estout
. ssc install estout, replace

**# fixed effects ----------------------------------------

* load data

!ls ../data/

import delimited "../data/ab_data.csv", clear varnames(1)

* data overview

describe

keep id ind year emp wage cap indoutpt n w k ys 

label variable id "Firm"
label variable emp "Employment"
label variable wage "Wage"
label variable indoutpt "Industry output"
label variable w "Log wage"
label variable n "Log employment"
label variable k "Log capital"
label variable ys "Log industry output"
label variable ind "Industry"
label variable year "Year"

describe

browse

* scatterplot of wage on emp

twoway (scatter wage emp) ///
       (lfit wage emp), ///
       xlabel(, grid) ylabel(, grid) ///
       xtitle("Employment") ///
       ytitle("Wages") ///
       scheme(s2color) ///
       legend(off)

graph export "../outputs/pl1_stata.png", replace

* baseline regression

reghdfe w n k ys, absorb(id year) cluster(id)

esttab, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
       stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
        label 

* sensitivity to fixed effects specifications

estimates clear

reghdfe w n k ys, noabsorb cluster(id)
estimates store m1

reghdfe w n k ys, absorb(id) cluster(id) noconstant
estimates store m2

reghdfe w n k ys, absorb(id year) cluster(id) noconstant
estimates store m3

esttab m*, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
       stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
        label 

* heterogeneity analysis via subsamples

estimates clear

* Get unique values of industry
levelsof ind, local(industries)

* Loop over each industry
foreach i of local industries {
    * Run regression for each industry
    reghdfe w n k ys if ind == `i', absorb(id year) cluster(id)
    
    * Store the estimates
    estimates store ind_`i'
}

* Display results side by side
esttab ind_*, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
    stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
    label

* robustness - subset sample for firms in 1980s

reghdfe w n k ys if year >= 1980, absorb(id year) cluster(id)

esttab, b(3) se(3) star(* 0.10 ** 0.05 *** 0.01) ///
       stats(N r2, fmt(%9.0f %9.3f) labels("Observations" "R-squared")) ///
        label 