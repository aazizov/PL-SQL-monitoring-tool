## PL/SQL monitoring tool
For monitoring of Unprocessed Radius(or another system need to monitoring) requests, was created monitoring tool with alarming by email. Approach of this tool, based on the Model-based monitoring logic. For flexible monitoring of complex system, we have forced to continuous compare current data with renewing averaged Model. For this purpose, on the Oracle Database was created:
1. **Tables** :
    a. **radius_stats** - logging table for collecting of current data(unprocessed requests);
    b. **radius_stats_avg** - model table for comparing with current current 10 minutes data.

2. **Procedure** :
    **radius_stats_proc** - for :
        a. logging - collecting data, 
        b. comparing current data with averaged model
        c. sending email

3. **Job** :
    **Radius_Stats_Job** - for launch above mentioned processes by scheduler for every 10 minutes


