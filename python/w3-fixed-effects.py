import os

import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import pyfixest as pf

# Set working directory
os.chdir("/workspaces/coding-with-ai")

# Load data
ab_data = pd.read_csv("data/ab_data.csv", usecols=["EMP", "WAGE", "W", "N", "K", "YS", "ID", "YEAR", "IND"])

# Data overview
pd.set_option('display.max_columns', None)
ab_data.describe()

# Scatterplot of W on N
plt.figure()
# Enable interactive mode
plt.ion()
plt.scatter(ab_data["EMP"], ab_data["WAGE"])

# Add linear regression line
m, b = np.polyfit(ab_data["EMP"], ab_data["WAGE"], 1)
plt.plot(ab_data["EMP"], m*ab_data["EMP"] + b, color="red")

plt.xlabel("Employment")
plt.ylabel("Wages")
plt.show()
plt.savefig("outputs/pl1.png")
plt.close()

labels = {
    "EMP": "Employment",
    "WAGE": "Wage",
    "W": "Log wage",
    "N": "Log employment",
    "K": "Log capital",
    "YS": "Log industry output",
    "ID": "Firm",
    "YEAR": "Year",
    "IND": "Industry"
}

# baseline regression
est1 = pf.feols("W ~ N + K + YS | ID + YEAR", data=ab_data, vcov = {'CRV1':'ID'})
est1.summary()
est1.tidy()
pf.etable(est1, signif_code=[0.01, 0.05, 0.1], show_se_type=False, labels=labels)

# sensitivity to fixed effects specifications
est2 = pf.feols("W ~ N + K + YS | csw0(ID, YEAR)", data=ab_data, vcov = {'CRV1':'ID'})
pf.etable(est2, signif_code=[0.01, 0.05, 0.1], show_se_type=False, labels=labels)

# heterogeneity analysis via subsamples
est3 = pf.feols("W ~ N + K + YS | ID + YEAR", data=ab_data, vcov = {'CRV1':'ID'}, split = "IND")
pf.etable(est3, signif_code=[0.01, 0.05, 0.1], show_se_type=False, labels=labels)

# robustness - subset sample for firms in 1980s
est4 = pf.feols("W ~ N + K + YS | ID + YEAR", data=ab_data.query('YEAR >= 1980'), vcov = {'CRV1':'ID'})
pf.etable(est4, signif_code=[0.01, 0.05, 0.1], show_se_type=False, labels=labels)
