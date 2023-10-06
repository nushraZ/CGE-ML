# Data Dictionary

This file is made to keep everything organized. It also helps provide clarity for the terminology and datasets used in this project. 

## Brief descriptions of Datasets used in ML model

### Hazard Realization 
- **Shocks**: Contains hazard realizations with epicenter and magnitude. **Units**: dollar amount of capital stock lost.
   [NOTE: We received the data in the form of percentages representing capital stock remaining. However, to analyze the impact, we needed to convert these percentages into dollar amounts of capital stock lost. We accomplished this by converting the percentages to Capital Stock LOST, and multiplying it to the base capital stock.]

### CGE Outputs
- **DDS**: Delta Domestic Supply; units: millions of USD 
    - Has 6 categories of business sector in Puma region j (j = A, B, …, H): Goodsj, Tradej, Otherj, HS1j, HS2j, HS3j.
- **DY**: Delta Household Income; **units**: millions of USD 
    - Contains categories of household: HHij (i = 1, 2, …, 5; j = A, B, …, H) in income group i in region j. i = 1 is the group with the lowest income, 5 being the highest.
- **MIGT**: Change in Migration; **units**: number of households 
    - Contains categories of household: HHij (i = 1, 2, …, 5; j = A, B, …, H) in income group i in region j. i = 1 is the group with the lowest income, 5 being the highest.
- **DFFD**: Change in Employment; **units**: number of employment 
    - labor groups k (k=1,2,3) in business sectors in region j (j = A, B, …, H): Goodsj_Lk, Tradej_Lk, Otherj_Lk. k = 1 is the labor group with the lowest income, and k = 3 is the labor group with the highest income.


