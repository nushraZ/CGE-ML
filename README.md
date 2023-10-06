# CGE-ML Project Repository

## Table of Contents

1. [Overview](#overview)
2. [Project Workflow](#project-workflow)
3. [Repository Contents](#repository-contents)

## Overview

This repository contains resources and documentation for the CGE-ML (Computable General Equilibrium - Machine Learning) project. 

It aims to enhance economic resilience by integrating machine learning techniques. The goal is to apply ML-based reverse engineering to CGE models and optimize Economic strategies in response to various shocks and hazards.

## Project Workflow
The CGE-ML project follows the following workflow:

### Machine Learning Integration:
- **Predictors**: The shock data is used as predictors (independent variables). It is required to be in dollar amounts of base capital stock LOST. 
- **Outcome Variables**:  There are four main economic factors that we are concerned with: DDS, DY, MIGT, DFFD
  For all these factors above, we predict two types of model:
    - **Main Model**: The sum of CGE model output, representing the total economic impact. For example, predicting the total DDS for DDS.
    - **Sector-Specific Models**: Separate models for each economic sector (GoodsA, TradeB,.. etc.).
- **Model Training**:
  - We employ Elastic Net regression to train the machine learning models.
  - Cross-validation techniques are used to ensure model performance.
- **Coefficients Extraction**:
  - Coefficients are extracted from the trained models.
  - Coefficients represent the relationships between shock data and economic impact.
- **Optimization Models**:
  These coefficients will be applied to optimization models for informed decision-making and policy planning.
-  **Test Bed Replication**:
  The project is designed to be replicated for every other testbed.

## Repository Contents

- [Data Dictionary](https://github.com/nushraZ/CGE-ML/blob/main/Data_Dictionary.md): Brief overview of the datasets being used



