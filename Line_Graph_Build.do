

clear all


*** DATA IMPORT
import delimited "E:\Sandbox\DATA\EIA Energy Consumption by Sector.csv", delimiters(",") varnames(1) case(preserve) clear

describe


*** DATA CLEAN
tostring YYYYMM, replace

* ASSIGN DATES
gen Date = .
format Date %td
replace Date = date(substr(YYYYMM, 1, 4) + "-" + substr(YYYYMM, 5, 2) + "-01", "YMD", 2050) if substr(YYYYMM, 5, 2) != "13"
replace Date = date(substr(YYYYMM, 1, 4) + "-12-31", "YMD", 2050) if substr(YYYYMM, 5, 2) == "13"

list YYYYMM Date in 1/10
list YYYYMM Date in -10/l
assert Date != .
order Date, after(MSN)


* ASSIGN INDICATORS
levelsof Description

gen Sector = ""
replace Sector = "Residential" if strpos(Description, "Residential")
replace Sector = "Commercial" if strpos(Description, "Commercial")
replace Sector = "Transportation" if strpos(Description, "Transportation")
replace Sector = "Industrial" if strpos(Description, "Industrial")
replace Sector = "All" if strpos(Description, "Consumption Total")
replace Sector = "Electric Power" if strpos(Description, "Electric Power")
replace Sector = "Other" if Description == "Energy Consumption Balancing Item"

tab Sector, m

gen Energy_Type = ""
replace Energy_Type = "Primary" if strpos(Description, "Primary Energy")
replace Energy_Type = "Total" if strpos(Description, "Total Energy")
replace Energy_Type = "Other" if Description == "Energy Consumption Balancing Item"

tab Energy_Type, m

order Sector Energy_Type, after(Value)


*** PLOT
preserve
	keep if inlist(Sector, "Residential", "Commercial") | inlist(Sector, "Industrial", "Transportation")
	keep if Energy_Type == "Total" & month(Date) == 12 & day(Date) == 31
	
	twoway (line Value Date if Sector == "Residential") ///
		   (line Value Date if Sector == "Commercial")  ///
		   (line Value Date if Sector == "Industrial")  ///
		   (line Value Date if Sector == "Transportation"), ///
			ytitle("Trillion BTUs", size(small)) xtitle(Date, size(small)) xsize(20) ysize(10) ///
			xlabel(`=date("12/31/1949", "MDY")'(365)`=date("12/31/2019", "MDY", 2050)', ///
				   angle(90) labsize(vsmall) valuelabel format(%tdCCYY)) ///
			ylabel(#10, angle(0) labsize(vsmall) valuelabel format(%10.0fc)) ///
			graphregion( fc(white) lc(white) ) ///
			title("Total U.S. Energy Consumption", color(black) size(medium)) ///
			legend(order(1 "Residential" 2 "Commercial" 3 "Industrial" 4 "Transportation") ///
				   size(vsmall) symxsize(vsmall) rowgap(*0) region(lwidth(none)) rows(1) pos(12)) ///
			note("Source: U.S. Department of Energy") 
		
	graph export "E:\Sandbox\Line_Graph_Build_Stata.png", replace as(png)		
restore



