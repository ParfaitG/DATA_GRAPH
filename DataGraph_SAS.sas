%let fpath = C:\Path\To\DATA_GRAPH;

** READING IN TXT FILES;
proc import	datafile = "&fpath\DATA\MultifactorProductData.txt"
	out = MFPData dbms = tab replace;
run;

proc import	datafile = "&fpath\DATA\MultifactorSectorData.txt"
	out = SectorData dbms = tab replace;
run;

** DATA CLEANING;
data MFPData;
	set MFPData;
	sector_code = input(substr(series_id, 4, 4), best.);			
	drop footnote_codes;
	if substr(series_id, 8, 3) = "012";
run;

data SectorData;
	set SectorData;
	keep sector_code sector_name;
run;

** MERGING DATASETS;
proc sort data=MFPData out=MFPData;
	by sector_code;
run;

proc sort data=SectorData out=SectorData;
	by sector_code;
run;

data ProductData;
   merge MFPData SectorData;
   by sector_code;
run;

** UPDATING SECTOR NAME AND NAICS;
data ProductData;
	set ProductData;
	NAICSpos = prxmatch("/NAICS/", sector_name);
	NAICS = substr(sector_name, NAICSpos-1, lengthc(sector_name) - NAICSpos+1);	
	Sector = substr(sector_name, 1, NAICSpos-2);
	drop NAICSpos sector_name;
run;

** BUILD SECTOR CODE LIST;
%let sectorcode =;
data _null_;
	set Sectordata;
	call symput('sectorcode', trim(resolve('&sectorcode'))||' '||sector_code);
run;
%put &sectorcode;

** GET COUNT OF LIST;
%macro wordcount(list);
   %* Count the number of words in &LIST;
   %local count;
   %let count=0; 
   %do %while(%qscan(&list,&count+1,%str( )) ne %str());
       %let count = %eval(&count+1); 
   %end;
   &count
%mend wordcount;
%let cntlist = %wordcount(&sectorcode);

** OUTPUT GRAPH;
%macro runGraphs;		
	%do i = 1 %to &cntlist;
		data GraphData;
			set ProductData;	
			if sector_code = %scan(&sectorcode,&i);	
		run;

		GOPTIONS RESET=ALL;

		filename outgraph "%sysfunc(catx( , &fpath\Graphs\sector_, %scan(&sectorcode,&i), _sas.gif))";
		goptions gsfname=outgraph device=gif
		         hsize=12in  vsize=4in                  
		         hpos=40	
				 noborder 
				 colors=(cxCC0000 cxFF0000 cx993300 cxCC3300 cxFF3300 cxCC9900 cxFFCC00 
			             cxFFFF00 cx006600 cx009900 cx00CC00 cx336666 cx006666 cx009999 
		                 cx0033FF cx0066FF cx0099FF cx000099 cx0000CC cx0000FF cx660099 
			             cx663399 cx9900CC cx660066 cx990066 cxCC0099 cxFF0999 cxFF00FF
		                 );

		pattern color=cx990000;

		title1 justify=center font="Arial/bold" 
		       "US MultiFactor Productivity, 1987-2015";
		axis1 stagger label=('Year');
		axis2 label=(a=90 'Product Value');

		proc gchart data=GraphData;
		   where year in (1987, 1988, 1989, 1990, 1991, 1992, 1993, 
	                      1994, 1995, 1996, 1997, 1998, 1999, 2000, 
	                      2001, 2002, 2003, 2004, 2005, 2006, 2007, 
	                      2008, 2009, 2010, 2011, 2012, 2013, 2014, 
	                      2015);

		   vbar year /  sumvar=value	
                        group=sector 
						maxis=axis1 
		                raxis=axis2
						space=0.1
						gspace=0.2
						discrete
						coutline=same
						patternid=midpoint;  
		run;
		quit;  
	%end;
%mend;

%runGraphs;

