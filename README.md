- Deploy the sample [PBIX](./Contoso-Partitioned.pbix) on a workspace 
- Run [PBIX](./Script - CreatePartitions.ps1) to create the partitions

# Script - CreatePartitions.ps1

Creates the partitions for the 'Sales' Fact table, other tables dont require partitioning

# Script - DatasetRefresh - API.ps1

Script that uses the [Enhanced Refresh API](https://docs.microsoft.com/en-us/power-bi/connect-data/asynchronous-refresh) to refresh the dataset in two independent batches with different refresh configuration for each

# Script - DatasetRefresh - Unprocessed.ps1

This script is useful for the first refresh of the dataset, it fetches all the unprocessed partitions and process them in batches