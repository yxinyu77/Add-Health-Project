# Add Health Project – Supplemental Materials

This repository contains the **supplemental materials** for the research project  
**“Adolescent Physical Activity and Long-Term Obesity Risk: Evidence from Add Health.”**

All **code, data, and documentation** are organized so that an interested reader can
**reproduce the full analysis step by step**, including data cleaning, empirical analysis,
and simulation studies.

---

## Repository Structure

```text

Add-Health-Project/
│
├── README.md
│
├── data/
│ ├── wave1.csv # Add Health Wave I public-use data
│ └── wave4.csv # Add Health Wave IV public-use data
│
├── documentation/
│ ├── W1inhome_codebook.pdf # Wave I questionnaire codebook
│ └── W4inhome_codebook.pdf # Wave IV questionnaire codebook
│
├── shared_setup.R # Shared data cleaning & variable construction
│
├── analysis/ # REAL DATA ANALYSIS
│ ├── real_method_1.Rmd # Logistic regression (Wald inference)
│ ├── real_method_2.Rmd # Spline logistic regression + bootstrap
│ └── real_method_3.Rmd # Logistic regression + jackknife
│
├── simulations/ # SIMULATION STUDIES
│ ├── sim_method_1.Rmd # Simulation for Method 1
│ ├── sim_method_2.Rmd # Simulation for Method 2
│ └── sim_method_3.Rmd # Simulation for Method 3
│
└── figures/ # Auto-generated plots

```

---

## Data Sources

The empirical analysis uses **public-use data** from the  
**National Longitudinal Study of Adolescent to Adult Health (Add Health)**:

- **Wave I (1994–1995):** adolescent physical activity, demographics, baseline health  
- **Wave IV (2008):** adult anthropometric outcomes

Official Add Health codebooks are included in the `documentation/` folder and were used
to guide variable definitions, response coding, and missing-data handling.

Because public-use files do not include full survey design variables (PSUs, strata, or
weights), all analyses treat observations as approximately independent and are interpreted
as **associational**, not design-based population estimates.

---

## Data Cleaning and Variable Construction

All data processing is centralized in:


This file is sourced by **all analysis and simulation scripts** to ensure consistency.

Key steps include:

- Linking respondents across waves using the Add Health identifier (`AID`)
- Recoding Add Health special response codes (e.g., refused, don’t know) as missing
- Constructing adolescent MVPA using midpoint recoding of Wave I activity items
- Computing baseline BMI from self-reported Wave I height and weight
- Computing adult BMI from measured Wave IV data and defining obesity as BMI ≥ 30
- Excluding implausible BMI values
- Restricting to respondents with complete data on key variables

All transformations are explicitly coded and documented in `shared_setup.R`.

---

## Reproducing the Real-Data Analysis

To reproduce the empirical results reported in the paper, run the following files **in order**:

1. **Method 1: Linear logistic regression (Wald inference)**  

2. **Method 2: Flexible logistic regression with spline + bootstrap**  

3. **Method 3: Logistic regression with grouped jackknife variance estimation**  

Each file automatically loads the cleaned analytic dataset and produces the tables and
figures used in the paper.

---

## Reproducing the Simulation Studies

Simulation-based validation is implemented in:


These scripts generate synthetic data under specified data-generating mechanisms and
evaluate bias, variability, mean squared error, and confidence interval coverage for each
method. Random seeds are set to ensure reproducibility.

---

## Software Requirements

All analyses were conducted in **R (version ≥ 4.2.0)**.

Required packages include:
- tidyverse
- ggplot2
- splines
- boot
- broom
- rmarkdown
- knitr

Each `.Rmd` file loads the necessary packages at the top.

---

## Quick Links (Clickable Code)

### Real Data Analysis (Empirical Results)
These files perform the analysis using the Add Health Waves I and IV data.

- [Method 1: Logistic regression (Wald inference)](https://github.com/yxinyu77/Add-Health-Project/blob/main/real_method_1.Rmd)
- [Method 2: Spline logistic regression + bootstrap](https://github.com/yxinyu77/Add-Health-Project/blob/main/real_method_2.Rmd)
- [Method 3: Logistic regression + jackknife variance estimation](https://github.com/yxinyu77/Add-Health-Project/blob/main/real_method_3.Rmd)

---

### Simulation Studies (Method Evaluation)
These files implement Monte Carlo simulations to evaluate the statistical properties
(bias, variance, MSE, and confidence interval coverage) of the three methods.

- [Simulation for Method 1](https://github.com/yxinyu77/Add-Health-Project/blob/main/sim_method_1.Rmd)
- [Simulation for Method 2](https://github.com/yxinyu77/Add-Health-Project/blob/main/sim_method_2.Rmd)
- [Simulation for Method 3](https://github.com/yxinyu77/Add-Health-Project/blob/main/sim_method_3.Rmd)

---

### Simulation Results and Figures
This file aggregates the simulation outputs and **produces the figures and tables**
summarizing simulation results reported in the paper.

- [Simulation results and figure generation](https://github.com/yxinyu77/Add-Health-Project/blob/main/simulation.Rmd)

---

### Shared Code and Data Preparation
This script is sourced by all analysis and simulation files and contains the shared
data cleaning, variable construction, and preprocessing steps.

- [Shared setup and data preparation](https://github.com/yxinyu77/Add-Health-Project/blob/main/shared_setup.R)


---

## Notes

This repository accompanies the final project for **STATS 406**.  
All results in the paper can be reproduced using the files provided here.
