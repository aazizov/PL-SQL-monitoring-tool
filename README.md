## PL/SQL monitoring tool
For monitoring of Unprocessed Radius(or another system need to monitoring) requests, was created monitoring tool with alarming by email. Approach of this tool, based on the Model-based monitoring logic. For flexible monitoring of complex system, we have forced to continuous compare current data with renewing averaged Model. For this purpose, on the Oracle Database was created:
1. **Tables** :<br>
    a. **radius_stats** - logging table for collecting of current data(unprocessed requests),<br>
    b. **radius_stats_avg** - model table for comparing with current current 10 minutes data.

2. **Procedure** :<br>
    **radius_stats_proc** - for :<br>
        a. logging - collecting data,<br> 
        b. comparing current data with averaged model,<br>
        c. sending email.<br>

3. **Job** :<br>
    **Radius_Stats_Job** - for launch above mentioned processes by scheduler for every 10 minutes.
