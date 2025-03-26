/*
File version 1.0

Description
-----------

This do file illustrates a simple Monte Carlo analysis of 
overcoming omitted variable bias with 2SLS.

Author
-----------
Dr Christian Engels
ce50@st-andrews.ac.uk
*/

clear all

* seed for reproducibility
set seed 42

* number of observations / length of data set in memory
set obs 10000

scalar corr_x1_x2 	= -0.1
scalar corr_x1_z 	= 0.25
scalar corr_x2_z	= 0

matrix Sigma = ///
(1, corr_x1_x2, corr_x1_z \ ///
corr_x1_x2, 1, corr_x2_z \ ///
corr_x1_z, corr_x2_z, 1)

drawnorm x1 x2 z, cov(Sigma)

* generate 2nd stage error term
gen e = rnormal(0, 1)

* generate outcome variable
scalar true_beta = 0.95
gen y = 0.5 +  true_beta*x1 + 0.5*x2 + e 

* show resuls with x2 (correctly specified model)
reg y x1 x2
* show resuls without x2 (omitted variable)
reg y x1 
* show resuls without x2 and x1 instrumented with z
ivregress 2sls y (x1=z)

* create frame for results
frame create results est1 est2

* 1000 Monte Carlo iterations
quietly foreach i of numlist 1/1000 {
	
	cap drop x1 x2 z e y
	set obs 10000
	drawnorm x1 x2 z, cov(Sigma)
	
	gen e = rnormal(0, 1)
	gen y = 0.5 +  true_beta*x1 + 0.5*x2 + e 
	
	reg y x1
	scalar est1 = _b[x1]
	
	ivregress 2sls y (x1=z)
	scalar est2 = _b[x1]
	
	frame post results (est1) (est2)
}
* switch to results frame
frame change results

* summarize Monte Carlo coefficient estimates
sum 

* plot Monte Carlo simulation results
kdensity est1, addplot(kdensity est2) ///
xtitle("Estimates") ytitle("Density") ///
ylabel(, nolabels notick) ///
legend(label(1 "OLS estimate") label(2 "2SLS estimate")) ///
title(Monte Carlo results: OLS vs 2SLS) ///
xline(0.95, lcolor(red))
