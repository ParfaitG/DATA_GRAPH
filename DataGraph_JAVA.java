import java.util.*;
import java.io.*;
import java.awt.*;

import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartUtilities;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.axis.Axis;
import org.jfree.chart.axis.NumberAxis;
import org.jfree.chart.axis.ValueAxis;
import org.jfree.chart.axis.CategoryAxis;
import org.jfree.chart.labels.ItemLabelAnchor;
import org.jfree.chart.labels.ItemLabelPosition;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.CategoryPlot;
import org.jfree.chart.renderer.category.BarRenderer;
import org.jfree.chart.renderer.category.CategoryItemRenderer;
import org.jfree.chart.renderer.category.StandardBarPainter;
import org.jfree.chart.renderer.xy.XYItemRenderer;
import org.jfree.chart.title.LegendTitle;
import org.jfree.chart.block.ColumnArrangement;
import org.jfree.chart.block.GridArrangement;

import org.jfree.ui.RectangleEdge;
import org.jfree.ui.RectangleInsets;
import org.jfree.data.category.DefaultCategoryDataset;
import org.jfree.data.category.CategoryDataset;
import org.jfree.data.general.DatasetUtilities;

    
public class DataGraph_JAVA
{
   public static void main( String[ ] args )
   {
      String currentDir = new File("").getAbsolutePath();      
      ArrayList<ArrayList<String>> mfpdata = new ArrayList<ArrayList<String>>();
      ArrayList<ArrayList<String>> sectordata = new ArrayList<ArrayList<String>>();
      ArrayList<ArrayList<String>> graphdata = new ArrayList<ArrayList<String>>();
      HashSet<String> sectornames = new HashSet<String>();
      
      try
      {
         String prodFile = currentDir + "\\DATA\\MultifactorProductData.txt";
         String sectFile = currentDir + "\\DATA\\MultifactorSectorData.txt";
         BufferedReader br = null;
         String line = "";
         String txtSplitBy = "\t";
                     
         // PRODUCT DATA
         br = new BufferedReader(new FileReader(prodFile));
         while ((line = br.readLine()) != null) {
                 
            String[] txtdata = line.split(txtSplitBy);
                        
            ArrayList<String> innerdata = new ArrayList<String>();
            
            if (txtdata[0].trim().substring(7).equals("012")) {               
                innerdata.add(txtdata[0].substring(3, 7));        // SECTOR CODE                
                innerdata.add(txtdata[1]);                        // YEAR                     
                innerdata.add(txtdata[3]);                        // VALUE
                
                mfpdata.add(innerdata);
            }
         }
         
         // SECTOR DATA
         br = new BufferedReader(new FileReader(sectFile));
         while ((line = br.readLine()) != null) {
                 
            String[] txtdata = line.split(txtSplitBy);
                        
            ArrayList<String> innerdata = new ArrayList<String>();
            //System.out.println(txtdata[1]);   
            if(txtdata[1].indexOf("(NAICS") > 0) {
                innerdata.add(txtdata[0]);                                                  // SECTOR CODE                
                innerdata.add(txtdata[1].substring(0, txtdata[1].indexOf("(NAICS")));       // SECTOR NAME                     
                innerdata.add(txtdata[1].substring(txtdata[1].indexOf("(NAICS")));          // NAICS
                
                sectordata.add(innerdata);
            }
         }
         
         // MERGE ARRAYS
         for (ArrayList<String> i: mfpdata){
             ArrayList<String> innerdata = i;
             for (ArrayList<String> j: sectordata){
               //System.out.println(i.get(0)+" - "+j.get(0));     
               if (i.get(0).equals(j.get(0))) {
                  innerdata.add(j.get(0));
                  innerdata.add(j.get(1));
                  
                  graphdata.add(innerdata);                                   
               }
             }
         }
         
         // DISTINCT SECTOR NAMES
         for (ArrayList<String> j: sectordata){
            sectornames.add(j.get(0));
         }
         
         // DATA SETS
         for(String s: sectornames) {
            DefaultCategoryDataset dataset = new DefaultCategoryDataset( );
            
            for(ArrayList<String> g: graphdata) {
               
               if (s.equals(g.get(0))) {
                  // PLOT DATASET               
                  dataset.addValue(Float.parseFloat(g.get(2).trim()), g.get(1), g.get(4));
               }
            }

            // PLOT OBJECTS
            JFreeChart barChart = ChartFactory.createBarChart(
               "U.S. Multifactor Productivity, 1987-2015",      // chart title
               "Years",                                         // domain axis label
               "Product Value",                                 // range axis label
               dataset,                                         // data
               PlotOrientation.VERTICAL,                        // the plot orientation
               false,                                           // include legend
               true,
               false);
            
            barChart.getTitle().setPadding(5, 10, 5, 10);
            barChart.setBackgroundPaint(Color.WHITE);
            barChart.getPlot().setBackgroundPaint(Color.WHITE);
            CategoryPlot barPlot = barChart.getCategoryPlot();
            ((BarRenderer) barPlot.getRenderer()).setBarPainter(new StandardBarPainter());
            
            CategoryAxis caxis = barPlot.getDomainAxis();
            ValueAxis vaxis = barPlot.getRangeAxis();
            
            // SERIES COLORS 
            Color c1 = hex2Rgb("#CC0000"); Color c2 = hex2Rgb("#FF0000"); Color c3 = hex2Rgb("#993300");
            Color c4 = hex2Rgb("#CC3300"); Color c5 = hex2Rgb("#FF3300"); Color c6 = hex2Rgb("#CC9900");
            Color c7 = hex2Rgb("#FFCC00"); Color c8 = hex2Rgb("#FFFF00"); Color c9 = hex2Rgb("#006600");
            Color c10 = hex2Rgb("#009900"); Color c11 = hex2Rgb("#00CC00"); Color c12 = hex2Rgb("#336666");
            Color c13 = hex2Rgb("#006666"); Color c14 = hex2Rgb("#009999"); Color c15 = hex2Rgb("#0033FF");
            Color c16 = hex2Rgb("#0066FF"); Color c17 = hex2Rgb("#0099FF"); Color c18 = hex2Rgb("#000099");
            Color c19 = hex2Rgb("#0000CC"); Color c20 = hex2Rgb("#0000FF"); Color c21 = hex2Rgb("#660099");
            Color c22 = hex2Rgb("#663399"); Color c23 = hex2Rgb("#9900CC"); Color c24 = hex2Rgb("#660066");
            Color c25 = hex2Rgb("#990066"); Color c26 = hex2Rgb("#CC0099"); Color c27 = hex2Rgb("#FF0999");
            Color c28 = hex2Rgb("#FF00FF"); Color c29 = hex2Rgb("#FF0080");
            
            Color[] barColors = {c1, c2, c3, c4, c5, c6, c7, c8, c9, c10,
                                 c11, c12, c13, c14, c15 ,c16, c17, c18, c19, c20,
                                 c21, c22, c23, c24, c25, c26, c27, c28, c29};
            
            int i = 0;
            for(Color c: barColors) {         
                ((BarRenderer) barPlot.getRenderer()).setSeriesPaint(i, c);
                i++;
            }
            
            // ADJUSTING FONT
            Font barFont = new Font("Arial", Font.BOLD, 16);
            barChart.getTitle().setFont(barFont);
                  
            barFont = new Font("Arial", Font.BOLD, 12);
            vaxis.setLabelFont(barFont);
            caxis.setLabelFont(barFont);
            
            barFont = new Font("Arial", Font.PLAIN, 12);      
            vaxis.setTickLabelFont(barFont);
            caxis.setTickLabelFont(barFont);
            
            // DATA BAR SPACING
            caxis.setLowerMargin(0.025);
            caxis.setUpperMargin(0.025);      
            caxis.setCategoryMargin(0.025);
            
            // LEGEND SETTINGS
            LegendTitle legend = new LegendTitle(barPlot, new GridArrangement(2, 15), new GridArrangement(2, 15));      
            Font lfont = new Font("Arial", Font.PLAIN, 12); 
            legend.setItemFont(lfont); 
            legend.setPosition(RectangleEdge.BOTTOM);
            legend.setPadding(10.0, 10.0, 10.0, 10.0);
            legend.setMargin(5.0, 5.0, 5.0, 5.0);
            legend.setItemLabelPadding(new RectangleInsets(2, 2, 2, 15));
            barChart.addLegend(legend);     
                  
            int width = 1200; /* Width of the image */
            int height = 400; /* Height of the image */
                 
            BarRenderer brenderer = (BarRenderer) barPlot.getRenderer();
            brenderer.setItemMargin(0.1);
            
            File BarChart = new File(currentDir + "\\GRAPHS\\sector_"+s+"_java.png"); 
            ChartUtilities.saveChartAsJPEG( BarChart , barChart , width , height );
            
         }         
         System.out.println("Successfully produced sector graphs!\n");
         
      } catch (FileNotFoundException ffe) {
         System.out.println(ffe.getMessage());
      } catch (IOException ioe) {
         System.out.println(ioe.getMessage());
      }
   }

   public static Color hex2Rgb(String colorStr) {
    return new Color(
            Integer.valueOf( colorStr.substring( 1, 3 ), 16 ),
            Integer.valueOf( colorStr.substring( 3, 5 ), 16 ),
            Integer.valueOf( colorStr.substring( 5, 7 ), 16 ) );
   }

}