param workspaceLocation string {
  metadata: {
    description: 'Specify the workspace region'
  }
  default: ''
}
param workspaceName string {
  metadata: {
    description: 'Specify the workspace name'
  }
  default: ''
}

var omsSolutions = {
  customSolution: {
    name: 'Azure Backup Monitoring Solution'
    solutionName: 'AzureBackup[${workspaceName}]'
    publisher: 'Microsoft'
    displayName: 'Azure Backup Monitoring Solution'
    description: 'Monitor and analyze your Backup Vaults'
    author: 'Microsoft'
  }
}

resource workspaceName_res 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: workspaceName
  location: workspaceLocation
}

resource workspaceName_Azure_Backup_Monitoring_Solution 'Microsoft.OperationalInsights/workspaces/views@2015-11-01-preview' = {
  name: '${workspaceName}/Azure Backup Monitoring Solution'
  location: workspaceLocation
  properties: {
    Name: omsSolutions.customSolution.name
    Author: omsSolutions.customSolution.author
    Source: 'Local'
    Version: 2
    Dashboard: [
      {
        Id: 'InformationBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            Title: 'Azure Backup Monitoring'
            NewGroup: false
            Color: '#00d8cc'
          }
          Header: {
            Image: 'data:image/png;base64,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'
            Label: 'Monitoring Solution pack for Azure Backup'
            Link: {
              Label: 'More info'
              Url: 'https://azure.microsoft.com/en-us/services/backup/'
            }
          }
          List: [
            {
              Title: 'Monitor Azure Backup!'
              Content: '## Welcome to the monitoring solution of Azure Backup!\nYou can view:\n\n1.  **Backup Jobs** and what backup jobs *failed*\n2. **Restore jobs** and what restore jobs *failed*\n3. **Critical Alerts** that need your urgent attention\n4. **Cloud Storage in GB** view along with **Top 5** datasources backed up along with their storage in GB\n5. **Data sources** being backed up\n\n\n[Microsoft](https://assets.onestore.ms/cdnfiles/onestorerolling-1607-15000/shell/v3/images/logo/microsoft.png "Microsoft")'
            }
          ]
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Backup Jobs Breakdown (Non Log)'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Backup Jobs Breakdown (Non Log)'
            Subtitle: ''
          }
          Donut: {
            Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Job" | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where JobOperation_s == "Backup" and JobOperationSubType_s != "Log" and JobOperationSubType_s != "Recovery point_Log" | summarize AggregatedValue = dcount(JobUniqueId_g) by JobStatus_s | order by AggregatedValue desc'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#55d455'
                '#ba141a'
                '#00bcf2'
              ]
              valueColorMapping: [
                {
                  value: 'Completed'
                  color: '#55d455'
                }
                {
                  value: 'Failed'
                  color: '#ba141a'
                }
              ]
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed" and JobOperationSubType_s != "Log" and JobOperationSubType_s != "Recovery point_Log" | distinct JobUniqueId_g, BackupItemUniqueId_s, JobStatus_s, Resource | project BackupItemUniqueId_s, JobStatus_s, Resource | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s ) on BackupItemUniqueId_s | project BackupItemFriendlyName_s, BackupItemUniqueId_s, JobStatus_s, Resource | extend Vault= Resource | summarize count() by BackupItemFriendlyName_s, JobStatus_s, Vault, BackupItemUniqueId_s  | order by count_ desc'
            HideGraph: true
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Data Sources'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed" and JobOperationSubType_s != "Log" and JobOperationSubType_s != "Recovery point_Log" | distinct JobUniqueId_g, BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | project BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s, RecommendedAction_s  | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s, BackupItemUniqueId_s , ProtectedContainerFriendlyName_s, BackupItemType_s, JobStatus_s, Resource, JobFailureCode_s | extend Vault= Resource | where {selected item}'
            NavigationSelect: {
              NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed" and JobOperationSubType_s != "Log" and JobOperationSubType_s != "Recovery point_Log" | distinct JobUniqueId_g, BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | project BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s, RecommendedAction_s  | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s, BackupItemUniqueId_s , ProtectedContainerFriendlyName_s, BackupItemType_s, JobStatus_s, Resource, JobFailureCode_s | extend Vault= Resource | where {selected item}'
            }
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Backup Jobs BreakDown (Log)'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Backup Jobs Breakdown (Log)'
            Subtitle: ''
          }
          Donut: {
            Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Job" | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where JobOperation_s == "Backup" and (JobOperationSubType_s == "Log" or JobOperationSubType_s == "Recovery point_Log") | summarize AggregatedValue = dcount(JobUniqueId_g) by JobStatus_s | order by AggregatedValue desc'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#00188f'
                '#0072c6'
                '#00bcf2'
              ]
              valueColorMapping: [
                {
                  value: 'Completed'
                  color: '#55d455'
                }
                {
                  value: 'Failed'
                  color: '#dd5900'
                }
              ]
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed" and (JobOperationSubType_s == "Log" or JobOperationSubType_s == "Recovery point_Log") | project BackupItemUniqueId_s, JobStatus_s, Resource | join kind=inner (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s ) on BackupItemUniqueId_s | project BackupItemFriendlyName_s , JobStatus_s, Resource | extend Vault= Resource | summarize count() by BackupItemFriendlyName_s, JobStatus_s, Vault | order by count_ desc'
            HideGraph: true
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Datasources'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed" and (JobOperationSubType_s == "Log" or JobOperationSubType_s == "Recovery point_Log") | project BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | join kind=inner (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s, BackupItemUniqueId_s, ProtectedContainerFriendlyName_s, BackupItemType_s, JobStatus_s, Resource, JobFailureCode_s | extend Vault= Resource | where {selected item}'
            NavigationSelect: {
              NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where OperationName == "Job" and JobOperation_s == "Backup" and JobStatus_s == "Failed" and (JobOperationSubType_s == "Log" or JobOperationSubType_s == "Recovery point_Log") | project BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | join kind=inner (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s, BackupItemUniqueId_s, ProtectedContainerFriendlyName_s, BackupItemType_s, JobStatus_s, Resource, JobFailureCode_s | extend Vault= Resource | where {selected item}'
            }
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Restore Jobs Breakdown'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Restore Jobs Breakdown'
            Subtitle: ''
          }
          Donut: {
            Query: 'AzureDiagnostics  | where Category == "AzureBackupReport"      | where OperationName == "Job"     | where JobOperation_s == "Restore"  or JobOperation_s == "Recovery"    | summarize AggregatedValue = dcount(JobUniqueId_g) by JobStatus_s  | order by AggregatedValue desc'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#007233'
                '#ba141a'
                '#00bcf2'
              ]
              valueColorMapping: [
                {
                  value: 'Cancelled'
                  color: '#fff100'
                }
                {
                  value: 'Completed'
                  color: '#007233'
                }
                {
                  value: 'Failed'
                  color: '#ba141a'
                }
              ]
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | where OperationName == "Job" and JobOperation_s == "Restore" or JobOperation_s == "Recovery" and JobStatus_s == "Failed" | distinct JobUniqueId_g, BackupItemUniqueId_s, JobStatus_s, Resource | project BackupItemUniqueId_s, JobStatus_s, Resource | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s ) on BackupItemUniqueId_s | project BackupItemFriendlyName_s, BackupItemUniqueId_s, JobStatus_s, Resource | extend Vault= Resource | summarize count() by BackupItemFriendlyName_s, BackupItemUniqueId_s , JobStatus_s, Vault | order by count_ desc'
            HideGraph: true
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Data Sources'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | where OperationName == "Job" and JobOperation_s == "Restore" or JobOperation_s == "Recovery" and JobStatus_s == "Failed" | distinct JobUniqueId_g, BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | project BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s, BackupItemUniqueId_s, ProtectedContainerFriendlyName_s, BackupItemType_s, JobStatus_s, Resource, JobFailureCode_s | extend Vault= Resource  | where {selected item}'
            NavigationSelect: {
              NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport" ; Events | where OperationName == "Job" and JobOperation_s == "Restore" or JobOperation_s == "Recovery" and JobStatus_s == "Failed" | distinct JobUniqueId_g, BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | project BackupItemUniqueId_s, ProtectedContainerUniqueId_s, JobStatus_s, Resource, JobFailureCode_s | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s     | project BackupItemUniqueId_s , BackupItemFriendlyName_s, BackupItemName_s, BackupItemType_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s, BackupItemUniqueId_s, ProtectedContainerFriendlyName_s, BackupItemType_s, JobStatus_s, Resource, JobFailureCode_s | extend Vault= Resource  | where {selected item}'
            }
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Alerts from Azure Resources Backup'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Active Alert Distribution '
            Subtitle: ''
          }
          Donut: {
            Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Alert" | where AlertUniqueId_s != "" | summarize arg_max(TimeGenerated, *) by AlertUniqueId_s  | extend CurrentStatus = AlertStatus_s  | join  (AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_s ) on AlertUniqueId_s  | project AlertUniqueId_s, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s | where CurrentStatus == "Active" | summarize count() by AlertSeverity_s'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#e81123'
                '#008272'
                '#00bcf2'
              ]
              valueColorMapping: [
                {
                  value: 'Critical'
                  color: '#e81123'
                }
                {
                  value: 'Warning'
                  color: '#fff100'
                }
                {
                  value: 'Information'
                  color: '#55d455'
                }
              ]
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "Alert" | where AlertUniqueId_s != "" | summarize lastOccurred = arg_max(TimeGenerated, *) by AlertUniqueId_s  | extend CurrentStatus = AlertStatus_s  | join  (Events | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_s ) on AlertUniqueId_s  | project AlertUniqueId_s, lastOccurred, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s, BackupItemUniqueId_s, RecommendedAction_s | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s     | project BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s ) on BackupItemUniqueId_s | project BackupItemName_s, AlertCode_s, HitCount | order by HitCount desc'
            HideGraph: true
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Data Sources'
              Value: 'HitCount'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "Alert" | where AlertUniqueId_s != "" | summarize lastOccurred = arg_max(TimeGenerated, *) by AlertUniqueId_s  | extend CurrentStatus = AlertStatus_s  | join  (Events | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_s ) on AlertUniqueId_s  | project AlertUniqueId_s, lastOccurred, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s, BackupItemUniqueId_s, RecommendedAction_s, Resource | join kind=inner (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s     | project BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s ) on BackupItemUniqueId_s | project AlertCode_s, lastOccurred, BackupItemName_s, CurrentStatus, AlertSeverity_s, HitCount, RecommendedAction_s, Resource | extend Vault= Resource | where {selected item}'
            NavigationSelect: {
              NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "Alert" | where AlertUniqueId_s != "" | summarize lastOccurred = arg_max(TimeGenerated, *) by AlertUniqueId_s  | extend CurrentStatus = AlertStatus_s  | join  (Events | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_s ) on AlertUniqueId_s  | project AlertUniqueId_s, lastOccurred, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s, BackupItemUniqueId_s, RecommendedAction_s, Resource | join kind=inner (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s     | project BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s ) on BackupItemUniqueId_s | project AlertCode_s, lastOccurred, BackupItemName_s, CurrentStatus, AlertSeverity_s, HitCount, RecommendedAction_s, Resource | extend Vault= Resource | where {selected item}'
            }
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Alerts from On-prem backup'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Active Alert distribution'
            Subtitle: ''
          }
          Donut: {
            Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Alert" | where AlertUniqueId_g != ""  | summarize arg_max(TimeGenerated, *) by AlertUniqueId_g  | extend CurrentStatus = AlertStatus_s  | join kind= inner (AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_g ) on AlertUniqueId_g | project AlertUniqueId_g, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s | where CurrentStatus == "Active" | summarize count() by AlertSeverity_s'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#00188f'
                '#0072c6'
                '#00bcf2'
              ]
              valueColorMapping: [
                {
                  value: 'Critical'
                  color: '#ba141a'
                }
                {
                  value: 'Warning'
                  color: '#ffb900'
                }
                {
                  value: 'Information'
                  color: '#55d455'
                }
              ]
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "Alert" | where AlertUniqueId_g != "" | summarize lastOccurred = arg_max(TimeGenerated, *) by AlertUniqueId_g  | extend CurrentStatus = AlertStatus_s  | join  (Events | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_g ) on AlertUniqueId_g  | project AlertUniqueId_g, lastOccurred, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s, BackupItemUniqueId_s, RecommendedAction_s | where CurrentStatus == "Active" | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s     | project BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s ) on BackupItemUniqueId_s | project BackupItemName_s, AlertCode_s, HitCount | order by HitCount desc'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Computer'
              Value: 'Count'
            }
            Color: '#0072c6'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "Alert" | where AlertUniqueId_g != ""  | summarize lastOccurred = arg_max(TimeGenerated, *) by AlertUniqueId_g  | extend CurrentStatus = AlertStatus_s  | join kind=inner  (Events | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_g ) on AlertUniqueId_g  | project AlertUniqueId_g, BackupManagementServerUniqueId_s, ProtectedContainerUniqueId_s ,lastOccurred, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s, BackupItemUniqueId_s, RecommendedAction_s, Resource | where CurrentStatus == "Active" | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s     | project BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | join kind=leftouter( Events     | where OperationName == "BackupManagementServer"     | distinct BackupManagmentServerUniqueId_s, BackupManagmentServerName_s     | project BackupManagmentServerUniqueId_s, BackupManagmentServerName_s ) on $left.BackupManagementServerUniqueId_s == $right.BackupManagmentServerUniqueId_s | project AlertCode_s, lastOccurred, BackupItemName_s, ProtectedContainerFriendlyName_s, BackupManagmentServerName_s, CurrentStatus, AlertSeverity_s, HitCount, RecommendedAction_s, Resource | extend Vault= Resource | project-away Resource | where {selected item}'
            NavigationSelect: {
              NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "Alert" | where AlertUniqueId_g != ""  | summarize lastOccurred = arg_max(TimeGenerated, *) by AlertUniqueId_g  | extend CurrentStatus = AlertStatus_s  | join kind=inner  (Events | where OperationName == "Alert" | where AlertStatus_s == "Active" | summarize HitCount = count() by AlertUniqueId_g ) on AlertUniqueId_g  | project AlertUniqueId_g, BackupManagementServerUniqueId_s, ProtectedContainerUniqueId_s ,lastOccurred, HitCount , CurrentStatus , AlertCode_s, AlertSeverity_s, BackupItemUniqueId_s, RecommendedAction_s, Resource | where CurrentStatus == "Active" | join kind=leftouter (     Events     | where OperationName == "BackupItem"     | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s     | project BackupItemUniqueId_s, BackupItemFriendlyName_s, BackupItemName_s ) on BackupItemUniqueId_s | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | join kind=leftouter( Events     | where OperationName == "BackupManagementServer"     | distinct BackupManagmentServerUniqueId_s, BackupManagmentServerName_s     | project BackupManagmentServerUniqueId_s, BackupManagmentServerName_s ) on $left.BackupManagementServerUniqueId_s == $right.BackupManagmentServerUniqueId_s | project AlertCode_s, lastOccurred, BackupItemName_s, ProtectedContainerFriendlyName_s, BackupManagmentServerName_s, CurrentStatus, AlertSeverity_s, HitCount, RecommendedAction_s, Resource | extend Vault= Resource | project-away Resource | where {selected item}'
            }
          }
        }
      }
      {
        Id: 'SingleQueryDonutBuilderBladeV1'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Active Datasources Protected'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Last known Protection status'
            Subtitle: ''
          }
          Donut: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "BackupItem" | where BackupItemProtectionState_s != ""  | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId_s, BackupItemProtectionState_s | summarize dcount(BackupItemUniqueId_s) by BackupItemProtectionState_s'
            CenterLegend: {
              Text: 'Total'
              Operation: 'Sum'
              ArcsToSelect: []
            }
            Options: {
              colors: [
                '#ff8c00'
                '#55d455'
                '#6dc2e9'
              ]
              valueColorMapping: []
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "BackupItem" | where BackupItemProtectionState_s != ""  | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s ,BackupItemType_s, BackupManagementType_s, BackupItemProtectionState_s, BackupItemUniqueId_s | summarize dcount(BackupItemUniqueId_s) by BackupManagementType_s,BackupItemProtectionState_s | order by BackupManagementType_s desc'
            HideGraph: true
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'BackupManagement Type'
              Value: 'BackupItems'
            }
            Color: '#ff8c00'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "BackupItem" | where BackupItemProtectionState_s != ""  | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s ,BackupItemType_s, BackupManagementType_s, BackupItemProtectionState_s, BackupItemUniqueId_s, ProtectedContainerUniqueId_s, Resource | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s ,BackupItemType_s, BackupManagementType_s, BackupItemProtectionState_s, BackupItemUniqueId_s, ProtectedContainerFriendlyName_s, Resource | extend Vault= Resource | project-away Resource | where {selected item}'
            NavigationSelect: {
              NavigationQuery: 'let Events = AzureDiagnostics | where Category == "AzureBackupReport"; Events | where OperationName == "BackupItem" | where BackupItemProtectionState_s != ""  | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s ,BackupItemType_s, BackupManagementType_s, BackupItemProtectionState_s, BackupItemUniqueId_s, ProtectedContainerUniqueId_s, Resource | join kind=leftouter (     Events     | where OperationName == "ProtectedContainer"     | distinct ProtectedContainerUniqueId_s, ProtectedContainerFriendlyName_s     | project ProtectedContainerUniqueId_s , ProtectedContainerFriendlyName_s ) on ProtectedContainerUniqueId_s | project BackupItemFriendlyName_s, BackupItemName_s ,BackupItemType_s, BackupManagementType_s, BackupItemProtectionState_s, BackupItemUniqueId_s, ProtectedContainerFriendlyName_s, Resource | extend Vault= Resource | project-away Resource | where {selected item}'
            }
          }
        }
      }
      {
        Id: 'LineChartBuilderBlade'
        Type: 'Blade'
        Version: 0
        Configuration: {
          General: {
            title: 'Cloud Storage in GB'
            newGroup: false
            icon: ''
            useIcon: false
          }
          Header: {
            Title: 'Cloud storage in GB'
            Subtitle: ''
          }
          LineChart: {
            Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "StorageAssociation" | extend CloudStorageInGB = todouble(StorageConsumedInMBs_s) / 1024 | project CloudStorageInGB, BackupItemUniqueId_s, StorageUniqueId_s, TimeGenerated | join kind=inner (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "Storage"    | distinct StorageUniqueId_s, StorageType_s    | project StorageUniqueId_s, StorageType_s  ) on StorageUniqueId_s | where StorageType_s == "Cloud" | summarize dayCharge = avg(CloudStorageInGB)  by BackupItemUniqueId_s, bin(TimeGenerated, 1d) | summarize TotalCharge = sum(dayCharge) by bin(TimeGenerated, 1d)'
            yAxis: {
              isLogarithmic: false
              units: {
                baseUnitType: ''
                baseUnit: ''
                displayUnit: ''
              }
              customLabel: 'Cloud Storage (GB)'
            }
            NavigationSelect: {}
          }
          List: {
            Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "StorageAssociation" | summarize arg_max(TimeGenerated, *) by BackupItemUniqueId_s, StorageUniqueId_s | extend StorageInGB = todouble(StorageConsumedInMBs_s) / 1024 | project StorageInGB, BackupItemUniqueId_s, StorageUniqueId_s | join kind=inner (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "Storage"    | distinct StorageUniqueId_s, StorageType_s    | project StorageUniqueId_s, StorageType_s  ) on StorageUniqueId_s | project StorageInGB, BackupItemUniqueId_s, StorageType_s | join kind=leftouter (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "BackupItem"    | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s    | project BackupItemUniqueId_s, BackupItemFriendlyName_s ) on BackupItemUniqueId_s | project StorageInGB, BackupItemFriendlyName_s, BackupItemUniqueId_s, StorageType_s | where StorageType_s == "Cloud" | order by StorageInGB desc'
            HideGraph: false
            enableSparklines: false
            operation: 'Summary'
            ColumnsTitle: {
              Name: 'Data Sources'
              Value: 'Cloud Data in GB'
            }
            Color: '#eb3c00'
            thresholds: {
              isEnabled: false
              values: [
                {
                  name: 'Normal'
                  threshold: 'Default'
                  color: '#009e49'
                  isDefault: true
                }
                {
                  name: 'Warning'
                  threshold: '60'
                  color: '#fcd116'
                  isDefault: false
                }
                {
                  name: 'Error'
                  threshold: '90'
                  color: '#ba141a'
                  isDefault: false
                }
              ]
            }
            NameDSVSeparator: ''
            NavigationQuery: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "StorageAssociation" | extend StorageInGB = todouble(StorageConsumedInMBs_s) / 1024 | project StorageInGB, BackupItemUniqueId_s, StorageUniqueId_s, TimeGenerated | join kind=inner (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "Storage"    | distinct StorageUniqueId_s, StorageType_s    | project StorageUniqueId_s, StorageType_s  ) on StorageUniqueId_s | where StorageType_s == "Cloud"    | project StorageInGB, BackupItemUniqueId_s, StorageType_s, TimeGenerated | join kind=leftouter (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "BackupItem"    | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s    | project BackupItemUniqueId_s, BackupItemFriendlyName_s ) on BackupItemUniqueId_s | project StorageInGB, BackupItemFriendlyName_s, BackupItemUniqueId_s, StorageType_s, TimeGenerated | where {selected item} | summarize dayCharge = avg(StorageInGB)  by BackupItemUniqueId_s, bin(TimeGenerated, 1d)'
            NavigationSelect: {
              NavigationQuery: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "StorageAssociation" | extend StorageInGB = todouble(StorageConsumedInMBs_s) / 1024 | project StorageInGB, BackupItemUniqueId_s, StorageUniqueId_s, TimeGenerated | join kind=inner (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "Storage"    | distinct StorageUniqueId_s, StorageType_s    | project StorageUniqueId_s, StorageType_s  ) on StorageUniqueId_s | where StorageType_s == "Cloud"    | project StorageInGB, BackupItemUniqueId_s, StorageType_s, TimeGenerated | join kind=leftouter (    AzureDiagnostics    | where Category == "AzureBackupReport"    | where OperationName == "BackupItem"    | distinct BackupItemUniqueId_s, BackupItemFriendlyName_s    | project BackupItemUniqueId_s, BackupItemFriendlyName_s ) on BackupItemUniqueId_s | project StorageInGB, BackupItemFriendlyName_s, BackupItemUniqueId_s, StorageType_s, TimeGenerated | where {selected item} | summarize dayCharge = avg(StorageInGB)  by BackupItemUniqueId_s, bin(TimeGenerated, 1d)'
            }
          }
        }
      }
    ]
    OverviewTile: {
      Id: 'SingleQueryDonutBuilderTileV1'
      Type: 'OverviewTile'
      Version: 2
      Configuration: {
        Donut: {
          Query: 'AzureDiagnostics | where Category == "AzureBackupReport" | where OperationName == "Job" | extend JobOperationSubType_s = columnifexists("JobOperationSubType_s", "") | where JobOperation_s == "Backup" and JobOperationSubType_s != "Log" and JobOperationSubType_s != "Recovery point_Log" | summarize AggregatedValue = dcount(JobUniqueId_g) by JobStatus_s | order by AggregatedValue desc'
          CenterLegend: {
            Text: 'Total'
            Operation: 'Sum'
            ArcsToSelect: []
          }
          Options: {
            colors: [
              '#55d455'
              '#e81123'
              '#00bcf2'
            ]
            valueColorMapping: [
              {
                value: 'Completed'
                color: '#55d455'
              }
              {
                value: 'Failed'
                color: '#ba141a'
              }
            ]
          }
        }
        Advanced: {
          DataFlowVerification: {
            Enabled: false
            Query: 'search * | limit 1 | project TimeGenerated'
            Message: ''
          }
        }
      }
    }
  }
  dependsOn: [
    workspaceName_res
  ]
}

resource workspaceName_omsSolutions_customSolution_solutionName 'Microsoft.OperationalInsights/workspaces/Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: '${workspaceName}/${omsSolutions.customSolution.solutionName}'
  location: workspaceLocation
  plan: {
    name: omsSolutions.customSolution.solutionName
    product: omsSolutions.customSolution.name
    publisher: omsSolutions.customSolution.publisher
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: workspaceName_res.id
    referencedResources: []
    containedResources: [
      resourceId('Microsoft.OperationalInsights/workspaces/views/', workspaceName, omsSolutions.customSolution.name)
    ]
  }
  dependsOn: [
    'Microsoft.OperationalInsights/workspaces/${workspaceName}/views/${omsSolutions.customSolution.name}'
  ]
}