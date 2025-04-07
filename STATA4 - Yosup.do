// STATA assignment 4 - Yosup Shin

* Part 1: Power calculations
// step 1

clear
set seed 0426

capture program drop assignment4
program define assignment4, rclass
    syntax, obs(integer)

    clear
    set obs `obs'

    // Assign 50% to treatment
    gen rand = runiform()
    sort rand
    gen treat = 0
    replace treat = 1 if _n <= `obs'/2

    // Outcome: baseline noise + treatment effect (avg 0.1)
    gen y = rnormal(0, 1) + treat * runiform(0, 0.2)

    // Simulate 15% attrition
    gen dropout = runiform()
    replace y = . if dropout < 0.15

    // Estimate treatment effect
    reg y treat
    matrix a = r(table)
    return scalar coef = a[1,1]
    return scalar pval = a[4,1]
end


clear
tempfile results_q1
save `results_q1', replace emptyok

forvalues i = 3000(100)3800 {
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4, obs(`i')

    gen samplesize = `i'
    append using `results_q1'
    save `results_q1', replace 
}

use `results_q1', clear
gen sig = (pvalue < 0.05)

collapse (mean) power = sig, by(samplesize)
list, clean

twoway line power samplesize, msymbol(circle) ///
    title("Power vs Sample Size (50% Treated, 15% Attrition)") ///
    ytitle("Power") xtitle("Sample Size")



// PART 2 — Power Simulation for Cluster Randomization

// Set seed for reproducibility
set seed 0426

// Drop program if it already exists
capture program drop assignment4_cluster

// Define the simulation program
program define assignment4_cluster, rclass
    syntax, clusters(integer) clustersize(integer)

    clear
    set obs `clusters'

    // Randomly assign treatment to half of the clusters
    local half_obs = `clusters'/2
    gen treated = 0
    replace treated = 1 if _n <= `half_obs'

    // Simulate takeup: only 70% of treated schools implement the program
    gen random_draw = runiform()
    gen takeup_flag = 0
    replace takeup_flag = 1 if random_draw <= 0.7 & treated == 1

    // School-level variables
    gen school = _n 
    gen school_effect = rnormal(0, 0.5)

    // Expand to individual-level data
    expand `clustersize'
    gen student_effect = rnormal(0, 1)

    // Generate outcome score
    gen total_score = student_effect + school_effect + takeup_flag * runiform(0.15, 0.25)

    // Normalize score
    summ total_score
    gen norm_score = (total_score - r(mean)) / r(sd)

    // Regression on normalized score
    reg norm_score treated

    // Add treatment effect to create final score
    gen final_score = norm_score + treated * runiform(0.15, 0.25)
    reg final_score treated

    // Store results
    matrix result = r(table)
    return scalar coef = result[1,1]
    return scalar pval = result[4,1]
end

// Step 5: Run simulation over varying cluster sizes
clear
tempfile results_q5
save `results_q5', replace emptyok

forvalues i = 1/10 {
    local size = 2^`i'
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4_cluster, clusters(200) clustersize(`size')

    gen samplesize = `i'
    append using `results_q5'
    save `results_q5', replace 
}
// Step 6: Power Simulation by Varying Number of Clusters (Fixed Cluster Size)

tempfile results_q6

forvalues i = 1/5 {
    local size = 10 * `i'
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4_cluster, clusters(`size') clustersize(15)

    gen samplesize = `i'
    append using `results_q6'
    save `results_q6', replace 
}

// Analyze results from Step 6
use `results_q6', clear

// Generate indicator for statistically significant result
gen sig = 0
replace sig = 1 if pvalue < 0.05

// Summarize significance rate by number of clusters
bysort samplesize: tabstat sig

// Step 7: Power Simulation by Varying Clusters Again (Confirming Power Increase)

clear
tempfile results_q7

forvalues i = 1/5 {
    local size = 10 * `i'
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4_cluster, clusters(`size') clustersize(15)

    gen samplesize = `i'
    append using `results_q7'
    save `results_q7', replace 
}

// Analyze simulation results
use `results_q7', clear

// Indicator for statistical significance
gen sig = 0
replace sig = 1 if pvalue < 0.05

// Summarize proportion of significant results by sample size
bysort samplesize: tabstat sig

// Part 3 - Part 3: De-biasing a parameter estimate using controls

set seed 0426

capture program drop assignment4_debias
program define assignment4_debias, rclass
    syntax, strata_groups(integer) individuals(integer)

    clear
    set obs `strata_groups'
    gen strata_id = _n
    gen strata_effect = runiform(0.15, 0.25)

    expand `individuals'
    sort strata_id
    gen id = _n

    gen covar1 = rnormal(50, 10)
    gen covar1_effect = rnormal(0, 1)

    gen covar2 = rnormal(3000, 500)
    gen covar2_effect = rnormal(0, 1)

    gen covar3 = rnormal(100, 50)

    gen treat = 0
    replace treat = 1 if covar1 >= 50 & covar3 <= 140

    gen y = rnormal(0, 1000) + treat * strata_effect + treat * covar1_effect + treat * covar2_effect

    reg y covar1 covar2 covar3 i.strata_id##c.covar1 treat
    matrix a = r(table)
    return scalar coef1 = a[1,1]

    reg y covar1 covar2 treat
    matrix a = r(table)
    return scalar coef2 = a[1,1]

    reg y covar1 covar3 treat
    matrix a = r(table)
    return scalar coef3 = a[1,1]

    reg y covar2 covar3 treat
    matrix a = r(table)
    return scalar coef4 = a[1,1]

    reg y covar2 treat
    matrix a = r(table)
    return scalar coef5 = a[1,1]
end

clear
tempfile results_step3
save `results_step3', replace emptyok

forvalues i = 1/4 {
    local strata = 3^`i'
    local indiv = 3^(`i'+1)

    simulate coef1=r(coef1) coef2=r(coef2) coef3=r(coef3) coef4=r(coef4) coef5=r(coef5), reps(500): ///
        assignment4_debias, strata_groups(`strata') individuals(`indiv')

    gen N = `strata' * `indiv'
    append using `results_step3'
    save `results_step3', replace 
}

// Histograms by model
forvalues i = 1/5 {
    histogram coef`i', by(N, note("")) title("Histogram of coef`i'")
    graph export assignment4_part3_histogram_model`i'.png, replace
}

// Boxplots by sample size
forvalues i = 1/5 {
    graph box coef`i', over(N, label(angle(45))) title("Boxplot of coef`i'")
    graph export assignment4_part3_boxplot_model`i'.png, replace
}


// PART 2 — Power Simulation for Cluster Randomization
set seed 0426

capture program drop assignment4_cluster
program define assignment4_cluster, rclass
    syntax, clusters(integer) clustersize(integer) //takeup(double)
    clear

    set obs `clusters'

    local half_obs = `clusters'/2
    gen treated = 0
    replace treated = 1 if _n <= `half_obs'

    display `takeup'
    gen random_draw = runiform()
    gen takeup_flag = 0
    replace takeup_flag = 1 if random_draw <= 0.7 & treated == 1

    gen school = _n 
    gen school_effect = rnormal(0, 0.5)

    expand `clustersize'

    gen student_effect = rnormal(0, 1)

    // Generate total score
    gen total_score = student_effect + school_effect + takeup_flag * runiform(0.15, 0.25)

    summ total_score
    gen norm_score = (total_score - r(mean)) / r(sd)

    reg norm_score treated

    gen final_score = norm_score + treated * runiform(0.15, 0.25)
    reg final_score treated

    matrix result = r(table)
    return scalar coef = result[1,1]
    return scalar pval = result[4,1]
end

// Step 5
clear
tempfile results_q5
save `results_q5', replace emptyok

forvalues i = 1/10 {
    local size = 2^`i'
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4_cluster, clusters(200) clustersize(`size')

    gen samplesize = `i'
    append using `results_q5'
    save `results_q5', replace 
}

use `results_q5', clear
gen sig = 0
replace sig = 1 if pvalue < 0.05
bysort samplesize: tabstat sig

/*
-> samplesize = 1

    Variable |      Mean
-------------+----------
         sig |      .886
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 2

    Variable |      Mean
-------------+----------
         sig |      .978
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 3

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 4

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 5

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 6

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 7

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 8

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 9

    Variable |      Mean
-------------+----------
         sig |         1
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 10

    Variable |      Mean
-------------+----------
         sig |         1
------------------------
*/


// Step 6
clear
tempfile results_q6
save `results_q6', replace emptyok

forvalues i = 1/5 {
    local size = 10 * `i'
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4_cluster, clusters(`size') clustersize(15)

    gen samplesize = `i'
    append using `results_q6'
    save `results_q6', replace 
}

use `results_q6', clear
gen sig = 0
replace sig = 1 if pvalue < 0.05
bysort samplesize: tabstat sig

/*
-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 1

    Variable |      Mean
-------------+----------
         sig |      .538
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 2

    Variable |      Mean
-------------+----------
         sig |        .7
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 3

    Variable |      Mean
-------------+----------
         sig |       .74
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 4

    Variable |      Mean
-------------+----------
         sig |       .82
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 5

    Variable |      Mean
-------------+----------
         sig |        .9
------------------------
*/

// Step 7
clear
tempfile results_q7
save `results_q7', replace emptyok

forvalues i = 1/5 {
    local size = 10 * `i'
    simulate coef=r(coef) pvalue=r(pval), reps(500): ///
        assignment4_cluster, clusters(`size') clustersize(15)

    gen samplesize = `i'
    append using `results_q7'
    save `results_q7', replace 
}

use `results_q7', clear
gen sig = 0
replace sig = 1 if pvalue < 0.05
bysort samplesize: tabstat sig

/*
-> samplesize = 1

    Variable |      Mean
-------------+----------
         sig |      .524
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 2

    Variable |      Mean
-------------+----------
         sig |      .668
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 3

    Variable |      Mean
-------------+----------
         sig |       .78
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 4

    Variable |      Mean
-------------+----------
         sig |      .808
------------------------

-----------------------------------------------------------------------------------------------------------------------
-> samplesize = 5

    Variable |      Mean
-------------+----------
         sig |      .938
------------------------

*/

// PART 3 — De-biasing a parameter estimate using controls

set seed 0426

capture program drop assignment4_debias
program define assignment4_debias, rclass
    syntax, strata_groups(integer) individuals(integer)

    clear
    set obs `strata_groups'

    // Create strata
    gen strata_id = _n
    gen strata_effect = runiform(0.15, 0.25)  // fixed effect per group

    // Expand to individual level
    expand `individuals'
    sort strata_id
    gen id = _n

    // -------------------------
    // Covariates
    // -------------------------

    // Covar1: affects both Y and treatment (confounder)
    gen covar1 = rnormal(50, 10)
    gen covar1_effect = rnormal(0, 1)

    // Covar2: affects Y only
    gen covar2 = rnormal(3000, 500)
    gen covar2_effect = rnormal(0, 1)

    // Covar3: affects treatment only
    gen covar3 = rnormal(100, 50)

    // -------------------------
    // Treatment Assignment
    // -------------------------
    gen treat = 0
    replace treat = 1 if covar1 >= 50 & covar3 <= 140

    // -------------------------
    // Outcome variable Y
    // -------------------------
    gen y = rnormal(0, 1000) + treat * strata_effect + treat * covar1_effect + treat * covar2_effect

    // -------------------------
    // Regressions
    // -------------------------

    // 1. Full model with interaction
    reg y covar1 covar2 covar3 i.strata_id##c.covar1 treat
    matrix a = r(table)
    return scalar coef1 = a[1,1]

    // 2. Excluding covar3 and interaction
    reg y covar1 covar2 treat
    matrix a = r(table)
    return scalar coef2 = a[1,1]

    // 3. Replace covar2 with covar3
    reg y covar1 covar3 treat
    matrix a = r(table)
    return scalar coef3 = a[1,1]

    // 4. Replace covar1 with covar2 and covar3
    reg y covar2 covar3 treat
    matrix a = r(table)
    return scalar coef4 = a[1,1]

    // 5. Just covar2 and treatment
    reg y covar2 treat
    matrix a = r(table)
    return scalar coef5 = a[1,1]
end

clear
// Test if the regression works
assignment4_debias, strata_groups(20) individuals(40)

// Step 5
clear
tempfile results_part3
save `results_part3', replace emptyok

// Loop through increasing sample sizes based on powers of 3
forvalues i = 1/4 {
    local strata = 3^`i'
    local indiv = 3^(`i'+1)

    simulate coef1=r(coef1) coef2=r(coef2) coef3=r(coef3) coef4=r(coef4) coef5=r(coef5), reps(500): ///
        assignment4_debias, strata_groups(`strata') individuals(`indiv')

    gen N = `strata' * `indiv'
    append using `results_part3'
    save `results_part3', replace
}

// Generate histograms by total sample size for each model
forvalues i = 1/5 {
    histogram coef`i', by(N, note("")) title("Histogram of coef`i' by Sample Size")
    graph export "assignment4_part3_histogram_model`i'.png", replace
}

// Generate boxplots comparing coefficient distributions
forvalues i = 1/5 {
    graph box coef`i', over(N, label(angle(45))) title("Boxplot of coef`i' across N")
    graph export "assignment4_part3_boxplot_model`i'.png", replace
}
