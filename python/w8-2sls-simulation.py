import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
import seaborn as sns
from statsmodels.api import OLS
from statsmodels.sandbox.regression.gmm import IV2SLS

# Set a seed for reproducibility
np.random.seed(42)

# Define the true value of beta (coefficient for x1)
true_beta = 0.95

# Define correlations between variables
corr_x1_x2 = -0.1  # Correlation between x1 and x2
corr_x1_z = 0.25  # Correlation between x1 and the instrument z
corr_x1_e = 0  # Correlation between x1 and the error term e
corr_x2_z = 0  # Correlation between x2 and the instrument z
corr_x2_e = 0  # Correlation between x2 and the error term e
corr_z_e = 0  # Correlation between the instrument z and the error term e

# Define the number of observations
obs = 1000

# Define the mean vector for the multivariate normal distribution
mean_vector = [0, 0, 0, 0]

# Define the covariance matrix based on the correlations
covariance_matrix = np.array([
    # row x1
    [1, corr_x1_x2, corr_x1_z, corr_x1_e],
    # row x2
    [corr_x1_x2, 1, corr_x2_z, corr_x2_e],
    # row z
    [corr_x1_z, corr_x2_z, 1, corr_z_e],
    # row e
    [corr_x1_e, corr_x2_e, corr_z_e, 1]
])


# Function to generate the full dataset
def generate_full_data(obs, true_beta, mean_vector, covariance_matrix):
    # Generate data from a multivariate normal distribution
    out = np.random.multivariate_normal(mean_vector, covariance_matrix, obs)
    df = pd.DataFrame(out, columns=["x1", "x2", "z", "e"])
    # Create the dependent variable y
    df['y'] = 0.5 + true_beta * df['x1'] + 0.5 * df['x2'] + df['e']
    df = df[['y', 'x1', 'x2', 'z', 'e']]  # Reorder columns to match R
    return df


# Generate the initial dataset
df = generate_full_data(obs, true_beta, mean_vector, covariance_matrix)
df.head()

# Estimate and display OLS regressions
# OLS with x1 and x2
model_ols_1 = OLS(df['y'], df[['x1', 'x2']]).fit()
print(model_ols_1.summary())

# OLS with only x1
model_ols_2 = OLS(df['y'], df['x1']).fit()
print(model_ols_2.summary())


# Estimate and display 2SLS (IV) regression
# 2SLS: y regressed on x1, instrumented by z
iv_model = IV2SLS(df['y'], df['x1'], df['z']).fit() # y, exogenous, endogenous, instrument
print(iv_model.summary())


# Function to perform one iteration of the simulation
def get_one_iteration(iteration):
    # Generate a new dataset for this iteration
    df = generate_full_data(obs, true_beta, mean_vector, covariance_matrix)

    # Estimate OLS and IV regressions
    model_ols = OLS(df['y'], df['x1']).fit()  # OLS with x1
    ols_coef = model_ols.params["x1"]

    iv_model = IV2SLS(df['y'], df['x1'], df['z']).fit()  # 2SLS with x1 instrumented by z
    iv_coef = iv_model.params["x1"]

    # Extract coefficients and store them in a dictionary
    out = {
        'iter': iteration,  # Iteration number
        'ols': ols_coef,  # OLS coefficient for x1
        'iv': iv_coef  # IV coefficient for x1
    }
    return out


# Run one iteration of the simulation (for testing)
get_one_iteration(1)


# Run the simulation 1000 times and store the results
results = [get_one_iteration(i) for i in range(1, 1001)]
results_df = pd.DataFrame(results)

# Display a glimpse of the results
print(results_df.head())

# Generate descriptive statistics of the results
print(results_df.describe())

# Visualize the distribution of the OLS and IV estimates
sns.kdeplot(data=results_df['iv'], label='IV Estimate')
sns.kdeplot(data=results_df['ols'], label='OLS Estimate')
plt.axvline(x=true_beta, color='r', linestyle='dashed', label='True Beta')
plt.legend()
plt.show()
