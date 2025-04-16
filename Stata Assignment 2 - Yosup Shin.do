* Stata Assignment 2 - Yosup Shin *
if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="yosupshin" { //this would be your username on your computer
	
	global wd "/Users/yosupshin/Desktop/PPOL6818_expdesign" //this would your ppol_6818 folder address
}

* Set globals
global tanz_stud_dta "$wd/week_05/03_assignment/01_data/q1_psle_student_raw.dta"
global household "$wd/week_05/03_assignment/01_data/q2_CIV_Section_0.dta"
global pop_density "$wd/week_05/03_assignment/01_data/q2_CIV_populationdensity.xlsx"
global gps "$wd/week_05/03_assignment/01_data/q3_GPS_Data.dta"
global tanz_raw "$wd/week_05/03_assignment/01_data/q4_Tz_election_2010_raw.xls"
global election "$wd/week_05/03_assignment/01_data/q4_Tz_election_template.dta"
global psle "$wd/week_05/03_assignment/01_data/q5_psle_2020_data.dta"
global school "$wd/week_05/03_assignment/01_data/q5_school_location.dta"

* Question 1 *
// (Hey, Jacob, I am still quite sure this is best way to solve this question. I have asked professor and my friends how to solve it and we brainstormed together, but I am not still sure what is great way to do this without writing like 100 lines of codes, I'd appreciate if we could go over some good tips or answers for this question by any chance!)

use $tanz_stud_dta, replace
// Initialize empty variables to store extracted information
local vars student_num school_code cand_id gender prem_number name ///
            Kiswahili English maarifa hisabati science uraia average

foreach var in `vars' {
    gen `var' = ""
}			

// Convert variable 's' to a string format
tostring s, replace

// Save the modified dataset
save "student.dta", replace

// Create an empty temporary file to store student information
clear
tempfile student
save `student', replace emptyok

// Reload the saved student dataset
use "student.dta", replace

// Retrieve unique school codes
levelsof schoolcode, local(schools)

foreach school in `schools' {
    preserve
    
    // Keep only records related to the current school
    keep if schoolcode == "`school'"
    
    // Extract the number of students who took the exam for this school
    replace student_num = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)$")
    destring student_num, replace force
    local values = student_num[1]
    
    display "`values'" 
    display schoolcode
    
    // Save the current school's dataset
    save "schools.dta", replace

    forvalues i = 1/`values' {
        use "schools.dta", clear

        // Extract and store the school code
        replace school_code = regexs(1) if regexm(s, "([A-Z][A-Z][0-9]{7})$")
        local varcode = school_code[1]

        // Extract and store the candidate ID
        replace cand_id = regexs(1) if regexm(s, "(PS[0-9]{7}\-[0-9]{4})")
        local varcand = cand_id[1]
        display "`varcand'"
        replace s = subinstr(s, "`varcand'", "", 1)

        // Extract and store the student's gender
        replace gender = regexs(1) if regexm(s, ">([MF])</FONT>")
        local vargend = gender[1]
        display "`vargend'"
        replace s = subinstr(s, ">`vargend'</FONT>", "", 1)

        // Extract and store the student's unique examination number
        replace prem_number = regexs(1) if regexm(s, "(2015[0-9]{7})")
        local varprem = prem_number[1]
        display "`varprem'"
        replace s = subinstr(s, "`varprem'", "", 1)

        // Extract and store the student's full name
        replace name = regexs(1) if regexm(s, "<P>([A-Z]+ [A-Z]+ [A-Z]+)</FONT>")
        local varname = name[1]
        display "`varname'"
        replace s = subinstr(s, "`varname'", "", 1)

        // Extract and store the student's grade in Kiswahili
        replace Kiswahili = regexs(1) if regexm(s, "Kiswahili - ([A-Z]),")
        local varKiswahili = Kiswahili[1]
        display "`varKiswahili'"
        replace s = subinstr(s, "Kiswahili - `varKiswahili'", "", 1)

        // Extract and store the student's grade in English
        replace English = regexs(1) if regexm(s, "English - ([A-Z]),")
        local varEnglish = English[1]
        display "`varEnglish'"
        replace s = subinstr(s, "English - `varEnglish'", "", 1)

        // Extract and store the student's grade in Maarifa (General Knowledge)
        replace maarifa = regexs(1) if regexm(s, "Maarifa - ([A-Z]),")
        local varmaarifa = maarifa[1]
        display "`varmaarifa'"
        replace s = subinstr(s, "Maarifa - `varmaarifa'", "", 1)

        // Extract and store the student's grade in Mathematics
        replace hisabati = regexs(1) if regexm(s, "Hisabati - ([A-Z]),")
        local varhisabati = hisabati[1]
        display "`varhisabati'"
        replace s = subinstr(s, "Hisabati - `varhisabati'", "", 1)

        // Extract and store the student's grade in Science
        replace science = regexs(1) if regexm(s, "Science - ([A-Z]),")
        local varscience = science[1]
        display "`varscience'"
        replace s = subinstr(s, "Science - `varscience'", "", 1)

        // Extract and store the student's grade in Civics (Uraia)
        replace uraia = regexs(1) if regexm(s, "Uraia - ([A-Z]),")
        local varuraia = uraia[1]
        display "`varuraia'"
        replace s = subinstr(s, "Uraia - `varuraia'", "", 1)

        // Extract and store the student's overall average grade
        replace average = regexs(1) if regexm(s, "Average Grade - ([A-Z])")
        local varaverage = average[1]
        display "`varaverage'"
        replace s = subinstr(s, "Average Grade - `varaverage'", "", 1)    

        // Save the extracted data for the current school
        save "schools.dta", replace
        
        clear
        display "`varcand'"
        set obs 1
        gen id = `i'

        // Assign extracted values to new observations
        gen school_code = ""
        replace school_code = "`varcode'"

        gen cand_id = ""
        replace cand_id = "`varcand'"

        gen gender = ""
        replace gender = "`vargend'"

        gen prem_number = ""
        replace prem_number = "`varprem'"

        gen name = ""
        replace name = "`varname'"

        gen Kiswahili = ""
        replace Kiswahili = "`varKiswahili'"

        gen English = ""
        replace English = "`varEnglish'"

        gen maarifa = "" 
        replace maarifa = "`varmaarifa'"

        gen hisabati = "" 
        replace hisabati = "`varhisabati'"

        gen science = "" 
        replace science = "`varscience'"

        gen uraia = "" 
        replace uraia = "`varuraia'"

        gen average = ""
        replace average = "`varaverage'"

        // Append the extracted student record to the main dataset
        append using `student'
        save `student', replace
    }
    restore
}

// Load the final compiled dataset
use `student', clear

// Sort the data by school code
sort school_code

// Remove the temporary index variable
drop id


* Question 2 *

// In order to add population density column to the CIV_Section_0 dataset, I am going to convert the excel file to .dta file
// (I tried to use tempfile command here, then merge using it, but it gave me an error, so I did not use it)

import excel using $pop_density, firstrow clear
rename DENSITEAUKM Density
rename NOMCIRCONSCRIPTION Department
keep Density Department
tab Department
// Converts all characters in the Department variable to lowercase
replace Department = lower(Department)

// Keeps only rows where Department contains the word "departement" (case-sensitive)
keep if regexm(Department, "departement")

// Finds and extracts the name after "departement d', de, du" and replaces the entire Department variable with just that name
// regexs(1) → Captures whatever is inside ( .+ ), which represents the actual department name
replace Department = regexs(1) if regexm(Department, "departement d'(.+)")
replace Department = regexs(1) if regexm(Department, "departement de (.+)")
replace Department = regexs(1) if regexm(Department, "departement du (.+)")

// Ensures there are no extra spaces before or after the department name just in case
replace Department = trim(Department)

// fix incorrect department name
replace Department= "arrha" if Department == "arrah"
// Save the conveted dta file
save "density.dta", replace
global density "$wd/week_05/03_assignment/01_data/density.dta"

** Merge two datasets using the density file
use $household, replace 
tempfile household_data
decode b06_departemen, gen (Department)
save household_data
merge m:1 Department using $density

// clean the dataset
drop if _merge==2
drop _merge


* Question 3 *
use $gps, replace
// install user-created command to calculate geographical distances
ssc install geodist

// Generate temp file for looping
clear
tempfile enumerator_ids
gen id =.
save `enumerator_ids'

use $gps, replace
gen enumerator= .
sort longitude 
// Create looping
local j= ceil(_N/6)
forvalues i=1/`j'{
	
	merge 1:1 id using `enumerator_ids'
	drop _merge
	drop if enumerator !=.
	
	sort longitude
	gen latitude1 = latitude[1]
	gen longitude1 = longitude[1]
	geodist longitude latitude longitude1 latitude1, gen(distance)
	sort distance
	gen close_dist= _n
	replace enumerator= `i' if close_dist <=6
	drop latitude1 longitude1 distance close_dist
	keep if enumerator !=.
	append using `enumerator_ids'
	save `enumerator_ids', replace
	use $gps, clear
}

// clean up the looped data
merge 1:1 id using `enumerator_ids'
sort enumerator
drop _merge

// check the result of enumeration
scatter latitude longitude, mlabel(enumerator)


* Question 4 *
import excel using $tanz_raw, clear

// Rename columns based on their content
rename A Region
rename B District
rename C Constituency
rename D Ward 
rename H PoliticalParty
rename I Votes

//Remove irrelevant columns and drop non-data rows
drop F G J K 
drop if E ==""
drop if E == "CANDIDATE NAME"
drop E

// Fill missing region, district, constituency, and ward names using previous values
// Fill in missing geographical details using prior row values
foreach var in Region District Constituency Ward {
    replace `var' = `var'[_n-1] if `var' == ""
}

// Assign a unique identifier to each ward
egen ward_id = group(Region District Ward)

// Number the candidates within each ward
bysort ward_id: gen candidate_number = _n
bysort ward_id: egen total_candidates = max(candidate_number)

// Ensure every political party has a row in each ward
fillin PoliticalParty ward_id
gsort ward_id -Region

//fill in the regional info (I couldn't figure out better way than this)
foreach var in Region District Constituency Ward {
    replace `var' = `var'[_n-1] if `var' == ""
}

// Convert votes column to numeric and handle "UN OPPOSED" cases
replace Votes = "0" if Votes == "UN OPPOSSED"
destring Votes, gen(votes)
drop Votes
rename votes Votes

// Rank candidates within each ward
bysort ward_id: gen rank = _n
drop _fillin candidate_number
sort ward_id PoliticalParty

// Reshape dataset to wide format where each row represents a ward
reshape wide PoliticalParty total_candidates Votes, i(ward_id) j(rank)
rename total_candidates1 candidates
drop total_candidates*

// Calculate total votes in each ward
egen totalvotes = rowtotal(Votes*)

// Order columns same as the template dta file
order Region District Constituency Ward candidates totalvotes ward_id 

// Generate empty vote columns for all political parties
gen AFPvotes =.
gen APPT_MAENDELEOvotes =.
gen CCMvotes =.
gen CHADEMAvotes =.
gen CHAUSTAvotes =.
gen CUFvotes =.
gen DPvotes =.
gen JAHAZIASILIAvotes =.
gen MAKINvotes =.
gen NCCRMAGEUZIvotes =.
gen NLDvotes =.
gen NRAvotes =.
gen SAUvotes =.
gen TADEAvotes =.
gen TLPvotes =.
gen UDPvotes =.
gen UMDvotes =.
gen UPDPvotes =.

// Assign vote counts to respective political parties
forvalues i=1/18 {
	replace AFPvotes = Votes`i' if PoliticalParty`i' == "AFP"
	replace APPT_MAENDELEOvotes = Votes`i' if PoliticalParty`i' == "APPT - MAENDELEO"
	replace CCMvotes = Votes`i' if PoliticalParty`i' == "CCM"
	replace CHADEMAvotes = Votes`i' if PoliticalParty`i' == "CHADEMA"
	replace CHAUSTAvotes = Votes`i' if PoliticalParty`i' == "CHAUSTA"
	replace CUFvotes = Votes`i' if PoliticalParty`i' == "CUF"
	replace DPvotes = Votes`i' if PoliticalParty`i' == "DP"
	replace JAHAZIASILIAvotes = Votes`i' if PoliticalParty`i' == "JAHAZI ASILIA"
	replace MAKINvotes = Votes`i' if PoliticalParty`i' == "MAKIN"
	replace NCCRMAGEUZIvotes = Votes`i' if PoliticalParty`i' == "NCCR-MAGEUZI"
	replace NLDvotes = Votes`i' if PoliticalParty`i' == "NLD"
	replace NRAvotes = Votes`i' if PoliticalParty`i' == "NRA"
	replace SAUvotes = Votes`i' if PoliticalParty`i' == "SAU"
	replace TADEAvotes = Votes`i' if PoliticalParty`i' == "TADEA"
	replace TLPvotes = Votes`i' if PoliticalParty`i' == "TLP"
	replace UDPvotes = Votes`i' if PoliticalParty`i' ==  "UDP"
	replace UMDvotes = Votes`i' if PoliticalParty`i' == "UMD"
	replace UPDPvotes = Votes`i' if PoliticalParty`i' == "UPDP"	
}

drop PoliticalParty* Votes*

* Question 5 *
use "$school", replace

tempfile school_temp

// Remove entries without valid school identifiers
rename NECTACentreNo school_id
keep if school_id != "n/a"

// Identify and remove duplicate school listings
duplicates report school_id  // Check for duplicate counts before removal
duplicates drop school_id, force

save "school_temp"

use "$psle", clear

// Extract the school identifier from the composite code fields
split school_code_address, parse(_)
split school_code_address2, parse(.)
rename school_code_address21 school_id
drop school_code_address1 school_code_address2 school_code_address22

// Convert school ID to uppercase for consistency in merging
replace school_id = strupper(school_id)

// Merge school data with PSLE dataset
merge 1:1 school_id using "school_temp.dta"

// Remove unmatched records from the school dataset
drop if _merge == 2
drop _merge

// Reorder columns for better readability
order Ward, a(district_name)
