<?php

require 'D:\\PHP - 5.4.4\\phplot\\phplot.php';

// CURRENT DIRECTORY
$cd = dirname(__FILE__);

// PRODUCT DATA
$handle = fopen($cd."/DATA/MultifactorProductData.txt", "r");    
$row = 0; $MFPdata = [];

while (($data = fgetcsv($handle, 1000, "\t")) !== FALSE) {
    $row++;
    if($row == 1){ $row++; continue; }
    
    $innerdata = [];
    if (substr(strval($data[0]), 7, 3) == "012"){
        $innerdata[] = intval(substr(strval($data[0]), 3, 4));  // SECTOR CODE
                            
        $innerdata[] = $data[1];                                // YEAR
        $innerdata[] = $data[3];                                // VALUE
    			    
        $MFPdata[] = $innerdata;    
    }    
        
}

fclose($handle);

// SECTOR DATA
$handle = fopen($cd."/DATA/MultifactorSectorData.txt", "r");    
$row = 0; $sectordata = [];

while (($data = fgetcsv($handle, 1000, "\t")) !== FALSE) {
    $row++;
    if($row == 1){ $row++; continue; }
    
    $innerdata = [];                                      
    $innerdata[] = intval($data[0]);                                                          // SECTOR CODE
    $innerdata[] = substr(strval($data[1]), 0, strlen(strval($data[1]))
                         - (strlen(strval($data[1])) - strpos(strval($data[1]), "(NAICS")));  // SECTOR NAME
    $innerdata[] = substr(strval($data[1]), strpos(strval($data[1]), "(NAICS"));              // NAICS
    $sectordata[] = $innerdata;    

}

fclose($handle);

// MERGE ARRAYS
$graphdata = [];
foreach($MFPdata as $m){
    foreach($sectordata as $s){
        if ($m[0] == $s[0]){            
            $m[] = $s[1];  // SECTOR NAME
            $m[] = $s[2];  // NAICS
            $graphdata[] = $m;
        }
    }
}

// DISTINCT SECTOR CODES
$industries = [];
foreach ($MFPdata as $m) {
    $sectors[]  = $m[0];
}
$sectors = array_unique($sectors, SORT_REGULAR);


// GENERATE GRAPHS ITERATIVELY BY SECTOR
foreach($sectors as $s){
    
    $values = ["Years"]; 
    $years = [];
    $sectname = [];
    foreach($graphdata as $g) {
        
        if ($g[0] == $s) {
            $years[] = $g[1];
            $values[] = $g[2];
            $sectname[] = $g[3];
        }
    }
    
    // INITIALIZING PLOT OBJECT
    $plot = new PHPlot(1200, 475);
    $plot->SetImageBorderType('plain');
    
    // PLOT FONTS
    $plot->SetTTFPath('C:/Windows/Fonts');
    $plot->SetFontTTF('title', 'ARIALBD.TTF', 14);
    $plot->SetFontTTF('x_title', 'ARIALBD.TTF', 12);
    $plot->SetFontTTF('x_label', 'ARIALBD.TTF', 10);
    $plot->SetFontTTF('y_title', 'ARIALBD.TTF', 12);
    $plot->SetFontTTF('y_label', 'ARIALBD.TTF', 10);
    $plot->SetFontTTF('legend', 'ARIALBD.TTF', 10);
    
    // DATA BAR COLORS
    $plot->SetDataColors(array('#CC0000', '#FF0000', '#993300', '#CC3300', '#FF3300', '#CC9900', '#FFCC00', 
                               '#FFFF00', '#006600', '#009900', '#00CC00', '#336666', '#006666', '#009999', 
                               '#0033FF', '#0066FF', '#0099FF', '#000099', '#0000CC', '#0000FF', '#660099', 
                               '#663399', '#9900CC', '#660066', '#990066', '#CC0099', '#FF0999', '#FF00FF', '#FF0080'));
    
    $plot->SetDataBorderColors(array('#CC0000', '#FF0000', '#993300', '#CC3300', '#FF3300', '#CC9900', '#FFCC00', 
                                     '#FFFF00', '#006600', '#009900', '#00CC00', '#336666', '#006666', '#009999', 
                                     '#0033FF', '#0066FF', '#0099FF', '#000099', '#0000CC', '#0000FF', '#660099', 
                                     '#663399', '#9900CC', '#660066', '#990066', '#CC0099', '#FF0999', '#FF00FF', '#FF0080'));
    
    $plot->SetPlotType('bars');
    $plot->SetShading(0);
    
    // PLOT DATA
    $plot->SetDataType('text-data');
    $plot->SetDataValues(array($values));
    
    # MAIN PLOT TITLE
    $plot->SetTitle("\nU.S. Multifactor Productivity, 1987-2015\n");
    $plot->SetDrawDashedGrid(FALSE);
    
    # LEGEND
    $plot->SetLegend($years);
    $plot->SetLegendPosition(1, 0, 'image', 1, 0, -10, 10);
    
    # X AND Y AXIZ TITLES AND TICKS
    $plot->SetXTickLabelPos('none');
    $plot->SetXTickPos('none');
    $plot->SetXTitle($sectname[0]."\n\n");
    $plot->SetYTitle("\nProduct Value\n");
    
    # OUTPUT PLOT TO FILE
    $plot->SetIsInline(TRUE);
    $plot->SetOutputFile($cd.'/GRAPHS/sector_'. $s .'_php.png');
         
    $plot->DrawGraph();
    
}

echo "Successfully produced graphs!\n";

?>