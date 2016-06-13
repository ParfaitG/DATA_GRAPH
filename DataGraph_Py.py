#!/usr/bin/python
import os
import pandas as pd
import numpy as np
from matplotlib import rc, pyplot as plt
import seaborn

pd.set_option('display.width', 1000)
cd = os.path.dirname(os.path.abspath(__file__))

# IMPORT DATA FRAMES
'''PRODUCT DATA'''
mfpdf = pd.read_table(os.path.join(cd, "DATA", "MultifactorProductData.txt"), sep="\t", usecols=[0,1,3])
mfpdf['series_id'] = mfpdf['series_id'].str.strip()
mfpdf['sector_code'] = mfpdf['series_id'].str[3:7].astype('int64')
mfpdf = mfpdf[mfpdf['series_id'].str.endswith('012')]

'''SECTOR DATA'''
sectordf = pd.read_table(os.path.join(cd, "DATA", "MultifactorSectorData.txt"), sep="\t",
                         index_col=False, usecols=[0, 1])
mfpdf = pd.merge(mfpdf, sectordf, on=['sector_code'])
mfpdf['NAICS'] = mfpdf['sector_name'].str.extract('(\(NAICS.*)', expand=False)
mfpdf['sector_name'] = mfpdf['sector_name'].str.extract('(.*) \(NAICS', expand=False)

# DISTINCT SECTORS        
sectorlist = set(mfpdf['sector_code'].tolist())

# CONFIGURE PLOT
font = {'family' : 'arial', 'weight' : 'bold', 'size'   : 10}
rc('font', **font); rc("figure", facecolor="white"); rc('axes', edgecolor='darkgray')

seaborn.set()

def runplot(pvtdf, filename):        
    pvtdf.plot(kind='bar', edgecolor='w',figsize=(15,5), width=2, fontsize = 10)
    locs, labels = plt.xticks()    
    plt.title('U.S. MultiFactor Productivity, 1987-2015', weight='bold', size=14)
    plt.legend(loc='upper center', ncol=14, frameon=True, shadow=False, prop={'size':8},
               bbox_to_anchor=(0.5, -0.05))    
    plt.xlabel('Year', weight='bold', size=12)
    plt.ylabel('Value', weight='bold', size=12)
    plt.tick_params(axis='x', bottom='off', top='off')
    plt.tick_params(axis='y', left='off', right='off')
    plt.ylim([0,120])
    plt.grid(b=True)
    plt.setp(labels, rotation=0, rotation_mode="anchor", ha="center")
    plt.tight_layout()
    plt.savefig(filename)
    plt.clf()
    plt.close()

# RUN PLOTS AND SAVE TO FILE
for s in sectorlist:
    sumtable = mfpdf[mfpdf['sector_code'] == s].pivot_table(values='value', index=['sector_name'],
                                                        columns=['year'], aggfunc=sum)
    sfile = os.path.join(cd, 'Graphs', 'sector_{}_py.png'.format(str(s)))
    runplot(sumtable, sfile)
    
print("Successfully produced graphs!")
