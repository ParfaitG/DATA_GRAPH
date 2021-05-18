

**********************************
*** DATA IMPORT
**********************************;

data Energy_Consumption;
		%let _EFIERR_ = 0; /* set the ERROR detection macro variable */
		infile 'E:\Sandbox\DATA\EIA Energy Consumption by Sector.csv' delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
		informat MSN $9. ;
		informat YYYYMM $8. ;
		informat Value 8. ;
		informat Column_Order $3. ;
		informat Description $52. ;
		informat Unit $14. ;

		format MSN $9. ;
		format YYYYMM $8. ;
		format Value 10.3 ;
		format Column_Order $3. ;
		format Description $100. ;
		format Unit $14. ;

		input MSN $
		      YYYYMM $
		      Value 
		      Column_Order $
		      Description $
		      Unit $;

       if _ERROR_ then call symputx('_EFIERR_',1);  /* set ERROR detection macro variable */
run;

data Energy_Consumption;
	format MSN Date YYYYMM Sector Energy_Type Column_Order Description Value;
	set Energy_Consumption;

	length Date 8. Sector $15 Energy_Type $8;

	if substr(YYYYMM, 5, 2) ^= "13" then Date = input(cats(substr(YYYYMM, 1, 4), '-', substr(YYYYMM, 5, 2), '-01'), yymmdd10.);
    else Date = input(cats(substr(YYYYMM, 1, 4), '-12-31'), yymmdd10.);
	format Date MMDDYY10.;

	select;
		when (index(Description, "Residential Sector") >= 1)	  Sector = "Residential";
		when (index(Description, "Commercial Sector") >= 1)		  Sector = "Commercial";
		when (index(Description, "Industrial Sector") >= 1)		  Sector = "Industrial";
		when (index(Description, "Transportation Sector") >= 1)   Sector = "Transportation";
		when (index(Description, "Consumption Total") >= 1)       Sector = "All";
		when (index(Description, "Electric Power") >= 1)          Sector = "Electric Power";
		when (Description = "Energy Consumption Balancing Item")  Sector = "Other";
	end;
		
	select;
		when (index(Description, "Primary Energy") >= 1)          Energy_Type = "Primary";
		when (index(Description, "Total Energy") >= 1)            Energy_Type = "Total";
		when (Description = "Energy Consumption Balancing Item")  Energy_Type = "Other";
	end;
run;

proc contents
	data = Energy_Consumption;
quit;

proc freq
	data = Energy_Consumption;
	tables Sector / missing;
quit;

proc freq
	data = Energy_Consumption;
	tables Energy_Type / missing;
quit;


**********************************
*** PLOT BUILD
**********************************;

proc sort data=Energy_Consumption;
	by Date Sector;
run;

proc transpose 
	data = Energy_Consumption(where=(Sector in ("Residential", "Commercial", "Industrial", "Transportation") and
                                     Energy_Type = "Total" & month(Date)=12 & day(Date)=31))
    out = Energy_Cons_Wide(drop=_NAME_);

	id Sector;
	var Value;
	by Date;
quit;


data Anno_Text;
 	infile datalines delimiter='|' DSD; 
	length function $10 x1space $20 y1space $20 x1 8. y1 8. width 8. textsize 8. textweight $10 label $50;
	
	input function x1space y1space x1 y1 width textsize textweight label;
	datalines;
text|wallpercent|graphpercent|10|5|100|10||Source: Department of Energy, EIA
;
run;


*** PROC SGPLOT;
ods listing close; 
ods listing gpath="E:\Sandbox";
ods graphics / reset=index imagename="Line_Graph_Build_SAS_sgplot" imagefmt=png
    height=6in width=12in; 

title height=18pt "Total U.S. Energy Consumption (1949 - 2019)";

proc sgplot data = Energy_Cons_Wide pad=(bottom=5pct) sganno=Anno_Text;
	series X=Date y=Residential    / lineattrs=(pattern=1);
	series X=Date y=Commercial     / lineattrs=(pattern=1);
	series X=Date y=Industrial     / lineattrs=(pattern=1);
	series X=Date y=Transportation / lineattrs=(pattern=1);

	yaxis valueattrs=(size=10pt) valuesformat=comma10.0 label="Trillion BTUs"
          grid labelattrs=(size=12pt weight=bold) values=(0 to 4E4 by 5E3);
	xaxis valueattrs=(size=10pt) valuesformat=year4. labelattrs=(size=12pt weight=bold)
          values=('31dec1948'd to '31dec2020'd by year);
	keylegend / location=outside position=N noborder;
run;

title;
ods _all_ close; 
ods listing; 




*** PROC GPLOT;
filename graphout 'E:\Sandbox\Line_Graph_Build_SAS_gplot.png';

/* Set the graphics environment */
goptions reset=all device=png gsfname=graphout
         cback=white border xpixels=1200 ypixels=600
         htitle=20pt htext=12pt ftext='Arial Unicode MS';

title1 h=20pt "Total U.S. Energy Consumption";
title2 h=16pt "1949 – 2019";

 /* Create axis definitions */
axis1 offset=(2) major=none minor=none label=none value=(a=90) order=('31dec1949'd to '31dec2019'd by year);
axis2 offset=(0,0) minor=none label=(a=90 h=14pt "Consumption (Trillion Btu)") order=(0 to 4E4 by 5E3);

 /* Create symbol definitions */
symbol1 interpol=join  value=none;

footnote1 j=l "  Source: Department of Energy, EIA";
footnote2 j=l " ";

/* Produce the plot */
proc gplot data=Energy_Consumption(where=(Sector in ("Residential", "Commercial", "Industrial", "Transportation") and
                                          Energy_Type = "Total" & month(Date)=12 & day(Date)=31));
	format Date year4.;
	format Value comma10.0;
	plot Value*Date=Sector / haxis=axis1 vaxis=axis2 grid;
run;

title;
footnote;
quit;


%macro delcat(catname); 
  %if %sysfunc(cexist(&catname)) 
     %then %do; 
       proc greplay nofs igout=&catname; 
         delete _all_; 
       run;
       quit; 
    %end; 
%mend delcat; 

%delcat(work.gseg);
