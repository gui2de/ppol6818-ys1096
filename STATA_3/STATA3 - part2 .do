capture program drop samp_regression
program define samp_regression, rclass
    syntax, nsize(integer)
    clear
    set obs `nsize'
    gen x = rnormal()
    gen y = 2*x + 10
    
    regress y x
    
    return scalar N = e(N)
    return scalar beta = _b[x]
    return scalar SEM = _se[x]
    return scalar pvalue = 2 * (1 - normal(abs(_b[x]/_se[x])))
    return scalar ci_low = _b[x] - invttail(e(df_r), 0.025)*_se[x]
    return scalar ci_high = _b[x] + invttail(e(df_r), 0.025)*_se[x]
end

// Create dataset to store all results
clear
set obs 0
gen sample_size = .
gen rep = .
gen N = .
gen beta = .
gen SEM = .
gen pvalue = .
gen ci_low = .
gen ci_high = .
gen ci_width = .
save regression_results.dta, replace

// Define sample sizes
local powers_of_two 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536 131072 262144 524288 1048576 2097152
local other_sizes 10 100 1000 10000 100000 1000000

// Combine all sizes
local all_sizes `powers_of_two' `other_sizes'

// Run simulations for each sample size
foreach n of local all_sizes {
    display "Running simulation for n = `n'"
    
    clear
    simulate N=r(N) beta=r(beta) SEM=r(SEM) pvalue=r(pvalue) ci_low=r(ci_low) ci_high=r(ci_high), reps(500) seed(12345): samp_regression, nsize(`n')
    
    // Add sample size and replication number
    gen sample_size = `n'
    gen rep = _n
    gen ci_width = ci_high - ci_low
    
    // Append to main dataset
    append using regression_results.dta
    save regression_results.dta, replace
}

// Load the final dataset
use regression_results.dta, clear
drop log_sample_size
// Sort by sample size for analysis
sort sample_size rep

save regression_results.dta, replace

* step 3: 

//table
dtable beta-ci_width, by(N, notot) export(STATA_3_part2_table.docx)

// Figure 
hist beta, by(N)
graph box beta, over(N)

save regression_results.dta, replace
