import numpy as np
import pandas as pd

import matplotlib
import matplotlib.pyplot as plt
import seaborn as sns

#####################################
### DATA IMPORT
#####################################
energy_df = pd.read_csv(r"DATA\EIA Energy Consumption by Sector.csv")

str(energy_df)

print(energy_df['Description'].unique())

#####################################
### DATA CLEAN
#####################################

energy_dict = {
    "Primary Energy Consumed by the Residential Sector": "Residential",
    "Primary Energy Consumed by the Commercial Sector": "Commercial",
    "Primary Energy Consumed by the Industrial Sector": "Industrial",
    "Primary Energy Consumed by the Transportation Sector": "Transportation",
    "Primary Energy Consumed by the Electric Power Sector": "Electric Power",
    "Primary Energy Consumption Total" : "All",
    "Total Energy Consumed by the Residential Sector"  : "Residential",
    "Total Energy Consumed by the Commercial Sector": "Commercial",
    "Total Energy Consumed by the Industrial Sector": "Industrial",
    "Total Energy Consumed by the Transportation Sector": "Transportation",
    "Energy Consumption Balancing Item": "Other"
}

energy_df = (
    energy_df.assign(
        YYYYMM = lambda df: df["YYYYMM"].astype('str'),
        Date = lambda df: pd.to_datetime(
            np.where(
                df["YYYYMM"].str[-2:] == "13", 
                df["YYYYMM"].str[:4].str.cat(["1231"]*len(energy_df)),
                df["YYYYMM"].str.cat(["01"]*len(energy_df))                
            ),
            format="%Y%m%d"
        ),
        Sector = lambda df: df["Description"].replace(energy_dict),
        Energy_Type = lambda df: np.where(
            df["Description"].str.contains("Primary Energy"), 
            "Primary",
            np.where(
                df["Description"].str.contains("Total Energy"),
                "Total",
                np.where(
                    df["Description"].eq("Energy Consumption Balancing Item"),
                    "Other", 
                    np.nan,
                )
            )
        )
    )
)


print(energy_df)

print(energy_df.dtypes)


#####################################
### PLOT BUILD
#####################################

graph_sectors = ["Residential", "Commercial", "Industrial", "Transportation"]
graph_df = energy_df[
    (energy_df["Sector"].isin(graph_sectors)) &
    (energy_df["Energy_Type"].eq("Total")) &
    (energy_df["Date"].dt.month == 12) & 
    (energy_df["Date"].dt.day == 31)
]

### MATPLOTLIB

font = {'family' : 'Arial'}
matplotlib.rc('font', **font)

fig, ax = plt.subplots(figsize=(12,6))

pvt_df = graph_df.pivot_table(
    index="Date", columns="Sector", values="Value", aggfunc="max"
)
pvt_df.plot(kind="line", ax=ax)

ax.set(ylim=(0, 4E4))
ax.yaxis.grid(True)
ax.set_yticklabels(['{:,}'.format(int(x)) for x in ax.get_yticks().tolist()])

plt.title("Total U.S. Energy Consumption", fontsize=18, fontweight="bold")
plt.xlabel("Date", fontsize=12)
plt.ylabel("Trillions Btus", fontsize=12)
fig.text(0.125, 0.025, "Source: U.S. Department of Energy, EIA", ha='left')

plt.tight_layout()
plt.show()
fig.savefig("Line_Graph_Build_Python_matplotlib.png", dpi=fig.dpi)
plt.clf()
plt.close()



### SEABORN
sns.set_style("whitegrid")
fig, ax = plt.subplots(figsize=(12,6))

sns.lineplot(
    x = "Date", 
    y = "Value",
    hue = "Sector", 
    data = graph_df,
    ax = ax,
    ci = None,
)

ax.set(ylim=(0, 4E4))
ax.xaxis.grid(False)
ax.set_yticklabels(['{:,}'.format(int(x)) for x in ax.get_yticks().tolist()])

plt.title("Total U.S. Energy Consumption", fontsize=18, fontweight="bold")
plt.xlabel("Date", fontsize=12)
plt.ylabel("Trillions Btus", fontsize=12)
fig.text(0.125, 0.025, "Source: U.S. Department of Energy, EIA", ha='left')

plt.show()
fig.savefig("Line_Graph_Build_Python_seaborn.png", dpi=fig.dpi)
plt.clf()
plt.close()















