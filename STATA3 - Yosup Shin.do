* STATA Assignment 3 - Yosup Shin 

cd "/Users/yosupshin/Desktop/PPOL6818_expdesign/week_08/03_assignment"
clear 

* Step 1: Data generation process
set seed 0426
set obs 10000

* Step 2: generate random x, y, and error values

gen x = rnormal()
gen error = rnormal()
gen y = 2*x + 10 + error

save population.dta

* Step 3: Define program that generate random X's and for outcome Y
capture program drop samp_regression
program define samp_regression, rclass
	args N

	use "population.dta", replace

	sample `N', count
	
	regress y x
	// returns the N, beta, SEM, p-value, and confidence intervals into r() 
	return scalar N = e(N)
	return scalar beta     = _b[x]
    return scalar SEM      = _se[x]
    return scalar pvalue   = 2 * (1 - normal(abs(_b[x]/_se[x])))
    return scalar ci_low   = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ci_high  = _b[x] + invttail(e(df_r), 0.025)*_se[x]

end

* run regression to see if it works
samp_regression 100
return list

* Step 4: Run regression again, but using different N values 
clear 
set seed 0426

* define reps and sample sizes
local reps 500
local samp_size 10 100 1000 10000
foreach N in `samp_size'{
	display "Simulations for sample size = `N'"
	
	simulate N=r(N) beta=r(beta) SEM=r(SEM) pval=r(pvalue) ci_low=r(ci_low) ci_high=r(ci_high), ///
        reps(`reps') nodots: samp_regression `N'
		
		save simulation_data_`N'.dta, replace
}

* Load the first simulation dataset
use simulation_data_10.dta, replace

* Append the rest of the simulation files
append using simulation_data_100.dta
append using simulation_data_1000.dta
append using simulation_data_10000.dta


* Save the combined dataset with 2000 results
save all_simulations.dta, replace

* Step 5: Create tables and figures
use all_simulations.dta, replace

hist beta ,by (N)
* box plots
graph box beta, over(N)

* Table
dtable beta-ci_high, by(N)

// When your sample size is very large (N = 10,000), the sampling variability of the estimated coefficient (beta) becomes very small

save all_simulations.dta, replace

