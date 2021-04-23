@description('Name of the Logic App to be created.')
param logicAppName string = 'Usage'

@description('Azure region in which the Logic App should be created.')
param location string = resourceGroup().location

@description('Name of the existing Log Analytics workspace that the Logic App should connect to. Note that the Logic App connects to a single workspace, but can query data across multiple workspaces. Use the \'Workspaces To Query\' parameter to specify the list of workspaces that the Logic App should query data from.')
param logicAppWorkspace string

@description('Subscription Id of the existing Log Analytics workspace that the Logic App should connect to.')
param workspaceSubscriptionId string

@description('Resource Group name of the existing Log Analytics workspace that the Logic App should connect to.')
param workspaceResourceGroup string

@description('List of workspaces that the Logic App should query data from. Should be a comma-separated array of values of the format [\'/subscriptions/{subscriptionId1}/resourceGroups/{resourceGroupName1}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName1}\',\'/subscriptions/{subscriptionId2}/resourceGroups/{resourceGroupName2}/providers/Microsoft.OperationalInsights/workspaces/{workspaceName2}\']')
param workspacesToQuery array

@allowed([
  'Day'
  'Week'
  'Month'
])
@description('Frequency at whch emails should be received by the recipient(s). Select \'Day\' for sending emails once a day, \'Week\' for sending emails once a week, or \'Month\' for sending emails once a month.')
param emailFrequency string = 'Day'

@description('Email id of the recipient(s). To specify multiple email ids, use a semicolon-separated list.')
param recipientEmailId string

@description('Start Date and Time (in UTC) of the data to be queried by the Logic App. Use yyyy-MM-dd HH:mm:ssZ format.')
param startDate string = dateTimeAdd(utcNow('u'), '-P7D')

@description('End Date and Time (in UTC) of the data to be queried by the Logic App. Use yyyy-MM-dd HH:mm:ssZ format.')
param endDate string = utcNow('u')

@description('Use to filter data queried by the Logic App to a limited set of subscriptions in which Recovery Services vaults exist. Should be of the format \'{subscriptionId1},{subscriptionId2},..\'. Default value is \'*\', which enables the Logic App to query data across all backup subscriptions that are sending data to the specified Log Analytics workspaces.')
param vaultSubscriptionListFilter string = '*'

@description('Use to filter data queried by the Logic App to a limited set of regions in which Recovery Services vaults exist. Should be of the format \'location1,location2,..\' (eg. eastus,westus). Default value is \'*\', which enables the Logic App to query data for vaults across all Azure regions in the specified subscriptions.')
param vaultLocationListFilter string = '*'

@description('Use to filter data queried by the Logic App to a limited set of Recovery Services vaults. Should be of the format \'vaultname1,vaultname2,..\'. Default value is \'*\', which enables the Logic App to query data for all vaults in the specified subscriptions and locations.')
param vaultListFilter string = '*'

@description('Use to filter data queried by the Logic App to a limited set of Azure Backup solutions being used in your environment. Should be of the format \'solution1,solution2,..\' (eg. Azure VM Backup,SQL in Azure VM Backup,DPM). Default value is \'*\', which enables the Logic App to query data across all Azure Backup solutions being used.')
param backupSolutionListFilter string = '*'

@description('Selecting \'true\' enables the Logic App to avoid querying data that is sent to the legacy Azure Diagnostics table in the Log Analytics workspace(s). Excluding the legacy table improves query performance time.')
param excludeLegacyEvent bool = true

@allowed([
  'Daily'
  'Weekly'
  'Monthly'
])
@description('Use to specify the granularity at which data is sampled in the case of trend graphs.')
param aggregationType string = 'Daily'

@description('Tags to be assigned to the Logic App and the API connection resources.')
param resourceTags object = {
  UsedByBackupReports: 'true'
}

@description('Subject of the email to be received by the recipient(s).')
param emailSubject string = 'Usage'

var office365ConnectionName_var = '${location}-office365'
var azureMonitorLogsConnectionName_var = '${location}-azuremonitorlogs'

resource office365ConnectionName 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: office365ConnectionName_var
  location: location
  tags: resourceTags
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
    }
    displayName: 'office365'
  }
}

resource azureMonitorLogsConnectionName 'Microsoft.Web/connections@2018-07-01-preview' = {
  name: azureMonitorLogsConnectionName_var
  location: location
  tags: resourceTags
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuremonitorlogs')
    }
    displayName: 'azuremonitorlogs'
  }
}

resource logicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: resourceTags
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
        dataToExport: {
          defaultValue: 'Usage'
          type: 'String'
        }
        aggregationType: {
          defaultValue: '"${aggregationType}"'
          type: 'String'
        }
        backupSolutionListFilter: {
          defaultValue: '"${backupSolutionListFilter}"'
          type: 'String'
        }
        excludeLegacyEvent: {
          defaultValue: excludeLegacyEvent
          type: 'Bool'
        }
        endDate: {
          defaultValue: endDate
          type: 'String'
        }
        startDate: {
          defaultValue: startDate
          type: 'String'
        }
        vaultListFilter: {
          defaultValue: '"${vaultListFilter}"'
          type: 'String'
        }
        vaultLocationListFilter: {
          defaultValue: '"${vaultLocationListFilter}"'
          type: 'String'
        }
        vaultSubscriptionListFilter: {
          defaultValue: '"${vaultSubscriptionListFilter}"'
          type: 'String'
        }
        workspacesToQuery: {
          defaultValue: workspacesToQuery
          type: 'Array'
        }
      }
      triggers: {
        Recurrence: {
          recurrence: {
            frequency: emailFrequency
            interval: 1
          }
          type: 'Recurrence'
        }
      }
      actions: {
        For_each: {
          foreach: '@parameters(\'workspacesToQuery\')'
          actions: {
            Append_to_string_variable: {
              type: 'AppendToStringVariable'
              inputs: {
                name: 'AzureDiagnostics_Incomplete'
                value: ' workspace(\'@{items(\'For_each\')}\').AzureDiagnostics,'
              }
            }
            Append_to_string_variable_2: {
              runAfter: {
                Append_to_string_variable: [
                  'Succeeded'
                ]
              }
              type: 'AppendToStringVariable'
              inputs: {
                name: 'CoreAzureBackup_Incomplete'
                value: ' workspace(\'@{items(\'For_each\')}\').CoreAzureBackup,'
              }
            }
            Append_to_string_variable_3: {
              runAfter: {
                Append_to_string_variable_2: [
                  'Succeeded'
                ]
              }
              type: 'AppendToStringVariable'
              inputs: {
                name: 'AddonAzureBackupJobs_Incomplete'
                value: ' workspace(\'@{items(\'For_each\')}\').AddonAzureBackupJobs,'
              }
            }
            Append_to_string_variable_4: {
              runAfter: {
                Append_to_string_variable_3: [
                  'Succeeded'
                ]
              }
              type: 'AppendToStringVariable'
              inputs: {
                name: 'AddonAzureBackupPolicy_Incomplete'
                value: ' workspace(\'@{items(\'For_each\')}\').AddonAzureBackupPolicy,'
              }
            }
            Append_to_string_variable_5: {
              runAfter: {
                Append_to_string_variable_4: [
                  'Succeeded'
                ]
              }
              type: 'AppendToStringVariable'
              inputs: {
                name: 'AddonAzureBackupProtectedInstance_Incomplete'
                value: ' workspace(\'@{items(\'For_each\')}\').AddonAzureBackupProtectedInstance,'
              }
            }
            Append_to_string_variable_6: {
              runAfter: {
                Append_to_string_variable_5: [
                  'Succeeded'
                ]
              }
              type: 'AppendToStringVariable'
              inputs: {
                name: 'AddonAzureBackupStorage_Incomplete'
                value: ' workspace(\'@{items(\'For_each\')}\').AddonAzureBackupStorage,'
              }
            }
          }
          runAfter: {
            'Initialize_variable-AddonAzureBackupStorage': [
              'Succeeded'
            ]
          }
          type: 'Foreach'
        }
        If_Scope_Failed: {
          actions: {
            'Send_an_email_(V2)-FailureRun': {
              type: 'ApiConnection'
              inputs: {
                body: {
                  Body: '<p>The Logic App Run did not execute to completion. <br>\n<br>Status: @{result(\'Scope\')[0][\'status\']}<br><br> <a href=\'https://aka.ms/AzureBackupReportEmail\'>Learn more</a> about how to troubleshoot the error</p>'
                  Subject: emailSubject
                  To: recipientEmailId
                }
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/v2/Mail'
              }
            }
          }
          runAfter: {
            Scope: [
              'Succeeded'
              'Failed'
              'Skipped'
              'TimedOut'
            ]
          }
          else: {
            actions: {
              'Send_an_email_(V2)-SuccessfulRun': {
                type: 'ApiConnection'
                inputs: {
                  body: {
                    Attachments: [
                      {
                        ContentBytes: '@{body(\'Run_query_and_visualize_results-BillingGroupTrend\')?[\'attachmentContent\']}'
                        Name: '@body(\'Run_query_and_visualize_results-BillingGroupTrend\')?[\'attachmentName\']'
                      }
                      {
                        ContentBytes: '@{body(\'Run_query_and_visualize_results-CloudStorageTrend\')?[\'attachmentContent\']}'
                        Name: '@body(\'Run_query_and_visualize_results-CloudStorageTrend\')?[\'attachmentName\']'
                      }
                      {
                        ContentBytes: '@{base64(body(\'Create_CSV_table-BillingGroupList\'))}'
                        Name: 'BillingGroupList.csv'
                      }
                    ]
                    Body: '<p><u><strong><br>\nUsage Report<br>\n</strong></u><u><strong><br>\nEmail Contents<br>\n</strong></u><br>\n1. <b>Inline</b> <br>a. Trend of protected instance count over time <br>b. Trend of backup cloud storage (GB) consumed over time<br>2. <b>Attachments </b> <br>a. List of all billin groups with details on protected instance count, total cloud storage consumed (GB), storage replication type etc. <br><br> <a href=\'https://aka.ms/AzureBackupReportDocs\'>Learn more</a> about Backup Reports<br>\n<br>\n<u><strong>@{variables(\'visual\')}</strong></u><u><strong><br>\n<br>\n<br>\n</strong></u><br>\n<br>\n</p>'
                    Subject: emailSubject
                    To: recipientEmailId
                  }
                  host: {
                    connection: {
                      name: '@parameters(\'$connections\')[\'office365\'][\'connectionId\']'
                    }
                  }
                  method: 'post'
                  path: '/v2/Mail'
                }
              }
            }
          }
          expression: {
            or: [
              {
                equals: [
                  '@result(\'Scope\')[0][\'status\']'
                  'Failed'
                ]
              }
              {
                equals: [
                  '@result(\'Scope\')[0][\'status\']'
                  'Aborted'
                ]
              }
              {
                equals: [
                  '@result(\'Scope\')[0][\'status\']'
                  'Skipped'
                ]
              }
              {
                equals: [
                  '@result(\'Scope\')[0][\'status\']'
                  'TimedOut'
                ]
              }
            ]
          }
          type: 'If'
        }
        'Initialize_variable-NoDataMessage': {
          inputs: {
            variables: [
              {
                name: 'NoDataMessage'
                type: 'array'
                value: [
                  {
                    Message: 'No records found'
                  }
                ]
              }
            ]
          }
          runAfter: {
            'Initialize_variable-EmailBodyForSuccessfulRun': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
        }
        'Initialize_variable-AddonAzureBackupJobs': {
          runAfter: {
            'Initialize_variable-CoreAzureBackup': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'AddonAzureBackupJobs_Incomplete'
                type: 'string'
                value: 'let AddonAzureBackupJobs = ()\n{\nunion'
              }
            ]
          }
        }
        'Initialize_variable-AddonAzureBackupPolicy': {
          runAfter: {
            'Initialize_variable-AddonAzureBackupJobs': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'AddonAzureBackupPolicy_Incomplete'
                type: 'string'
                value: 'let AddonAzureBackupPolicy = ()\n{\nunion'
              }
            ]
          }
        }
        'Initialize_variable-AddonAzureBackupProtectedInstance': {
          runAfter: {
            'Initialize_variable-AddonAzureBackupPolicy': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'AddonAzureBackupProtectedInstance_Incomplete'
                type: 'string'
                value: 'let AddonAzureBackupProtectedInstance = ()\n{\nunion'
              }
            ]
          }
        }
        'Initialize_variable-AddonAzureBackupStorage': {
          runAfter: {
            'Initialize_variable-AddonAzureBackupProtectedInstance': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'AddonAzureBackupStorage_Incomplete'
                type: 'string'
                value: 'let AddonAzureBackupStorage = ()\n{\nunion'
              }
            ]
          }
        }
        'Initialize_variable-AzureDiagnostics': {
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'AzureDiagnostics_Incomplete'
                type: 'string'
                value: 'let AzureDiagnostics = ()\n{\nunion'
              }
            ]
          }
        }
        'Initialize_variable-BillingGroupFunction': {
          runAfter: {
            'Initialize_variable-ReportFilterForLatestData': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'BillingGroupFunction'
                type: 'string'
                value: '@{variables(\'workspacesToQuery_Custom\')}\n@{variables(\'ReportFilter_Latest\')}\nlet _BillingGroupName = "*";\n//Other Vars\nlet AsonDay =  _RangeEnd-1d;\nlet AzureStorageCutoffDate = datetime(6/01/2020, 12:00:00.000 AM);\nlet AzureStorageProtectedInstanceCountCutoffDate = datetime(2/01/2021, 12:00:00.000 AM);\n// HelperFunctions\nlet Extend_BackupSolution = (T:(BackupManagementType:string, BackupItemType:string))\n{\nT | extend BackupSolution = iff(BackupManagementType == "IaaSVM", "Azure Virtual Machine Backup", \niff(BackupManagementType == "MAB", "Azure Backup Agent", \niff(BackupManagementType == "DPM", "DPM", \niff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", \niff(BackupManagementType == "AzureStorage", "Azure Storage (Azure Files) Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", "SQL in Azure VM Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", "SAP HANA in Azure VM Backup", "")))))))\n};\n// Source Tables\nlet VaultUnderAzureDiagnostics = ()\n{\nAzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "Vault" and columnifexists("SchemaVersion_s", "") == "V2"\n| project VaultName = columnifexists("VaultName_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), VaultTags = columnifexists("VaultTags_s", ""), AzureDataCenter =  columnifexists("AzureDataCenter_s", ""), ResourceGroupName =  columnifexists("ResourceGroupName_s", ""), SubscriptionId = toupper(SubscriptionId), StorageReplicationType = columnifexists("StorageReplicationType_s", ""), ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated\n};\nlet VaultUnderResourceSpecific = ()\n{\nCoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "Vault" \n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId = toupper(SubscriptionId), ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n};\nlet ResourceIdListUnderAzureDiagnostics = materialize(VaultUnderAzureDiagnostics | distinct ResourceId);\nlet ResourceIdListUnderResourceSpecific = materialize(VaultUnderResourceSpecific | distinct ResourceId);\nlet BackupItemUnderAzureDiagnostics = ()\n{\nlet SourceBackupItemTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "BackupItem" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupItemProtectionState = columnifexists("BackupItemProtectionState_s", ""), BackupItemAppVersion = columnifexists("BackupItemAppVersion_s", ""),SecondaryBackupProtectionState = columnifexists("SecondaryBackupProtectionState_s", ""), BackupItemName = columnifexists("BackupItemName_s", ""), BackupItemFriendlyName = columnifexists("BackupItemFriendlyName_s", ""),\nBackupItemType = columnifexists("BackupItemType_s", ""),  ProtectionGroupName = columnifexists("ProtectionGroupName_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemUnderResourceSpecific = ()\n{\nlet SourceBackupItemTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "BackupItem" and State != "Deleted"\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderResourceSpecific | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemAssociationUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", "") , PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemAssociationUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemAssociationHistoryUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", ""), PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemAssociationTable\n};\nlet BackupItemAssociationHistoryUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemAssociationTable\n};\nlet BackupItemFrontEndSizeHistoryUnderAzureDiagnostics = ()\n{\n let BackupItemFrontEndSizeTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemFrontEndSizeConsumption" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemFrontEndSize = todouble(columnifexists("BackupItemFrontEndSize_s", "")), BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeHistoryUnderResourceSpecific = ()\n{\nlet BackupItemFrontEndSizeTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemFrontEndSizeConsumption" and State != "Deleted"\n| project BackupItemFrontEndSize, BackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeUnderAzureDiagnostics = ()\n{\n let BackupItemFrontEndSizeTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemFrontEndSizeConsumption" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemFrontEndSize = todouble(columnifexists("BackupItemFrontEndSize_s", "")), BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeUnderResourceSpecific = ()\n{\nlet BackupItemFrontEndSizeTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemFrontEndSizeConsumption" and State != "Deleted"\n| project BackupItemFrontEndSize, BackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemFrontEndSizeTable\n};\nlet StorageAssociationHistoryUnderAzureDiagnostics = ()\n{\n let StorageAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "StorageAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), StorageUniqueId = columnifexists("StorageUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), StorageConsumedInMBs = todouble(columnifexists("StorageConsumedInMBs_s", "")), \nStorageAllocatedInMBs = todouble(columnifexists("StorageAllocatedInMBs_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nStorageAssociationTable\n};\nlet StorageAssociationHistoryUnderResourceSpecific = ()\n{\nlet StorageAssociationTable = AddonAzureBackupStorage \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now()) \n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "StorageAssociation" and State != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId, VaultUniqueId, BackupManagementServerUniqueId, StorageUniqueId, StorageConsumedInMBs, StorageAllocatedInMBs, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage") \n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nStorageAssociationTable\n};\nlet StorageAssociationUnderAzureDiagnostics = ()\n{\n let StorageAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "StorageAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), StorageUniqueId = columnifexists("StorageUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), StorageConsumedInMBs = todouble(columnifexists("StorageConsumedInMBs_s", "")), \nStorageAllocatedInMBs = todouble(columnifexists("StorageAllocatedInMBs_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nStorageAssociationTable\n};\nlet StorageAssociationUnderResourceSpecific = ()\n{\nlet StorageAssociationTable = AddonAzureBackupStorage \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "StorageAssociation" and State != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId, VaultUniqueId, BackupManagementServerUniqueId, StorageUniqueId, StorageConsumedInMBs, StorageAllocatedInMBs, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nStorageAssociationTable\n};\nlet ProtectedContainerUnderAzureDiagnostics = ()\n{\nlet ProtectedContainerTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "ProtectedContainer"  and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""),  ProtectedContainerFriendlyName = columnifexists("ProtectedContainerFriendlyName_s", ""), AgentVersion = columnifexists("AgentVersion_s", ""),\nProtectedContainerOSType = columnifexists("ProtectedContainerOSType_s", ""), ProtectedContainerOSVersion = columnifexists("ProtectedContainerOSVersion_s", ""), ProtectedContainerWorkloadType = columnifexists("ProtectedContainerWorkloadType_s", ""),  ProtectedContainerName = columnifexists("ProtectedContainerName_s", ""), ProtectedContainerProtectionState = columnifexists("ProtectedContainerProtectionState_s", ""), ProtectedContainerLocation = columnifexists("ProtectedContainerLocation_s", ""), ProtectedContainerType = columnifexists("ProtectedContainerType_s", ""),\nBackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   ProtectedContainerTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet ProtectedContainerUnderResourceSpecific = ()\n{\nlet ProtectedContainerTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "ProtectedContainer" and State != "Deleted"\n| project ProtectedContainerUniqueId,  ProtectedContainerFriendlyName, AgentVersion,\nProtectedContainerOSType, ProtectedContainerOSVersion, ProtectedContainerWorkloadType,  ProtectedContainerName, ProtectedContainerProtectionState, ProtectedContainerLocation, ProtectedContainerType,\nBackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderResourceSpecific | join   (\n   ProtectedContainerTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet ProtectedInstanceUnderAzureDiagnostics = (isProtectedContainerBillingType:bool)\n{\n let ProtectedInstanceTable = AzureDiagnostics \n| where Category == "AzureBackupReport" and OperationName == "ProtectedInstance" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""),\n ProtectedInstanceCount = toint(columnifexists("ProtectedInstanceCount_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId;\nProtectedInstanceTable\n};\nlet ProtectedInstanceUnderResourceSpecific = (isProtectedContainerBillingType:bool)\n{\nlet ProtectedInstanceTable = AddonAzureBackupProtectedInstance \n| where OperationName == "ProtectedInstance" and State != "Deleted"\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId;\nProtectedInstanceTable\n};\nlet ProtectedInstanceHistoryUnderAzureDiagnostics = (isProtectedContainerBillingType:bool)\n{\n let ProtectedInstanceTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "ProtectedInstance" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""),\n ProtectedInstanceCount = toint(columnifexists("ProtectedInstanceCount_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage") \n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nProtectedInstanceTable\n};\nlet ProtectedInstanceHistoryUnderResourceSpecific = (isProtectedContainerBillingType:bool)\n{\nlet ProtectedInstanceTable = AddonAzureBackupProtectedInstance \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "ProtectedInstance" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId, TimeRangeEndDay = startofday(TimeGenerated)\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay;\nProtectedInstanceTable\n};\n// BusinessLogic\nlet LatestBackupItemDimensionTable = () {union isfuzzy = true \n(BackupItemUnderAzureDiagnostics()),\n(BackupItemUnderResourceSpecific())\n| where BackupItemUniqueId != ""\n// To show as per as on \'AsonDay\'\n| where startofday(TimeGenerated) == AsonDay\n| summarize arg_max(TimeGenerated, *)  by BackupItemUniqueId\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or  BackupItemFriendlyName contains (_BillingGroupName)\n| extend BackupItemProtectionState = iff(BackupItemProtectionState in ("Protected", "ActivelyProtected","ProtectionError"), "Protected", iff(BackupItemProtectionState in ("IRPending"), "InitialBackupPending", iff(isnotempty(BackupItemProtectionState),"ProtectionStopped",BackupItemProtectionState)))\n//| where BackupItemProtectionState in~ (_ProtectionInfoList) or \'*\' in (_ProtectionInfoList)\n| project BackupItemUniqueId,  BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nStorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter};\nlet TotalBackupItemDimensionTable = () {union isfuzzy = true \n(BackupItemUnderAzureDiagnostics()),\n(BackupItemUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *)   by BackupItemUniqueId\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or  BackupItemFriendlyName contains (_BillingGroupName)\n| extend BackupItemProtectionState = iff(BackupItemProtectionState in ("Protected", "ActivelyProtected","ProtectionError"), "Protected", iff(BackupItemProtectionState in ("IRPending"), "InitialBackupPending", iff(isnotempty(BackupItemProtectionState),"ProtectionStopped",BackupItemProtectionState)))\n//| where BackupItemProtectionState in~ (_ProtectionInfoList) or \'*\' in (_ProtectionInfoList)\n| project BackupItemUniqueId,  BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nStorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter};\nlet BI_CombinationUnderAzureDiagnostics = ()\n{\nlet Base = () {ProtectedContainerUnderAzureDiagnostics | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n| join kind= rightouter  (\n    BackupItemAssociationUnderAzureDiagnostics \n\t// To show as per as on \'AsonDay\'\n\t| where startofday(TimeGenerated) == AsonDay\n\t| project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n) on ProtectedContainerUniqueId \n| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n};\nlet Base_Size = ()\n{\nBase\n| join kind= leftouter (\n   BackupItemFrontEndSizeUnderAzureDiagnostics | where startofday(TimeGenerated) == AsonDay | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated \n) on BackupItemUniqueId\n// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n| join kind= leftouter (\n   StorageAssociationUnderAzureDiagnostics | where startofday(TimeGenerated) == AsonDay | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated\n) on BackupItemUniqueId\n| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n StorageConsumedInMBs, TimeGenerated, ResourceId\n};\nBase_Size\n};\nlet BI_CombinationUnderResourceSpecific = ()\n{\nlet Base = () {ProtectedContainerUnderResourceSpecific | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n| join kind= rightouter  (\n    BackupItemAssociationUnderResourceSpecific \n\t// To show as per as on \'AsonDay\'\n\t| where startofday(TimeGenerated) == AsonDay\n\t| project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n) on ProtectedContainerUniqueId \n| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n};\nlet Base_Size = ()\n{\nBase\n| join kind= leftouter (\n   BackupItemFrontEndSizeUnderResourceSpecific | where startofday(TimeGenerated) == AsonDay | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated \n) on BackupItemUniqueId\n// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n| join kind= leftouter (\n   StorageAssociationUnderResourceSpecific | where startofday(TimeGenerated) == AsonDay | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated\n) on BackupItemUniqueId\n| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n StorageConsumedInMBs, TimeGenerated, ResourceId\n};\nBase_Size\n};\nlet BI_HistoryCombinationUnderAzureDiagnostics = ()\n{\t\n\tlet Base = ()\n\t{\n\tProtectedContainerUnderAzureDiagnostics | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n\t| join  kind= rightouter  (\n\t\tBackupItemAssociationHistoryUnderAzureDiagnostics |  project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t) on ProtectedContainerUniqueId\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size = ()\n\t{\n\tBase\n\t| join kind= leftouter (\n\t   BackupItemFrontEndSizeHistoryUnderAzureDiagnostics | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay \n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n\t| join kind= leftouter (\n\t   StorageAssociationHistoryUnderAzureDiagnostics | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay\n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\nBase_Size\n};\nlet BI_HistoryCombinationUnderResourceSpecific = ()\n{\n\tlet Base = ()\n\t{\n\tProtectedContainerUnderResourceSpecific | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n\t| join  kind= rightouter  (\n\t\tBackupItemAssociationHistoryUnderResourceSpecific |  project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t) on ProtectedContainerUniqueId\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size = ()\n\t{\n\tBase\n\t| join kind= leftouter (\n\t   BackupItemFrontEndSizeHistoryUnderResourceSpecific | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay \n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n\t| join kind= leftouter (\n\t   StorageAssociationHistoryUnderResourceSpecific | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay\n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tBase_Size\n};\nlet LatestBackupItemAssociationAndStorageConsumptionTable = ()\n{\nLatestBackupItemDimensionTable | join \n(union isfuzzy = true  \n(BI_CombinationUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false),\n(BI_CombinationUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId\n)on BackupItemUniqueId\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or ProtectedContainerFriendlyName contains (_BillingGroupName)\n| project BackupItemUniqueId, BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nVaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, TimeGenerated,  ResourceId,  ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, PolicyUniqueId, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementServerUniqueId, StorageReplicationType, TimeRangeEndDay = startofday(TimeGenerated)\n};\nlet LatestBackupItemAssociationAndStorageConsumptionHistoryTable = () \n{\nTotalBackupItemDimensionTable | join  \n(union isfuzzy = true  \n(BI_HistoryCombinationUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false),\n(BI_HistoryCombinationUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay)\n  on BackupItemUniqueId\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or ProtectedContainerFriendlyName contains (_BillingGroupName)\n| project BackupItemUniqueId, BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nVaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, TimeGenerated,  ResourceId,  ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, PolicyUniqueId, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementServerUniqueId, StorageReplicationType, TimeRangeEndDay\n};\nlet LatestProtectedContainerHistoryInfoTableExcludingDPMVMs = (){\nLatestBackupItemAssociationAndStorageConsumptionHistoryTable \n| where not((BackupManagementType has "DPM" and BackupItemType has "VMwareVM") or (BackupManagementType has "DPM" and BackupItemType has "HyperVVM") \nor (BackupManagementType has "AzureBackupServer" and BackupItemType has "VMwareVM") or (BackupManagementType has "AzureBackupServer" and BackupItemType has "HyperVVM"))\n| summarize StorageConsumedInMBs = sum(StorageConsumedInMBs), BackupItemFrontEndSize = sum(BackupItemFrontEndSize), ProtectedContainerName = any(ProtectedContainerName), ProtectedContainerFriendlyName = any(ProtectedContainerFriendlyName), CustomBackupManagementType = iff((any(BackupManagementType) has "AzureWorkload"), any(strcat(BackupManagementType, "/", BackupItemType)), any(BackupManagementType)), BackupManagementType = any(BackupManagementType), BackupSolution = any(BackupSolution),  VaultUniqueId = any(VaultUniqueId), VaultName = any(VaultName), VaultTags = any(VaultTags), SubscriptionId = any(SubscriptionId), ResourceGroupName = any(ResourceGroupName), AzureDataCenter = any(AzureDataCenter), StorageReplicationType = any(StorageReplicationType), ResourceId = any(ResourceId), TimeGenerated = any(TimeGenerated) by  ProtectedContainerUniqueId,  TimeRangeEndDay\n};\nlet LatestProtectedContainerInfoTableExcludingDPMVMs = (){\n// projecting TimeRangeDay to distill the report for RangeEndDay\nLatestBackupItemAssociationAndStorageConsumptionTable\n| where not((BackupManagementType has "DPM" and BackupItemType has "VMwareVM") or (BackupManagementType has "DPM" and BackupItemType has "HyperVVM") \nor (BackupManagementType has "AzureBackupServer" and BackupItemType has "VMwareVM") or (BackupManagementType has "AzureBackupServer" and BackupItemType has "HyperVVM"))\n// CustomBackupManagementType needed to distinguish \'AzureWorkload\' \n| summarize StorageConsumedInMBs = sum(StorageConsumedInMBs), BackupItemFrontEndSize = sum(BackupItemFrontEndSize), ProtectedContainerName = any(ProtectedContainerName), ProtectedContainerFriendlyName= any(ProtectedContainerFriendlyName), CustomBackupManagementType = iff((any(BackupManagementType) has "AzureWorkload"), any(strcat(BackupManagementType, "/", BackupItemType)), any(BackupManagementType)),\nBackupManagementType = any(BackupManagementType), BackupSolution = any(BackupSolution), VaultUniqueId = any(VaultUniqueId), VaultName = any(VaultName), VaultTags = any(VaultTags), SubscriptionId = any(SubscriptionId), ResourceGroupName = any(ResourceGroupName), AzureDataCenter = any(AzureDataCenter), StorageReplicationType = any(StorageReplicationType), ResourceId = any(ResourceId), TimeGenerated = any(TimeGenerated), TimeRangeEndDay = startofday(any(TimeGenerated)) by  ProtectedContainerUniqueId\n};\nlet TotalProtectedInstanceHistoryTable = (isProtectedContainerBillingType:bool) \n{union isfuzzy = true \n(ProtectedInstanceHistoryUnderAzureDiagnostics(isProtectedContainerBillingType) | where _ExcludeLegacyEvent == false),\n(ProtectedInstanceHistoryUnderResourceSpecific(isProtectedContainerBillingType))\n// ProtectedInstance is at BillingGroup level. CustomBackupManagementType can be the filter used.\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId, TimeRangeEndDay\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay\n};\nlet LatestProtectedInstanceTable = (isProtectedContainerBillingType:bool) \n{union isfuzzy = true \n(ProtectedInstanceUnderAzureDiagnostics(isProtectedContainerBillingType) | where _ExcludeLegacyEvent == false),\n(ProtectedInstanceUnderResourceSpecific(isProtectedContainerBillingType))\n| where startofday(TimeGenerated) == AsonDay\n// ProtectedInstance is at BillingGroup level. CustomBackupManagementType can be the filter used.\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay = startofday(TimeGenerated)\n};\nlet LatestProtectedInstanceHistoryTableFromProtectedContainerUniqueId = ()\n{ \nTotalProtectedInstanceHistoryTable(true) \n| join kind= rightouter (LatestProtectedContainerHistoryInfoTableExcludingDPMVMs) on ProtectedContainerUniqueId, TimeRangeEndDay\n| project TimeRangeEndDay = TimeRangeEndDay1, TimeGenerated = TimeGenerated1, ProtectedInstanceCount, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementType = BackupManagementType1, BackupSolution, CustomBackupManagementType, BillingGroupType = "DatasourceSet", BillingGroupFriendlyName = ProtectedContainerFriendlyName, BillingGroupUniqueId = ProtectedContainerUniqueId1, BillingGroupName = ProtectedContainerName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter,\nStorageReplicationType, ResourceId\n};\nlet LatestProtectedInstanceTableFromProtectedContainerUniqueId = ()\n{ \nLatestProtectedInstanceTable(true)\n| join kind= rightouter (LatestProtectedContainerInfoTableExcludingDPMVMs ) on ProtectedContainerUniqueId\n| project TimeRangeEndDay = TimeRangeEndDay1, TimeGenerated = TimeGenerated1, ProtectedInstanceCount, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementType = BackupManagementType1, BackupSolution, CustomBackupManagementType, BillingGroupType = "DatasourceSet", BillingGroupFriendlyName = ProtectedContainerFriendlyName,  BillingGroupUniqueId = ProtectedContainerUniqueId1, BillingGroupName = ProtectedContainerName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter,\nStorageReplicationType, ResourceId\n};\nlet LatestProtectedInstanceHistoryTableFromBackupItemUniqueId = ()\n{ \n(TotalProtectedInstanceHistoryTable(false) \n| where BackupManagementType in ("DPM","AzureBackupServer"))\n| join kind= rightouter (LatestBackupItemAssociationAndStorageConsumptionHistoryTable | where ((BackupManagementType has "DPM" and BackupItemType has "VMwareVM") or (BackupManagementType has "DPM" and BackupItemType has "HyperVVM") \n or (BackupManagementType has "AzureBackupServer" and BackupItemType has "VMwareVM") or (BackupManagementType has "AzureBackupServer" and BackupItemType has "HyperVVM"))\n | extend CustomBackupManagementType = BackupManagementType) on BackupItemUniqueId, TimeRangeEndDay\n| project TimeRangeEndDay = TimeRangeEndDay1, TimeGenerated = TimeGenerated1, ProtectedInstanceCount, BackupItemFrontEndSize, StorageConsumedInMBs, CustomBackupManagementType, BackupManagementType, BackupSolution, BillingGroupType = "Datasource", BillingGroupFriendlyName = BackupItemFriendlyName, BillingGroupUniqueId = BackupItemUniqueId1, BillingGroupName = BackupItemName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\nlet LatestProtectedInstanceTableFromBackupItemUniqueId = ()\n{ \n(LatestProtectedInstanceTable(false)\n| where BackupManagementType in ("DPM","AzureBackupServer"))\n| join kind= rightouter \n// applicable only for DPM VM Scenarios\n(LatestBackupItemAssociationAndStorageConsumptionTable | where ((BackupManagementType has "DPM" and BackupItemType has "VMwareVM") or (BackupManagementType has "DPM" and BackupItemType has "HyperVVM") \nor (BackupManagementType has "AzureBackupServer" and BackupItemType has "VMwareVM") or (BackupManagementType has "AzureBackupServer" and BackupItemType has "HyperVVM"))\n| extend CustomBackupManagementType = BackupManagementType) on BackupItemUniqueId\n| project TimeRangeEndDay = TimeRangeEndDay1, TimeGenerated = TimeGenerated1, ProtectedInstanceCount, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementType, CustomBackupManagementType, BackupSolution, BillingGroupType = "Datasource", BillingGroupFriendlyName = BackupItemFriendlyName, \n BillingGroupUniqueId = BackupItemUniqueId1, BillingGroupName = BackupItemName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\n// Special handling for DPM, AzureBackupServer Cluster scenario - Node PS has ProtectedInstance, whereas Cluster PS has storage Consumption\nlet LatestProtectedInstanceHistoryTableFromDPMNodeProtectedContainerUniqueId = ()\n{ \n((TotalProtectedInstanceHistoryTable(true) \n| where BackupManagementType in ("DPM","AzureBackupServer")\n| where ProtectedInstanceCount > 0)\n| join kind= leftanti (LatestProtectedContainerHistoryInfoTableExcludingDPMVMs ) on ProtectedContainerUniqueId, TimeRangeEndDay\n| project ProtectedContainerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay)\n| join (\nunion isfuzzy = true  \n(ProtectedContainerUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false),\n(ProtectedContainerUnderResourceSpecific())\n| where BackupManagementType in ("DPM","AzureBackupServer")\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or ProtectedContainerFriendlyName contains (_BillingGroupName)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId)\n  on ProtectedContainerUniqueId\n  // BackupItemFrontEndSize and StorageConsumed will be 0.0 as the same will be calculated at cluster level \n  // As it is DPM or AzureBackupServer, no extra handling needed for AzureWorkload\n  // Ideally the TimeGenerated field should come from BackupItem/ProtectedContainer. This is a special case and we are getting the container properties from latest table and not from history table.\n| project TimeRangeEndDay, TimeGenerated, ProtectedInstanceCount, BackupItemFrontEndSize = 0.0, StorageConsumedInMBs = 0.0, BackupManagementType, CustomBackupManagementType = BackupManagementType, \nBackupSolution = iff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", "DPM"), BillingGroupType = "DatasourceSet", BillingGroupFriendlyName = ProtectedContainerFriendlyName, \n BillingGroupUniqueId = ProtectedContainerUniqueId, BillingGroupName = ProtectedContainerName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\n// Special handling for DPM, AzureBackupServer Cluster scenario - Node PS has ProtectedInstance, whereas Cluster PS has storage Consumption\nlet LatestProtectedInstanceTableFromDPMNodeProtectedContainerUniqueId = ()\n{ \n(\n(LatestProtectedInstanceTable(true)\n| where BackupManagementType in ("DPM","AzureBackupServer")\n| where ProtectedInstanceCount > 0)\n| join kind= leftanti (LatestProtectedContainerInfoTableExcludingDPMVMs ) on ProtectedContainerUniqueId\n| project ProtectedContainerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay)\n| join (\nunion isfuzzy = true  \n(ProtectedContainerUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false),\n(ProtectedContainerUnderResourceSpecific())\n| where BackupManagementType in ("DPM","AzureBackupServer")\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or ProtectedContainerFriendlyName contains (_BillingGroupName)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId)\n  on ProtectedContainerUniqueId\n  // BackupItemFrontEndSize and StorageConsumed will be 0.0 as the same will be calculated at cluster level \n  // As it is DPM or AzureBackupServer, no extra handling needed for AzureWorkload\n  // Ideally the TimeGenerated field should come from BackupItem/ProtectedContainer. This is a special case and we are getting the container properties from latest table and not from history table.\n| project TimeRangeEndDay, TimeGenerated, ProtectedInstanceCount, BackupItemFrontEndSize = 0.0, StorageConsumedInMBs = 0.0, BackupManagementType, CustomBackupManagementType = BackupManagementType,\n  BackupSolution = iff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", "DPM"), BillingGroupType = "DatasourceSet", BillingGroupFriendlyName = ProtectedContainerFriendlyName, \n BillingGroupUniqueId = ProtectedContainerUniqueId, BillingGroupName = ProtectedContainerName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\nlet ProtectedInstanceHistoryMetric = ( )\n{ union \n(LatestProtectedInstanceHistoryTableFromProtectedContainerUniqueId()),\n(LatestProtectedInstanceHistoryTableFromBackupItemUniqueId()),\n(LatestProtectedInstanceHistoryTableFromDPMNodeProtectedContainerUniqueId)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| project  CustomBackupManagementType, BackupItemFrontEndSize, StorageConsumedInMBs, BillingGroupUniqueId, BillingGroupFriendlyName, BillingGroupName, ProtectedInstanceCount, BillingGroupType, TimeRangeEndDay, TimeGenerated, BackupManagementType, BackupSolution, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\nlet ProtectedInstanceMetric = ( ) \n{ union \n(LatestProtectedInstanceTableFromBackupItemUniqueId() ),\n(LatestProtectedInstanceTableFromProtectedContainerUniqueId()),\n(LatestProtectedInstanceTableFromDPMNodeProtectedContainerUniqueId)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| project  CustomBackupManagementType, BackupManagementType, BackupSolution, BackupItemFrontEndSize, StorageConsumedInMBs, ProtectedInstanceCount, BillingGroupUniqueId, BillingGroupFriendlyName, BillingGroupName, BillingGroupType, TimeRangeEndDay, TimeGenerated, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\nlet FinalTable = () {union (ProtectedInstanceMetric | where (_RangeEnd-_RangeStart == 1d)), (ProtectedInstanceHistoryMetric | where (_RangeEnd-_RangeStart > 1d))\n};\n// Display Tweaks for AFS and null ProtectedInstanceCount\n// Billing Entity is at BackupManagementType level and not at DS level. \nlet FinalTable_V1Vault = () {FinalTable\n| project CustomBackupManagementType, BackupManagementType, BackupSolution, ProtectedInstanceCount = iff(isempty(ProtectedInstanceCount), 0.0 ,todouble(ProtectedInstanceCount)/10), StorageConsumedInMBs = iff(isempty(StorageConsumedInMBs), todouble(0), todouble(StorageConsumedInMBs)), BackupItemFrontEndSize = iff(isempty(BackupItemFrontEndSize), todouble(0), todouble(BackupItemFrontEndSize)), BillingGroupUniqueId, BillingGroupType, BillingGroupName, BillingGroupFriendlyName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ResourceId, StorageReplicationType, ProtectedContainerName, TimeGenerated\n| project UniqueId = BillingGroupUniqueId, Name = BillingGroupName, Type = BillingGroupType, FriendlyName = BillingGroupFriendlyName,  SourceSizeInMBs = BackupItemFrontEndSize, ExtendedProperties = pack("ProtectedInstanceCount", ProtectedInstanceCount), VaultStore_StorageConsumptionInMBs = StorageConsumedInMBs,  BackupSolution,  VaultUniqueId, VaultName, VaultResourceId = ResourceId, VaultSubscriptionId = SubscriptionId, VaultLocation = AzureDataCenter, VaultStore_StorageReplicationType = StorageReplicationType, VaultTags, VaultType = "Microsoft.RecoveryServices/vaults", TimeGenerated};\n// FinalTable_DPPVault to be added later\nFinalTable_V1Vault \n| where "Microsoft.RecoveryServices/vaults" in~ (_VaultTypeList) or \'*\' in (_VaultTypeList)'
              }
            ]
          }
        }
        'Initialize_variable-BillingGroupTrendFunction': {
          runAfter: {
            'Initialize_variable-BillingGroupFunction': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'BillingGroupTrendFunction'
                type: 'string'
                value: '@{variables(\'workspacesToQuery_Custom\')}\n@{variables(\'ReportFilter_Trend\')}\nlet _BillingGroupName = "*";\n//Other Vars\nlet AsonDay =  _RangeEnd-1d;\nlet AzureStorageCutoffDate = datetime(6/01/2020, 12:00:00.000 AM);\nlet AzureStorageProtectedInstanceCountCutoffDate = datetime(2/01/2021, 12:00:00.000 AM);\n// HelperFunctions\nlet Extend_BackupSolution = (T:(BackupManagementType:string, BackupItemType:string))\n{\nT | extend BackupSolution = iff(BackupManagementType == "IaaSVM", "Azure Virtual Machine Backup", \niff(BackupManagementType == "MAB", "Azure Backup Agent", \niff(BackupManagementType == "DPM", "DPM", \niff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", \niff(BackupManagementType == "AzureStorage", "Azure Storage (Azure Files) Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", "SQL in Azure VM Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", "SAP HANA in Azure VM Backup", "")))))))\n};\n// Source Tables\nlet VaultUnderAzureDiagnostics = ()\n{\nAzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "Vault" and columnifexists("SchemaVersion_s", "") == "V2"\n| project VaultName = columnifexists("VaultName_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), VaultTags = columnifexists("VaultTags_s", ""), AzureDataCenter =  columnifexists("AzureDataCenter_s", ""), ResourceGroupName =  columnifexists("ResourceGroupName_s", ""), SubscriptionId = toupper(SubscriptionId), StorageReplicationType = columnifexists("StorageReplicationType_s", ""), ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated\n};\nlet VaultUnderResourceSpecific = ()\n{\nCoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "Vault" \n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId = toupper(SubscriptionId), ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n};\nlet ResourceIdListUnderAzureDiagnostics = materialize(VaultUnderAzureDiagnostics | distinct ResourceId);\nlet ResourceIdListUnderResourceSpecific = materialize(VaultUnderResourceSpecific | distinct ResourceId);\nlet BackupItemUnderAzureDiagnostics = ()\n{\nlet SourceBackupItemTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "BackupItem" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupItemProtectionState = columnifexists("BackupItemProtectionState_s", ""), BackupItemAppVersion = columnifexists("BackupItemAppVersion_s", ""),SecondaryBackupProtectionState = columnifexists("SecondaryBackupProtectionState_s", ""), BackupItemName = columnifexists("BackupItemName_s", ""), BackupItemFriendlyName = columnifexists("BackupItemFriendlyName_s", ""),\nBackupItemType = columnifexists("BackupItemType_s", ""),  ProtectionGroupName = columnifexists("ProtectionGroupName_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemUnderResourceSpecific = ()\n{\nlet SourceBackupItemTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "BackupItem" and State != "Deleted"\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderResourceSpecific | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemAssociationUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", "") , PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemAssociationUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemAssociationHistoryUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", ""), PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemAssociationTable\n};\nlet BackupItemAssociationHistoryUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemAssociationTable\n};\nlet BackupItemFrontEndSizeHistoryUnderAzureDiagnostics = ()\n{\n let BackupItemFrontEndSizeTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemFrontEndSizeConsumption" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemFrontEndSize = todouble(columnifexists("BackupItemFrontEndSize_s", "")), BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeHistoryUnderResourceSpecific = ()\n{\nlet BackupItemFrontEndSizeTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemFrontEndSizeConsumption" and State != "Deleted"\n| project BackupItemFrontEndSize, BackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeUnderAzureDiagnostics = ()\n{\n let BackupItemFrontEndSizeTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemFrontEndSizeConsumption" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemFrontEndSize = todouble(columnifexists("BackupItemFrontEndSize_s", "")), BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeUnderResourceSpecific = ()\n{\nlet BackupItemFrontEndSizeTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemFrontEndSizeConsumption" and State != "Deleted"\n| project BackupItemFrontEndSize, BackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemFrontEndSizeTable\n};\nlet StorageAssociationHistoryUnderAzureDiagnostics = ()\n{\n let StorageAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "StorageAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), StorageUniqueId = columnifexists("StorageUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), StorageConsumedInMBs = todouble(columnifexists("StorageConsumedInMBs_s", "")), \nStorageAllocatedInMBs = todouble(columnifexists("StorageAllocatedInMBs_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nStorageAssociationTable\n};\nlet StorageAssociationHistoryUnderResourceSpecific = ()\n{\nlet StorageAssociationTable = AddonAzureBackupStorage \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now()) \n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "StorageAssociation" and State != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId, VaultUniqueId, BackupManagementServerUniqueId, StorageUniqueId, StorageConsumedInMBs, StorageAllocatedInMBs, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated)) \n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nStorageAssociationTable\n};\nlet StorageAssociationUnderAzureDiagnostics = ()\n{\n let StorageAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "StorageAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), StorageUniqueId = columnifexists("StorageUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), StorageConsumedInMBs = todouble(columnifexists("StorageConsumedInMBs_s", "")), \nStorageAllocatedInMBs = todouble(columnifexists("StorageAllocatedInMBs_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nStorageAssociationTable\n};\nlet StorageAssociationUnderResourceSpecific = ()\n{\nlet StorageAssociationTable = AddonAzureBackupStorage \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "StorageAssociation" and State != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId, VaultUniqueId, BackupManagementServerUniqueId, StorageUniqueId, StorageConsumedInMBs, StorageAllocatedInMBs, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nStorageAssociationTable\n};\nlet ProtectedContainerUnderAzureDiagnostics = ()\n{\nlet ProtectedContainerTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "ProtectedContainer"  and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""),  ProtectedContainerFriendlyName = columnifexists("ProtectedContainerFriendlyName_s", ""), AgentVersion = columnifexists("AgentVersion_s", ""),\nProtectedContainerOSType = columnifexists("ProtectedContainerOSType_s", ""), ProtectedContainerOSVersion = columnifexists("ProtectedContainerOSVersion_s", ""), ProtectedContainerWorkloadType = columnifexists("ProtectedContainerWorkloadType_s", ""),  ProtectedContainerName = columnifexists("ProtectedContainerName_s", ""), ProtectedContainerProtectionState = columnifexists("ProtectedContainerProtectionState_s", ""), ProtectedContainerLocation = columnifexists("ProtectedContainerLocation_s", ""), ProtectedContainerType = columnifexists("ProtectedContainerType_s", ""),\nBackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   ProtectedContainerTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet ProtectedContainerUnderResourceSpecific = ()\n{\nlet ProtectedContainerTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "ProtectedContainer" and State != "Deleted"\n| project ProtectedContainerUniqueId,  ProtectedContainerFriendlyName, AgentVersion,\nProtectedContainerOSType, ProtectedContainerOSVersion, ProtectedContainerWorkloadType,  ProtectedContainerName, ProtectedContainerProtectionState, ProtectedContainerLocation, ProtectedContainerType,\nBackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderResourceSpecific | join   (\n   ProtectedContainerTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet ProtectedInstanceUnderAzureDiagnostics = (isProtectedContainerBillingType:bool)\n{\n let ProtectedInstanceTable = AzureDiagnostics \n| where Category == "AzureBackupReport" and OperationName == "ProtectedInstance" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""),\n ProtectedInstanceCount = toint(columnifexists("ProtectedInstanceCount_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId;\nProtectedInstanceTable\n};\nlet ProtectedInstanceUnderResourceSpecific = (isProtectedContainerBillingType:bool)\n{\nlet ProtectedInstanceTable = AddonAzureBackupProtectedInstance \n| where OperationName == "ProtectedInstance" and State != "Deleted"\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId \n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId;\nProtectedInstanceTable\n};\nlet ProtectedInstanceHistoryUnderAzureDiagnostics = (isProtectedContainerBillingType:bool)\n{\n let ProtectedInstanceTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "ProtectedInstance" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""),\n ProtectedInstanceCount = toint(columnifexists("ProtectedInstanceCount_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage") \n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nProtectedInstanceTable\n};\nlet ProtectedInstanceHistoryUnderResourceSpecific = (isProtectedContainerBillingType:bool)\n{\nlet ProtectedInstanceTable = AddonAzureBackupProtectedInstance \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "ProtectedInstance" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n| where (BackupItemUniqueId == "" and isProtectedContainerBillingType) or (ProtectedContainerUniqueId == "" and not(isProtectedContainerBillingType))\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId,\n ProtectedInstanceCount = iff((BackupManagementType == "AzureStorage" and TimeGenerated <= AzureStorageProtectedInstanceCountCutoffDate), 0, ProtectedInstanceCount), BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId, TimeRangeEndDay = startofday(TimeGenerated)\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementServerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay;\nProtectedInstanceTable\n};\n// BusinessLogic\nlet TotalBackupItemDimensionTable = () {union isfuzzy = true \n(BackupItemUnderAzureDiagnostics()),\n(BackupItemUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *)   by BackupItemUniqueId\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or  BackupItemFriendlyName contains (_BillingGroupName)\n| extend BackupItemProtectionState = iff(BackupItemProtectionState in ("Protected", "ActivelyProtected","ProtectionError"), "Protected", iff(BackupItemProtectionState in ("IRPending"), "InitialBackupPending", iff(isnotempty(BackupItemProtectionState),"ProtectionStopped",BackupItemProtectionState)))\n//| where BackupItemProtectionState in~ (_ProtectionInfoList) or \'*\' in (_ProtectionInfoList)\n| project BackupItemUniqueId,  BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nStorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter};\nlet BI_HistoryCombinationUnderAzureDiagnostics = ()\n{\t\n\tlet Base = ()\n\t{\n\tProtectedContainerUnderAzureDiagnostics | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n\t| join  kind= rightouter  (\n\t\tBackupItemAssociationHistoryUnderAzureDiagnostics |  project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t) on ProtectedContainerUniqueId\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size = ()\n\t{\n\tBase\n\t| join kind= leftouter (\n\t   BackupItemFrontEndSizeHistoryUnderAzureDiagnostics | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay \n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n\t| join kind= leftouter (\n\t   StorageAssociationHistoryUnderAzureDiagnostics | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay\n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\nBase_Size\n};\nlet BI_HistoryCombinationUnderResourceSpecific = ()\n{\n\tlet Base = ()\n\t{\n\tProtectedContainerUnderResourceSpecific | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n\t| join  kind= rightouter  (\n\t\tBackupItemAssociationHistoryUnderResourceSpecific |  project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t) on ProtectedContainerUniqueId\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size = ()\n\t{\n\tBase\n\t| join kind= leftouter (\n\t   BackupItemFrontEndSizeHistoryUnderResourceSpecific | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay \n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n\t| join kind= leftouter (\n\t   StorageAssociationHistoryUnderResourceSpecific | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay\n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tBase_Size\n};\nlet LatestBackupItemAssociationAndStorageConsumptionHistoryTable = () \n{\nTotalBackupItemDimensionTable | join  \n(union isfuzzy = true  \n(BI_HistoryCombinationUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false),\n(BI_HistoryCombinationUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay)\n  on BackupItemUniqueId\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or ProtectedContainerFriendlyName contains (_BillingGroupName)\n| project BackupItemUniqueId, BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nVaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, TimeGenerated,  ResourceId,  ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, PolicyUniqueId, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementServerUniqueId, StorageReplicationType, TimeRangeEndDay\n};\nlet LatestProtectedContainerHistoryInfoTableExcludingDPMVMs = (){\nLatestBackupItemAssociationAndStorageConsumptionHistoryTable \n| where not((BackupManagementType has "DPM" and BackupItemType has "VMwareVM") or (BackupManagementType has "DPM" and BackupItemType has "HyperVVM") \nor (BackupManagementType has "AzureBackupServer" and BackupItemType has "VMwareVM") or (BackupManagementType has "AzureBackupServer" and BackupItemType has "HyperVVM"))\n| summarize StorageConsumedInMBs = sum(StorageConsumedInMBs), BackupItemFrontEndSize = sum(BackupItemFrontEndSize), ProtectedContainerName = any(ProtectedContainerName), ProtectedContainerFriendlyName = any(ProtectedContainerFriendlyName), CustomBackupManagementType = iff((any(BackupManagementType) has "AzureWorkload"), any(strcat(BackupManagementType, "/", BackupItemType)), any(BackupManagementType)), BackupManagementType = any(BackupManagementType), BackupSolution = any(BackupSolution),  VaultUniqueId = any(VaultUniqueId), VaultName = any(VaultName), VaultTags = any(VaultTags), SubscriptionId = any(SubscriptionId), ResourceGroupName = any(ResourceGroupName), AzureDataCenter = any(AzureDataCenter), StorageReplicationType = any(StorageReplicationType), ResourceId = any(ResourceId), TimeGenerated = any(TimeGenerated) by  ProtectedContainerUniqueId,  TimeRangeEndDay\n};\nlet TotalProtectedInstanceHistoryTable = (isProtectedContainerBillingType:bool) \n{union isfuzzy = true \n(ProtectedInstanceHistoryUnderAzureDiagnostics(isProtectedContainerBillingType) | where _ExcludeLegacyEvent == false),\n(ProtectedInstanceHistoryUnderResourceSpecific(isProtectedContainerBillingType))\n// ProtectedInstance is at BillingGroup level. CustomBackupManagementType can be the filter used.\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, ProtectedContainerUniqueId, TimeRangeEndDay\n| project BackupItemUniqueId, ProtectedContainerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay\n};\nlet LatestProtectedInstanceHistoryTableFromProtectedContainerUniqueId = ()\n{ \nTotalProtectedInstanceHistoryTable(true) \n| join kind= rightouter (LatestProtectedContainerHistoryInfoTableExcludingDPMVMs) on ProtectedContainerUniqueId, TimeRangeEndDay\n| project TimeRangeEndDay = TimeRangeEndDay1, TimeGenerated = TimeGenerated1, ProtectedInstanceCount, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementType = BackupManagementType1, BackupSolution, CustomBackupManagementType, BillingGroupType = "DatasourceSet", BillingGroupFriendlyName = ProtectedContainerFriendlyName, BillingGroupUniqueId = ProtectedContainerUniqueId1, BillingGroupName = ProtectedContainerName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter,\nStorageReplicationType, ResourceId\n};\nlet LatestProtectedInstanceHistoryTableFromBackupItemUniqueId = ()\n{ \n(TotalProtectedInstanceHistoryTable(false) \n| where BackupManagementType in ("DPM","AzureBackupServer"))\n| join kind= rightouter (LatestBackupItemAssociationAndStorageConsumptionHistoryTable | where ((BackupManagementType has "DPM" and BackupItemType has "VMwareVM") or (BackupManagementType has "DPM" and BackupItemType has "HyperVVM") \n or (BackupManagementType has "AzureBackupServer" and BackupItemType has "VMwareVM") or (BackupManagementType has "AzureBackupServer" and BackupItemType has "HyperVVM"))\n | extend CustomBackupManagementType = BackupManagementType) on BackupItemUniqueId, TimeRangeEndDay\n| project TimeRangeEndDay = TimeRangeEndDay1, TimeGenerated = TimeGenerated1, ProtectedInstanceCount, BackupItemFrontEndSize, StorageConsumedInMBs, CustomBackupManagementType, BackupManagementType, BackupSolution, BillingGroupType = "Datasource", BillingGroupFriendlyName = BackupItemFriendlyName, BillingGroupUniqueId = BackupItemUniqueId1, BillingGroupName = BackupItemName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\n// Special handling for DPM, AzureBackupServer Cluster scenario - Node PS has ProtectedInstance, whereas Cluster PS has storage Consumption\nlet LatestProtectedInstanceHistoryTableFromDPMNodeProtectedContainerUniqueId = ()\n{ \n((TotalProtectedInstanceHistoryTable(true) \n| where BackupManagementType in ("DPM","AzureBackupServer")\n| where ProtectedInstanceCount > 0)\n| join kind= leftanti (LatestProtectedContainerHistoryInfoTableExcludingDPMVMs ) on ProtectedContainerUniqueId, TimeRangeEndDay\n| project ProtectedContainerUniqueId, BackupManagementType, ResourceId, TimeGenerated, ProtectedInstanceCount, TimeRangeEndDay)\n| join (\nunion isfuzzy = true  \n(ProtectedContainerUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false),\n(ProtectedContainerUnderResourceSpecific())\n| where BackupManagementType in ("DPM","AzureBackupServer")\n| where isempty(_BillingGroupName) or _BillingGroupName == "*" or ProtectedContainerFriendlyName contains (_BillingGroupName)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId)\n  on ProtectedContainerUniqueId\n  // BackupItemFrontEndSize and StorageConsumed will be 0.0 as the same will be calculated at cluster level \n  // As it is DPM or AzureBackupServer, no extra handling needed for AzureWorkload\n  // Ideally the TimeGenerated field should come from BackupItem/ProtectedContainer. This is a special case and we are getting the container properties from latest table and not from history table.\n| project TimeRangeEndDay, TimeGenerated, ProtectedInstanceCount, BackupItemFrontEndSize = 0.0, StorageConsumedInMBs = 0.0, BackupManagementType, CustomBackupManagementType = BackupManagementType, \nBackupSolution = iff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", "DPM"), BillingGroupType = "DatasourceSet", BillingGroupFriendlyName = ProtectedContainerFriendlyName, \n BillingGroupUniqueId = ProtectedContainerUniqueId, BillingGroupName = ProtectedContainerName, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\nlet ProtectedInstanceHistoryMetric = ( )\n{ union \n(LatestProtectedInstanceHistoryTableFromProtectedContainerUniqueId()),\n(LatestProtectedInstanceHistoryTableFromBackupItemUniqueId()),\n(LatestProtectedInstanceHistoryTableFromDPMNodeProtectedContainerUniqueId)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| project  CustomBackupManagementType, BackupItemFrontEndSize, StorageConsumedInMBs, BillingGroupUniqueId, BillingGroupFriendlyName, BillingGroupName, ProtectedInstanceCount, BillingGroupType, TimeRangeEndDay, TimeGenerated, BackupManagementType, BackupSolution, ProtectedContainerName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, StorageReplicationType, ResourceId\n};\nlet FinalTable = () {ProtectedInstanceHistoryMetric\n};\n// Display Tweaks for AFS and null ProtectedInstanceCount\n// Billing Entity is at BackupManagementType level and not at DS level. \nlet FinalTable_V1Vault = () {FinalTable\n| project CustomBackupManagementType, BackupManagementType, BackupSolution, ProtectedInstanceCount = iff(isempty(ProtectedInstanceCount), 0.0 ,todouble(ProtectedInstanceCount)/10), StorageConsumedInMBs = iff(isempty(StorageConsumedInMBs), todouble(0), todouble(StorageConsumedInMBs)), BackupItemFrontEndSize = iff(isempty(BackupItemFrontEndSize), todouble(0), todouble(BackupItemFrontEndSize)), BillingGroupUniqueId, BillingGroupType, BillingGroupName, BillingGroupFriendlyName, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ResourceId, StorageReplicationType, ProtectedContainerName, TimeGenerated\n| project UniqueId = BillingGroupUniqueId, Name = BillingGroupName, Type = BillingGroupType, FriendlyName = BillingGroupFriendlyName,  SourceSizeInMBs = BackupItemFrontEndSize, ExtendedProperties = pack("ProtectedInstanceCount", ProtectedInstanceCount), VaultStore_StorageConsumptionInMBs = StorageConsumedInMBs,  BackupSolution,  VaultUniqueId, VaultName, VaultResourceId = ResourceId, VaultSubscriptionId = SubscriptionId, VaultLocation = AzureDataCenter, VaultStore_StorageReplicationType = StorageReplicationType, VaultTags, VaultType = "Microsoft.RecoveryServices/vaults", TimeGenerated};\n// FinalTable_DPPVault to be added later\nFinalTable_V1Vault \n| where "Microsoft.RecoveryServices/vaults" in~ (_VaultTypeList) or \'*\' in (_VaultTypeList)'
              }
            ]
          }
        }
        'Initialize_variable-CoreAzureBackup': {
          runAfter: {
            'Initialize_variable-AzureDiagnostics': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'CoreAzureBackup_Incomplete'
                type: 'string'
                value: 'let CoreAzureBackup = ()\n{\nunion'
              }
            ]
          }
        }
        'Initialize_variable-EmailBodyForSuccessfulRun': {
          runAfter: {
            'Initialize_variable-BillingGroupTrendFunction': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'visual'
                type: 'string'
              }
            ]
          }
        }
        'Initialize_variable-ReportFilterForHistoricalData': {
          runAfter: {
            'Initialize_variable-UnionOfWorkspaces': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ReportFilter_Trend'
                type: 'string'
                value: 'let _RangeStart = iff((datetime(@{parameters(\'startDate\')}) == datetime(null)), startofday(ago(1d)), startofday(datetime(@{parameters(\'startDate\')})));\nlet _RangeEnd = iff((datetime(@{parameters(\'endDate\')})== datetime(null)), startofday(now()), startofday(datetime(@{parameters(\'endDate\')})) + 1d);\nlet _VaultSubscriptionList = split(@{parameters(\'vaultSubscriptionListFilter\')}, \',\');\nlet _VaultLocationList = split(@{parameters(\'vaultLocationListFilter\')}, \',\');\nlet _VaultList = split(@{parameters(\'vaultListFilter\')}, \',\');\nlet _VaultTypeList = "*";\nlet _ExcludeLegacyEvent = @{parameters(\'excludeLegacyEvent\')};\nlet _BackupSolutionList =  split(@{parameters(\'backupSolutionListFilter\')}, \',\');\nlet _AggregationType = @{parameters(\'aggregationType\')};'
              }
            ]
          }
        }
        'Initialize_variable-ReportFilterForLatestData': {
          runAfter: {
            'Initialize_variable-ReportFilterForHistoricalData': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'ReportFilter_Latest'
                type: 'string'
                value: 'let _RangeStart = iff(( datetime(@{parameters(\'endDate\')})== datetime(null)), startofday(ago(1d)), startofday(datetime(@{parameters(\'endDate\')})));\nlet _RangeEnd = iff((datetime(@{parameters(\'endDate\')})== datetime(null)), startofday(now()), startofday(datetime(@{parameters(\'endDate\')})) + 1d);\nlet _VaultSubscriptionList = split(@{parameters(\'vaultSubscriptionListFilter\')}, \',\');\nlet _VaultLocationList = split(@{parameters(\'vaultLocationListFilter\')}, \',\');\nlet _VaultList = split(@{parameters(\'vaultListFilter\')}, \',\');\nlet _VaultTypeList = "*";\nlet _ExcludeLegacyEvent = @{parameters(\'excludeLegacyEvent\')};\nlet _BackupSolutionList  =  split(@{parameters(\'backupSolutionListFilter\')}, \',\');'
              }
            ]
          }
        }
        'Initialize_variable-UnionOfWorkspaces': {
          runAfter: {
            For_each: [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'workspacesToQuery_Custom'
                type: 'string'
                value: '@{concat(concat(substring(variables(\'AddonAzureBackupStorage_Incomplete\'),0,sub(length(variables(\'AddonAzureBackupStorage_Incomplete\')),1)),\'};\'),\r\nconcat(substring(variables(\'AddonAzureBackupProtectedInstance_Incomplete\'),0,sub(length(variables(\'AddonAzureBackupProtectedInstance_Incomplete\')),1)),\'};\'),\r\nconcat(substring(variables(\'AddonAzureBackupPolicy_Incomplete\'),0,sub(length(variables(\'AddonAzureBackupPolicy_Incomplete\')),1)),\'};\'),\r\nconcat(substring(variables(\'AddonAzureBackupJobs_Incomplete\'),0,sub(length(variables(\'AddonAzureBackupJobs_Incomplete\')),1)),\'};\'),\r\nconcat(substring(variables(\'CoreAzureBackup_Incomplete\'),0,sub(length(variables(\'CoreAzureBackup_Incomplete\')),1)),\'};\'),\r\nconcat(substring(variables(\'AzureDiagnostics_Incomplete\'),0,sub(length(variables(\'AzureDiagnostics_Incomplete\')),1)),\'};\'))}'
              }
            ]
          }
        }
        Scope: {
          actions: {
            'Create_CSV_table-BillingGroupList': {
              runAfter: {
                'Run_query_and_list_results-BillingGroupList': [
                  'Succeeded'
                ]
              }
              type: 'Table'
              inputs: {
                format: 'CSV'
                from: '@if(empty(body(\'Run_query_and_list_results-BillingGroupList\')?[\'value\']),variables(\'NoDataMessage\'),body(\'Run_query_and_list_results-BillingGroupList\')?[\'value\'])'
              }
            }
            'Run_query_and_list_results-BillingGroupList': {
              runAfter: {
                'Run_query_and_visualize_results-CloudStorageTrend': [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'BillingGroupFunction\')}\n|  extend name_array = split(Name,";")\n|  extend name_arraylen = array_length(name_array)\n| project BilledEntity=FriendlyName, BilledEntityResourceGroup=iff(name_arraylen == 3, name_array[(name_arraylen-2)], "(none)"), BilledEntityType=Type, BackupSolution, ProtectedInstances=todouble(parse_json(ExtendedProperties).ProtectedInstanceCount), CloudStorage=VaultStore_StorageConsumptionInMBs/1024, StorageReplicationType=VaultStore_StorageReplicationType, Vault=VaultResourceId, VaultResourceGroup=split(split(tolower(VaultResourceId), \'/resourcegroups/\')[1],\'/\')[0], Subscription=VaultSubscriptionId'
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azuremonitorlogs\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/queryData'
                queries: {
                  resourcegroups: workspaceResourceGroup
                  resourcename: logicAppWorkspace
                  resourcetype: 'Log Analytics Workspace'
                  subscriptions: workspaceSubscriptionId
                  timerange: 'Set in query'
                }
              }
            }
            'Run_query_and_visualize_results-BillingGroupTrend': {
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'BillingGroupTrendFunction\')}\n// query to transform function output\n| summarize ProtectedInstanceCount = sum(todouble(parse_json(ExtendedProperties).ProtectedInstanceCount)) by  startofday(TimeGenerated)\n'
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azuremonitorlogs\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/visualizeQuery'
                queries: {
                  resourcegroups: workspaceResourceGroup
                  resourcename: logicAppWorkspace
                  resourcetype: 'Log Analytics Workspace'
                  subscriptions: workspaceSubscriptionId
                  timerange: 'Set in query'
                  visType: 'Time Chart'
                }
              }
            }
            'Run_query_and_visualize_results-CloudStorageTrend': {
              runAfter: {
                'Run_query_and_visualize_results-BillingGroupTrend': [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'BillingGroupTrendFunction\')}\n// query to transform function output\n| summarize StorageConsumedInGBs = sum(VaultStore_StorageConsumptionInMBs)/1024 by  startofday(TimeGenerated)\n'
                host: {
                  connection: {
                    name: '@parameters(\'$connections\')[\'azuremonitorlogs\'][\'connectionId\']'
                  }
                }
                method: 'post'
                path: '/visualizeQuery'
                queries: {
                  resourcegroups: workspaceResourceGroup
                  resourcename: logicAppWorkspace
                  resourcetype: 'Log Analytics Workspace'
                  subscriptions: workspaceSubscriptionId
                  timerange: 'Set in query'
                  visType: 'Time Chart'
                }
              }
            }
            'Set_variable-EmailBodyForSuccessfulRun': {
              runAfter: {
                'Create_CSV_table-BillingGroupList': [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'visual'
                value: '<div>\n<h3>Protected Instances Trend</h3>\n<br>\n<img src="cid:@{body(\'Run_query_and_visualize_results-BillingGroupTrend\')?[\'attachmentName\']}" width:"50px"/>\n<br>\n<h3> Cloud Storage Trend</h3> \n<br>\n<img src="cid:@{body(\'Run_query_and_visualize_results-CloudStorageTrend\')?[\'attachmentName\']}" width:"50px"/>\n<br>\n</div>'
              }
            }
          }
          runAfter: {
            'Initialize_variable-NoDataMessage': [
              'Succeeded'
            ]
          }
          type: 'Scope'
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          azuremonitorlogs: {
            connectionId: azureMonitorLogsConnectionName.id
            connectionName: azureMonitorLogsConnectionName_var
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'azuremonitorlogs')
          }
          office365: {
            connectionId: office365ConnectionName.id
            connectionName: office365ConnectionName_var
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'office365')
          }
        }
      }
    }
  }
}