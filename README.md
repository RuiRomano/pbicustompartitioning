# Deployment Steps
- Deploy the sample [PBIX](./Contoso-Partitioned.pbix) on a workspace 
- Run [PBIX](./Script - CreatePartitions.ps1) to create the partitions
- Deploy the [Logic App](./LogicApp - Refresh.json) to an Azure Subscription
- Enable Logic App Managed Identity
- Authorize the Managed Identity to connect to Power BI (workspace & 'Allow service principals to use Power BI APIs' tenant setting)
- Execute the logic app to refresh your dataset


# Script - CreatePartitions.ps1

Creates the partitions for the 'Sales' Fact table, other tables dont require partitioning

# Script - DatasetRefresh - API.ps1

Script that uses the [Enhanced Refresh API](https://docs.microsoft.com/en-us/power-bi/connect-data/asynchronous-refresh) to refresh the dataset in two independent batches with different refresh configuration for each

# Script - DatasetRefresh - Unprocessed.ps1

This script is useful for the first refresh of the dataset, it fetches all the unprocessed partitions and process them in batches
_