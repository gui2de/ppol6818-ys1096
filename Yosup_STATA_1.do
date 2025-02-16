* STATA assignment 1 - Yosup Shin*

if c(username)=="jacob" {
	
	global wd "C:\Users\jacob\OneDrive\Desktop\PPOL_6818"
}

if c(username)=="Yosup" { //this would be your username on your computer
	
	global wd "/Users/yosupshin/Desktop/PPOL6818_expdesign" //this would your ppol_6818 folder address
}

** Question 1 **
global wd "/Users/yosupshin/Desktop/PPOL6818_expdesign"
global stud_dta "$wd/week_03/04_assignment/01_data/q1_data/student.dta"
global teac_dta "$wd/week_03/04_assignment/01_data/q1_data/teacher.dta"
global scho_dta "$wd/week_03/04_assignment/01_data/q1_data/school.dta"
global subj_dta "$wd/week_03/04_assignment/01_data/q1_data/subject.dta"


use "$stud_dta", replace
* merge using teacher variable
rename primary_teacher teacher
merge m:1 teacher using $teac_dta
drop _merge

* merge using school variable
merge m:1 school using $scho_dta
drop _merge

*merge using subject variable
merge m:1 subject using $subj_dta
drop _merge

* find  mean attendance of students at sounthern schools
sum attendance if loc=="South"

* find proportion of high school students who have a primary teacher who teaches a tested subject
tab stdnt_num if level == "High"
tab stdnt_num if level == "High" & tested == 1

* summarize the gpa of all students in the district
sum gpa if "loc" == "South"
sum gpa if "loc" == "North"
sum gpa if "loc" == "West"
sum gpa

* find mean attendance of school from each middle school
bysort school:sum attendance if level=="Middle" 

** Question 2 **
global pixel_data "$wd/week_03/04_assignment/01_data/q2_village_pixel.dta"
use "$pixel_data", replace

sort pixel payout
bysort pixel: egen min_payout = min(payout)
bysort pixel: egen max_payout = max(payout)
gen pixel_consistent=0
replace pixel_consistent =1 if min_payout ==max_payout 
tab pixel_consistent 

** encode pixel column
encode pixel, gen(encode_pixel)
tab encode_pixel

bysort village (pixel): gen pixel_count = _N
gen pixel_village = 0
replace pixel_village = 1 if pixel_count > 1

* (c)

gen dif_pix_same_payout = hhid if pixel_village == 0 & pixel_consistent == 1

bysort village: egen min_village_payout= min(payout)
bysort village: egen max_village_payout= max(payout)

gen village_constant=0
replace village_constant= 1 if min_village_payout == max_village_payout

gen village_pay_pixel_status =  1 if pixel_village == 0
replace village_pay_pixel_status = 2 if pixel_village == 1 & village_constant == 1
replace village_pay_pixel_status = 3 if pixel_village == 1 & village_constant == 0

tab village_pay_pixel_status
** Question 3 **

global proposal "$wd/week_03/04_assignment/01_data/q3_proposal_review.dta"
use "$proposal", replace

* rename wrongly name columns
rename Rewiewer1 Reviewer1
rename Review1Score score1
rename Reviewer2Score score2
rename Reviewer3Score score3

* reshape into long
reshape long Reviewer score, i(proposal_id) j(reviewer_number)

* generate mean and standarized score by each reviewer
bysort Reviewer: egen mean_score = mean(score)
bysort Reviewer: egen sd_score = sd(score)

gen stand_score = (score - mean_score) / sd_score
sort proposal_id

* reshape back to wide
reshape wide Reviewer score mean_score sd_score stand_score, i(proposal_id) j(reviewer_number)

* generate average standarized score of all three scores
egen average_stand_score = rowmean (stand_score1 stand_score2 stand_score3)

* sort average standarized score from the highest to the lowest
gsort -average_stand_score 

* Generate rank of average standarized score
gen rank=_n


** Question 4 **
global excel_t21 "$wd//week_03/04_assignment/01_data/q4_Pakistan_district_table21.xlsx"

clear

* Create an empty tempfile
tempfile table21
save `table21', replace emptyok

* Loop through all 135 sheets
forvalues i=1/135 {
    import excel "$excel_t21", sheet("Table `i'") firstrow clear allstring  // Import as strings
    display as error `i'  // Display progress

    keep if regexm(TABLE21PAKISTANICITIZEN1, "18 AND") == 1
	* Keep only rows that contain "18 AND" in the relevant column
    keep in 1  // Keep only the first occurrence

    * Rename first column for consistency
    rename TABLE21PAKISTANICITIZEN1 table21

    * Create a variable to track the sheet source
    gen table = `i'
    * Append the cleaned data
    append using `table21'
    save `table21', replace
}

* Load the cleaned dataset
use `table21', clear
*fix column width issue to make it easier to with with it
format %40s table21 B C D E F G H I K L M N O P Q R S T U V W X Y Z AA AB AC
order table, last

* loops to deal with misaligned columns
local cols "B C D E F G H I K L M N O P Q R S T U V W X Y Z AA AB AC"

foreach var in `cols' {
	replace `var' = "" if regexm(`var',"-")
	replace `var' = "" if trim(`var') == ""
}

order table, last
sort table 

local i = 1
foreach var of varlist B-Z AA-AC {
	rename `var' col`i'
	local i = `i' + 1
}

* reshape the dataset into appropriate formate
reshape long col, i(table) j(variable) string
drop if col == ""
drop variable

bysort table: gen variable = _n

reshape wide col, i(table) j(variable)

local letters "A B C D E F G H I J K L"
local i = 1
foreach var of varlist col* {
	replace `var' = strtrim(`var')
	local newname: word `i' of `letters'
	rename `var' `newname'
	local i = `i' + 1
}

* rename columns
replace table21 = "18 AND ABOVE" if regexm(table21, "OVERALL")
format %40s table21 A B C D E F G H I K L 
order table21 F J K L A B C D E G H I
rename F all_total_population
rename J all_C_N_I_Card_obtained
rename K all_C_N_I_CARD_not_obtained
rename L male_total_population
rename A male_C_N_I_Card_obtained
rename B male_C_N_I_CARD_not_obtained
rename C female_total_population
rename D female_C_N_I_Card_obtained
rename E female_C_N_I_CARD_not_obtained
rename G trans_total_population
rename H trans_C_N_I_Card_obtained
rename I trans_C_N_I_CARD_not_obtained
drop table21 //since this we are only extracting the columns 2-13
order table

* Save final dataset
save "$wd//week_03/04_assignment/01_data/cleaned_Pakistan.dta", replace

** Question 5 **
global school_level "$wd/week_03/04_assignment/01_data/q5_Tz_student_roster_html.dta"
use "$school_level", clear

codebook s
display s[1]

* Remove HTML Tags
replace s = regexr(s, "<[^>]+>", "")

* Generate number of student who took exam
gen num_student_exam_takers = regexs(1) if regexm(s, "WALIOFANYA MTIHANI : ([0-9]+)")

* Generate school average
gen school_avg = regexs(1) if regexm(s, "WASTANI WA SHULE\s*:\s*([0-9]+\.[0-9]+)")

* Generat binary variable which indicates under 40 or >=40, 1 = more than or equal to 40
gen student_group = 0  
replace student_group = 1 if regexm(s, "Wanafunzi chini ya ([0-9]+)") & real(regexs(1)) >=40
label var student_group "either under 40 or >=40, 0 = under 40"

* Generate school ranking in council
gen council_school_ranking = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIHALMASHAURI:\s*([0-9]+) kati ya ([0-9]+)")
label var council_school_ranking "school ranking in council out of 46"

* Generate school ranking in region
gen region_school_ranking = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KIMKOA\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")
label var region_school_ranking "regional school ranking, out of 290"

* Generate national school ranking
gen national_school_ranking = regexs(1) if regexm(s, "NAFASI YA SHULE KWENYE KUNDI LAKE KITAIFA\s*:\s*([0-9]+)\s+kati\s+ya\s+([0-9]+)")
label var national_school_ranking "national school ranking, out of 5664"

gen school_name = regexs(1) if regexm(s, "([A-Z ]+) - PS[0-9]+")
gen school_code = regexs(0) if regexm(s, "(PS[0-9]+)")

drop s

drop school_code

** Bonus question ** // Not a correct answers, I couldn't figure out appropriate way to extract data for 16 rows
global school_level "$wd/week_03/04_assignment/01_data/q5_Tz_student_roster_html.dta"
use "$school_level", clear

codebook s
display s[1]

* Remove HTML Tags
replace s = regexr(s, "<[^>]+>", "")

* Extract Candidate Number
gen cand_no = regexs(1) if regexm(s, "([A-Z0-9-]{14})")
* Extract Exam Number (Prem No)
gen prem_no = regexs(1) if regexm(s, "([0-9]{11})") 

* Extract Gender (M/F)
gen gender = regexs(1) if regexm(s, "([MF])")

* Extract Student Name - This is where I am getting missing value
gen name = regexs(1) if regexm(s, "<P>([A-Z]+\s[A-Z]+\s[A-Z]+)")

* Extract Subject Grades
gen kiswahili = regexs(1) if regexm(s, "Kiswahili\s*-\s*([A-D])")
gen english = regexs(1) if regexm(s, "English\s*-\s*([A-D])")
gen maarifa = regexs(1) if regexm(s, "Maarifa\s*-\s*([A-D])")
gen hisabati = regexs(1) if regexm(s, "Hisabati\s*-\s*([A-D])")
gen science = regexs(1) if regexm(s, "Science\s*-\s*([A-D])")
gen uraia = regexs(1) if regexm(s, "Uraia\s*-\s*([A-D])")
gen average = regexs(1) if regexm(s, "Average Grade\s*-\s*([A-D])")

drop s
