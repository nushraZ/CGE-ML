# Coefficients Documentation

This document provides documentation for the coefficients obtained from machine learning models. The coefficients are arranged in a wide format, where each row corresponds to a model(ModelName: the variable we are predicting), and the columns represent the coefficient values specific to each model.

## Column Definitions

- **Testbed:** (Column A)
The name of the test bed for which the coefficients were generated.

- **Hazard Type:** (Column B)
The type of hazard simulation associated with the coefficients.

- **Model Type:** (Column C)
 Indicates whether the model is a main model (predicting total economic impact) or a sub-model (predicting economic impact for a specific sector-Puma combination).

- **Model Name:** (Column D)
The outcome variable or target variable for the model, representing what is being predicted.

(Column E and onwards are the coefficients).


** The first row will typically be the main model row, and then onwards we have the sectorPuma models. This is true for every economic factors (DDS, DY, MIGT, DFFD).

## Coefficients Format and Interpretation

The coefficients are organized in columns, and there are 48 coefficients for every model. These coefficients indicate how much each predictor variable influences the outcome variable. 
**Magnitude and Sign of the coefficients**: The magnitude represents the strength of association between the corresponding predictor and target variable. A stronger magnitude (positive or negative) means a stronger influence. And, the sign indicates the direction of influence.

 The coefficient value for a specific sector in the model also helps us estimate the impact on the overall economic indicator (totDDS – in case of main model or “GoodsA” (a sector) – in case of sub model) for that sector

**Naming Conventions**
Each sector should be named as name of sector followed by the Puma region it belongs to. Here are a few examples: 
Goodsj 
Tradej 
Otherj 
HS1j (Housing Services 1) 
HS2j (Housing Services 2) 
HS2j (Housing Services 3) 
Here, j represents the Puma regions: A, B, …, H.  




