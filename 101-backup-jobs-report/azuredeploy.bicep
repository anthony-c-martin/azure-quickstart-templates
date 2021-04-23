@description('Name of the Logic App to be created.')
param logicAppName string = 'Jobs'

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
param emailSubject string = 'Jobs'

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
          defaultValue: 'Jobs'
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
                        ContentBytes: '@{body(\'Run_query_and_visualize_results-JobOperation\')?[\'attachmentContent\']}'
                        Name: '@body(\'Run_query_and_visualize_results-JobOperation\')?[\'attachmentName\']'
                      }
                      {
                        ContentBytes: '@{body(\'Run_query_and_visualize_results-JobStatus\')?[\'attachmentContent\']}'
                        Name: '@body(\'Run_query_and_visualize_results-JobStatus\')?[\'attachmentName\']'
                      }
                      {
                        ContentBytes: '@{base64(body(\'Create_CSV_table-JobList\'))}'
                        Name: 'JobList.csv'
                      }
                      {
                        ContentBytes: '@{body(\'Run_query_and_visualize_results-JobFailureCode\')?[\'attachmentContent\']}'
                        Name: '@body(\'Run_query_and_visualize_results-JobFailureCode\')?[\'attachmentName\']'
                      }
                    ]
                    Body: '<p><u><strong><br>\nJobs Report<br>\n</strong></u><u><strong><br>\nEmail Contents<br>\n</strong></u><br>\n1. <b>Inline</b> <br>a. Jobs by Status over time <br>b. Jobs by Operation<br>c. Jobs by Failure Code\n<br>\n<br>2. <b>Attachments </b> <br>a. List of backup and restore jobs in selected time range <br><br> <a href=\'https://aka.ms/AzureBackupReportDocs\'>Learn more</a> about Backup Reports<br>\n<br>\n<u><strong>@{variables(\'visual\')}</strong></u><u><strong><br>\n<br>\n<br>\n</strong></u><br>\n<br>\n</p>'
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
        'Initialize_variable-BackupInstanceTrendFunction': {
          runAfter: {
            'Initialize_variable-JobFunction': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'BackupInstanceTrendFunction'
                type: 'string'
                value: '@{variables(\'workspacesToQuery_Custom\')}\n@{variables(\'ReportFilter_Trend\')}\nlet _ProtectionInfoList = "*";\nlet _DatasourceSetName = "*";\nlet _BackupInstanceName = "*";\nlet _DisplayAllFields = true;\n// Other Vars\nlet AsonDay = _RangeEnd-1d;\nlet AzureStorageCutoffDate = datetime(6/01/2020, 12:00:00.000 AM);\n// HelperFunctions\nlet Extend_BackupSolution = (T:(BackupManagementType:string, BackupItemType:string))\n{\nT | extend BackupSolution = iff(BackupManagementType == "IaaSVM", "Azure Virtual Machine Backup", \niff(BackupManagementType == "MAB", "Azure Backup Agent", \niff(BackupManagementType == "DPM", "DPM", \niff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", \niff(BackupManagementType == "AzureStorage", "Azure Storage (Azure Files) Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", "SQL in Azure VM Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", "SAP HANA in Azure VM Backup", "")))))))\n};\nlet Extend_DatasourceType = (T:(BackupManagementType:string, BackupItemType:string))\n{\nT | extend DatasourceType = iff(BackupManagementType == "IaaSVM", "Microsoft.Compute/virtualMachines", \niff(BackupManagementType == "MAB", BackupItemType, \niff(BackupManagementType == "DPM", iff(BackupItemType == "SQLDB","SQLDataBase",BackupItemType), \niff(BackupManagementType == "AzureBackupServer", iff(BackupItemType == "SQLDB","SQLDataBase",BackupItemType), \niff(BackupManagementType == "AzureStorage", "Microsoft.Storage/storageAccounts/fileServices/shares", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", "SQLDataBase", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", "SAPHanaDatabase", "")))))))\n};\nlet Extend_BackupInstanceId = (T:(ResourceId:string, BackupManagementType:string, BackupItemType:string, ProtectedContainerName:string, BackupItemName:string))\n{\nT | extend BackupInstanceId =  toupper(iff ((BackupManagementType == "IaaSVM" and BackupItemType == "VM"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/IaasVMContainer;", ProtectedContainerName, "/protectedItems/VM;", ProtectedContainerName),\niff((BackupManagementType == "AzureStorage" and BackupItemType == "AzureFileShare"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/StorageContainer;", ProtectedContainerName, "/protectedItems/AzureFileShare;", BackupItemName) , \niff((BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/VMAppContainer;", ProtectedContainerName, "/protectedItems/SQLDataBase;", BackupItemName) , \niff((BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/VMAppContainer;", ProtectedContainerName, "/protectedItems/SAPHanaDatabase;", BackupItemName), "")))))\n};\nlet Extend_DatasourceSetResourceId_DatasourceSetType_DatasourceResourceId = (T:(ResourceId:string, ProtectedContainerName:string, BackupManagementType:string, BackupItemType:string, BackupItemUniqueId:string, BackupItemName:string, BackupItemFriendlyName:string))\n{\nT | extend prefix = array_strcat(array_split(split(ResourceId,"/"), 4)[0] ,"/")\n|  extend container_array = split(ProtectedContainerName,";")\n|  extend container_arraylen = array_length(container_array)\n| extend containerNameString = iff(container_arraylen == 3, ProtectedContainerName, "")\n| parse containerNameString with entityType:string ";" rgName:string ";" entityName:string\n| extend entityURL = iff((BackupManagementType == "AzureStorage" and BackupItemType == "AzureFileShare"), iff(entityType == "storage", "/Microsoft.Storage/storageAccounts/", "/Microsoft.ClassicStorage/storageAccounts/"), iff((BackupManagementType == "IaaSVM" and BackupItemType == "VM"), iff(entityType =~ "iaasvmcontainerv2", "/Microsoft.Compute/virtualMachines/", "/Microsoft.ClassicCompute/virtualMachines/"), iff(((BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase") or (BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase")), iff(entityType =~ "compute", "/Microsoft.Compute/virtualMachines/", "/Microsoft.ClassicCompute/virtualMachines/"), "")))\n| extend DatasourceSetResourceId = toupper(iff(BackupManagementType in ("DPM", "AzureBackupServer", "MAB"), "" , iff(containerNameString != "", strcat(prefix, "/", rgName, "/providers", entityURL, entityName), "")))\n//BackupSolution\n| extend DatasourceSetType = iff(BackupManagementType == "IaaSVM", iff(entityType =~ "iaasvmcontainerv2", "Microsoft.Compute/virtualMachines", "Microsoft.ClassicCompute/virtualMachines"),  \niff(BackupManagementType == "MAB", "Azure Backup Agent", \niff(BackupManagementType == "DPM", "DPM", \niff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", \niff(BackupManagementType == "AzureStorage", iff(entityType == "storage", "Microsoft.Storage/storageAccounts", "Microsoft.ClassicStorage/storageAccounts"), \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", iff(entityType =~ "compute", "Microsoft.Compute/virtualMachines", "Microsoft.ClassicCompute/virtualMachines"), \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", iff(entityType =~ "compute", "Microsoft.Compute/virtualMachines", "Microsoft.ClassicCompute/virtualMachines"), "")))))))\n| extend DatasourceResourceId = toupper(iff(BackupManagementType in ("DPM", "AzureBackupServer", "MAB"), BackupItemUniqueId, \niff(BackupManagementType == "IaaSVM", DatasourceSetResourceId, \niff(BackupManagementType == "AzureStorage", strcat(DatasourceSetResourceId, "/fileServices/default/shares/", BackupItemFriendlyName),\niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase",iff(DatasourceSetResourceId != "",strcat(DatasourceSetResourceId, "/providers/Microsoft.RecoveryServices/backupProtectedItem/SQLDataBase;", BackupItemName),""),\niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase",iff(DatasourceSetResourceId != "",strcat(DatasourceSetResourceId, "/providers/Microsoft.RecoveryServices/backupProtectedItem/SAPHanaDatabase;", BackupItemName),""),""))))))\n| project-away prefix, container_array, container_arraylen, containerNameString, entityURL \n};\n// Source Tables\nlet VaultUnderAzureDiagnostics = ()\n{\nAzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "Vault" and columnifexists("SchemaVersion_s", "") == "V2"\n| project VaultName = columnifexists("VaultName_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), VaultTags = columnifexists("VaultTags_s", ""), AzureDataCenter =  columnifexists("AzureDataCenter_s", ""), ResourceGroupName =  columnifexists("ResourceGroupName_s", ""), SubscriptionId = toupper(SubscriptionId), StorageReplicationType = columnifexists("StorageReplicationType_s", ""), ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated\n};\nlet VaultUnderResourceSpecific = ()\n{\nCoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "Vault" \n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId = toupper(SubscriptionId), ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n};\nlet ResourceIdListUnderAzureDiagnostics = materialize(VaultUnderAzureDiagnostics | distinct ResourceId);\nlet ResourceIdListUnderResourceSpecific = materialize(VaultUnderResourceSpecific | distinct ResourceId);\nlet BackupItemUnderAzureDiagnostics = ()\n{\nlet SourceBackupItemTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "BackupItem" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupItemProtectionState = columnifexists("BackupItemProtectionState_s", ""), BackupItemAppVersion = columnifexists("BackupItemAppVersion_s", ""),SecondaryBackupProtectionState = columnifexists("SecondaryBackupProtectionState_s", ""), BackupItemName = columnifexists("BackupItemName_s", ""), BackupItemFriendlyName = columnifexists("BackupItemFriendlyName_s", ""),\nBackupItemType = columnifexists("BackupItemType_s", ""),  ProtectionGroupName = columnifexists("ProtectionGroupName_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemUnderResourceSpecific = ()\n{\nlet SourceBackupItemTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "BackupItem" and State != "Deleted"\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderResourceSpecific | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemAssociationHistoryUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", ""), PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemAssociationTable\n};\nlet BackupItemAssociationHistoryUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemAssociationTable\n};\nlet BackupItemAssociationUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", "") , PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemAssociationUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemFrontEndSizeHistoryUnderAzureDiagnostics = ()\n{\n let BackupItemFrontEndSizeTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemFrontEndSizeConsumption" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemFrontEndSize = todouble(columnifexists("BackupItemFrontEndSize_s", "")), BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeHistoryUnderResourceSpecific = ()\n{\nlet BackupItemFrontEndSizeTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemFrontEndSizeConsumption" and State != "Deleted"\n| project BackupItemFrontEndSize, BackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeUnderAzureDiagnostics = ()\n{\n let BackupItemFrontEndSizeTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemFrontEndSizeConsumption" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemFrontEndSize = todouble(columnifexists("BackupItemFrontEndSize_s", "")), BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemFrontEndSizeTable\n};\nlet BackupItemFrontEndSizeUnderResourceSpecific = ()\n{\nlet BackupItemFrontEndSizeTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemFrontEndSizeConsumption" and State != "Deleted"\n| project BackupItemFrontEndSize, BackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemFrontEndSizeTable\n};\nlet StorageAssociationHistoryUnderAzureDiagnostics = ()\n{\n let StorageAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "StorageAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), StorageUniqueId = columnifexists("StorageUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), StorageConsumedInMBs = todouble(columnifexists("StorageConsumedInMBs_s", "")), \nStorageAllocatedInMBs = todouble(columnifexists("StorageAllocatedInMBs_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nStorageAssociationTable\n};\nlet StorageAssociationHistoryUnderResourceSpecific = ()\n{\nlet StorageAssociationTable = AddonAzureBackupStorage \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now()) \n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "StorageAssociation" and State != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId, VaultUniqueId, BackupManagementServerUniqueId, StorageUniqueId, StorageConsumedInMBs, StorageAllocatedInMBs, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage") \n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nStorageAssociationTable\n};\nlet StorageAssociationUnderAzureDiagnostics = ()\n{\n let StorageAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "StorageAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), StorageUniqueId = columnifexists("StorageUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), StorageConsumedInMBs = todouble(columnifexists("StorageConsumedInMBs_s", "")), \nStorageAllocatedInMBs = todouble(columnifexists("StorageAllocatedInMBs_s", "")), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nStorageAssociationTable\n};\nlet StorageAssociationUnderResourceSpecific = ()\n{\nlet StorageAssociationTable = AddonAzureBackupStorage \n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "StorageAssociation" and State != "Deleted"\n// Not Projecting ProtectedContainerUniqueId - DPM/AzureBackupServer ProtectedContainer (incase of cluster) is node PS and not cluster PS\n| project BackupItemUniqueId, VaultUniqueId, BackupManagementServerUniqueId, StorageUniqueId, StorageConsumedInMBs, StorageAllocatedInMBs, BackupManagementType, TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Providers like DPM, AzureBackupServer has Disk storage. Filtering out cloud storage only.\n| where split(StorageUniqueId, ";")[2] has "cloud"\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nStorageAssociationTable\n};\nlet RecoveryPointUnderAzureDiagnostics = ()\n{\n let RecoveryPointTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where OperationName == "RecoveryPoint" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project LatestRecoveryPointLocation = columnifexists("LatestRecoveryPointLocation_s", ""), OldestRecoveryPointLocation = columnifexists("OldestRecoveryPointLocation_s", ""), LatestRecoveryPointTime = todatetime(columnifexists("LatestRecoveryPointTime_s", "")), OldestRecoveryPointTime = todatetime(columnifexists("OldestRecoveryPointTime_s", "")),\nBackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n// Interested in only Vault/Cloud RPs\n| where LatestRecoveryPointLocation has "Cloud" \n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nRecoveryPointTable\n};\nlet RecoveryPointUnderResourceSpecific = ()\n{\n let RecoveryPointTable = CoreAzureBackup \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "RecoveryPoint" and  State != "Deleted"\n| project LatestRecoveryPointLocation, OldestRecoveryPointLocation, LatestRecoveryPointTime, OldestRecoveryPointTime,\nBackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n// Interested in only Vault/Cloud RPs\n| where LatestRecoveryPointLocation has "Cloud" \n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nRecoveryPointTable\n};\nlet RecoveryPointHistoryUnderAzureDiagnostics = ()\n{\n let RecoveryPointTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where OperationName == "RecoveryPoint" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project LatestRecoveryPointLocation = columnifexists("LatestRecoveryPointLocation_s", ""), OldestRecoveryPointLocation = columnifexists("OldestRecoveryPointLocation_s", ""), LatestRecoveryPointTime = todatetime(columnifexists("LatestRecoveryPointTime_s", "")), OldestRecoveryPointTime = todatetime(columnifexists("OldestRecoveryPointTime_s", "")),\nBackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n// Interested in only Vault/Cloud RPs\n| where LatestRecoveryPointLocation has "Cloud" \n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nRecoveryPointTable\n};\nlet RecoveryPointHistoryUnderResourceSpecific = ()\n{\n let RecoveryPointTable = CoreAzureBackup \n // Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "RecoveryPoint" and  State != "Deleted"\n| project LatestRecoveryPointLocation, OldestRecoveryPointLocation, LatestRecoveryPointTime, OldestRecoveryPointTime,\nBackupItemUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (_AggregationType =~ "Daily") or (_AggregationType =~ "Weekly" and startofday(TimeGenerated) == startofweek(TimeGenerated)) or (_AggregationType =~ "Monthly" and startofday(TimeGenerated) == startofmonth(TimeGenerated))\n// Interested in only Vault/Cloud RPs\n| where LatestRecoveryPointLocation has "Cloud" \n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay = startofday(TimeGenerated);\nRecoveryPointTable\n};\nlet ProtectedContainerUnderAzureDiagnostics = ()\n{\nlet ProtectedContainerTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "ProtectedContainer"  and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""),  ProtectedContainerFriendlyName = columnifexists("ProtectedContainerFriendlyName_s", ""), AgentVersion = columnifexists("AgentVersion_s", ""),\nProtectedContainerOSType = columnifexists("ProtectedContainerOSType_s", ""), ProtectedContainerOSVersion = columnifexists("ProtectedContainerOSVersion_s", ""), ProtectedContainerWorkloadType = columnifexists("ProtectedContainerWorkloadType_s", ""),  ProtectedContainerName = columnifexists("ProtectedContainerName_s", ""), ProtectedContainerProtectionState = columnifexists("ProtectedContainerProtectionState_s", ""), ProtectedContainerLocation = columnifexists("ProtectedContainerLocation_s", ""), ProtectedContainerType = columnifexists("ProtectedContainerType_s", ""),\nBackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   ProtectedContainerTable \n) on ResourceId;\n};\nlet ProtectedContainerUnderResourceSpecific = ()\n{\nlet ProtectedContainerTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "ProtectedContainer" and State != "Deleted"\n| project ProtectedContainerUniqueId,  ProtectedContainerFriendlyName, AgentVersion,\nProtectedContainerOSType, ProtectedContainerOSVersion, ProtectedContainerWorkloadType,  ProtectedContainerName, ProtectedContainerProtectionState, ProtectedContainerLocation, ProtectedContainerType,\nBackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderResourceSpecific | join   (\n   ProtectedContainerTable \n) on ResourceId;\n};\nlet PolicyUnderAzureDiagnostics = ()\n{\nlet PolicyTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where OperationName == "Policy" and columnifexists("SchemaVersion_s", "") == "V2"\n| project PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", "") , PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""), PolicyName = columnifexists("PolicyName_s", ""), ResourceId, BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupManagementType, PolicyName, ResourceId, TimeGenerated \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by PolicyUniqueId,  ResourceId;\nPolicyTable\n};\nlet PolicyUnderResourceSpecific = ()\n{\nlet PolicyTable = AddonAzureBackupPolicy\n// Take records until previous day\n| where TimeGenerated >= _RangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "Policy" \n| project PolicyUniqueId, PolicyName, ResourceId, TimeGenerated, BackupManagementType\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by PolicyUniqueId,  ResourceId;\nPolicyTable\n};\n// BusinessLogic\nlet TotalBackupItemDimensionTable = () {union isfuzzy = true \n(BackupItemUnderAzureDiagnostics()),\n(BackupItemUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *)   by BackupItemUniqueId\n| where isempty(_BackupInstanceName) or _BackupInstanceName == "*" or  BackupItemFriendlyName contains (_BackupInstanceName)\n| extend BackupItemProtectionState = iff(BackupItemProtectionState in ("Protected", "ActivelyProtected","ProtectionError"), "Protected", iff(BackupItemProtectionState in ("IRPending"), "InitialBackupPending", iff(isnotempty(BackupItemProtectionState),"ProtectionStopped",BackupItemProtectionState)))\n| where BackupItemProtectionState in~ (_ProtectionInfoList) or \'*\' in (_ProtectionInfoList)\n| project BackupItemUniqueId,  BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nStorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter};\nlet BI_HistoryCombinationUnderAzureDiagnostics = ()\n{\n\tlet JoinWithPolicy = (T:(PolicyUniqueId:string, ResourceId:string))\n\t{\n\tT | join kind= leftouter (\n\t PolicyUnderAzureDiagnostics | project PolicyUniqueId, PolicyName, ResourceId) on PolicyUniqueId, ResourceId\n\t};\n\tlet JoinWithRP = (T:(BackupItemUniqueId:string, TimeRangeEndDay:datetime))\n\t{\n\tT | join kind= leftouter (\n\t RecoveryPointHistoryUnderAzureDiagnostics | project BackupItemUniqueId, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeRangeEndDay) on BackupItemUniqueId, TimeRangeEndDay\n\t};\n\tlet Base = ()\n\t{\n\tProtectedContainerUnderAzureDiagnostics | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n\t| join  kind= rightouter  (\n\t\tBackupItemAssociationHistoryUnderAzureDiagnostics |  project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t) on ProtectedContainerUniqueId\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size = ()\n\t{\n\tBase\n\t| join kind= leftouter (\n\t   BackupItemFrontEndSizeHistoryUnderAzureDiagnostics | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay \n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n\t| join kind= leftouter (\n\t   StorageAssociationHistoryUnderAzureDiagnostics | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay\n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Policy = ()\n\t{\n\tJoinWithPolicy(Base) \n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_RP = ()\n\t{\n\tJoinWithRP(Base)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Policy_RP = ()\n\t{\n\tJoinWithRP(Base_Policy)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size_RP = ()\n\t{\n\tJoinWithRP(Base_Size)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size_Policy = ()\n\t{\n\tJoinWithPolicy(Base_Size)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName,BackupItemFrontEndSize, StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size_Policy_RP = ()\n\t{\n\tJoinWithRP(Base_Size_Policy)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName,BackupItemFrontEndSize, StorageConsumedInMBs, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tunion ( Base | where _DisplayAllFields == false ),\t   \n\t   ( Base_Size_Policy_RP | where _DisplayAllFields== true)\n};\nlet BI_HistoryCombinationUnderResourceSpecific = ()\n{\n\tlet JoinWithPolicy = (T:(PolicyUniqueId:string, ResourceId:string))\n\t{\n\tT | join kind= leftouter (\n\t PolicyUnderResourceSpecific | project PolicyUniqueId, PolicyName, ResourceId) on PolicyUniqueId, ResourceId\n\t};\n\tlet JoinWithRP = (T:(BackupItemUniqueId:string, TimeRangeEndDay:datetime))\n\t{\n\tT | join kind= leftouter (\n\t RecoveryPointHistoryUnderResourceSpecific | project BackupItemUniqueId, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeRangeEndDay) on BackupItemUniqueId, TimeRangeEndDay\n\t};\n\tlet Base = ()\n\t{\n\tProtectedContainerUnderResourceSpecific | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n\t| join  kind= rightouter  (\n\t\tBackupItemAssociationHistoryUnderResourceSpecific |  project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t) on ProtectedContainerUniqueId\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size = ()\n\t{\n\tBase\n\t| join kind= leftouter (\n\t   BackupItemFrontEndSizeHistoryUnderResourceSpecific | project BackupItemFrontEndSize, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay \n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t// using leftouter due to AzureStorage - storageconsumption table is not emitted. inner join will exclude AzureStorage BackupItems.\n\t| join kind= leftouter (\n\t   StorageAssociationHistoryUnderResourceSpecific | project StorageConsumedInMBs, BackupItemUniqueId, TimeGenerated, TimeRangeEndDay\n\t) on BackupItemUniqueId, TimeRangeEndDay\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Policy = ()\n\t{\n\tJoinWithPolicy(Base) \n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_RP = ()\n\t{\n\tJoinWithRP(Base)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Policy_RP = ()\n\t{\n\tJoinWithRP(Base_Policy)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size_RP = ()\n\t{\n\tJoinWithRP(Base_Size)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, BackupItemFrontEndSize,\n\t StorageConsumedInMBs, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size_Policy = ()\n\t{\n\tJoinWithPolicy(Base_Size)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName,BackupItemFrontEndSize, StorageConsumedInMBs, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tlet Base_Size_Policy_RP = ()\n\t{\n\tJoinWithRP(Base_Size_Policy)\n\t| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName,BackupItemFrontEndSize, StorageConsumedInMBs, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated, TimeRangeEndDay, ResourceId\n\t};\n\tunion ( Base | where _DisplayAllFields == false ),\t   \n\t   ( Base_Size_Policy_RP | where _DisplayAllFields== true)\n};\nlet LatestBackupItemAssociationAndStorageConsumptionHistoryTable = ()\n//let partition_data = (p:long, n:long)\n{\nTotalBackupItemDimensionTable | join  \n(union isfuzzy = true  \n(BI_HistoryCombinationUnderAzureDiagnostics() | where _ExcludeLegacyEvent == false\n),\n(BI_HistoryCombinationUnderResourceSpecific())\n//| where hash(BackupItemUniqueId, n) == p\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId, TimeRangeEndDay)\n  on BackupItemUniqueId\n| where isempty(_DatasourceSetName) or _DatasourceSetName == "*" or ProtectedContainerFriendlyName contains (_DatasourceSetName)\n| project BackupItemUniqueId, BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState, VaultUniqueId,\nVaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, TimeGenerated, ResourceId,  ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, PolicyUniqueId, PolicyName, BackupItemFrontEndSize, StorageConsumedInMBs, BackupManagementServerUniqueId, StorageReplicationType, OldestRecoveryPointTime, LatestRecoveryPointTime\n};\nlet FinalTable = () {\nLatestBackupItemAssociationAndStorageConsumptionHistoryTable\n| project BackupItemName, BackupItemFriendlyName, BackupItemProtectionState, PolicyUniqueId, PolicyName = iff(BackupItemProtectionState == "ProtectionStopped", "(none)", PolicyName), SubscriptionId, ResourceGroupName, AzureDataCenter, VaultUniqueId, VaultName, VaultTags, BackupManagementType, BackupItemType, BackupSolution, BackupItemFrontEndSize,  StorageConsumedInMBs = iff(isempty(StorageConsumedInMBs), todouble(0), StorageConsumedInMBs), ResourceId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupItemUniqueId, StorageReplicationType, OldestRecoveryPointTime, LatestRecoveryPointTime, TimeGenerated\n};\nlet FinalTable_V1Vault = () {Extend_DatasourceType(Extend_BackupInstanceId(Extend_DatasourceSetResourceId_DatasourceSetType_DatasourceResourceId(FinalTable)))\n|  extend container_array = split(ProtectedContainerName,";")\n|  extend container_arraylen = array_length(container_array)\n| project UniqueId = BackupItemUniqueId, Id = BackupInstanceId, FriendlyName = BackupItemFriendlyName, ProtectionInfo = BackupItemProtectionState, LatestRecoveryPoint = LatestRecoveryPointTime, OldestRecoveryPoint = OldestRecoveryPointTime, SourceSizeInMBs = BackupItemFrontEndSize, VaultStore_StorageConsumptionInMBs = StorageConsumedInMBs, DataSourceFriendlyName = BackupItemFriendlyName, BackupSolution, DatasourceType, DatasourceResourceId, DatasourceSetFriendlyName = ProtectedContainerFriendlyName,   DatasourceSetResourceId, DatasourceSetType,  PolicyName, PolicyUniqueId, PolicyId = strcat(ResourceId, "/backupPolicies/", PolicyName),  VaultResourceId = ResourceId, VaultUniqueId, VaultName, VaultTags, VaultStore_StorageReplicationType = StorageReplicationType, VaultSubscriptionId = SubscriptionId, VaultLocation = AzureDataCenter, VaultType = "Microsoft.RecoveryServices/vaults", TimeGenerated};\n// FinalTable_DPPVault to be added later\nFinalTable_V1Vault \n| where "Microsoft.RecoveryServices/vaults" in~ (_VaultTypeList) or \'*\' in (_VaultTypeList)'
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
            'Initialize_variable-BackupInstanceTrendFunction': [
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
        'Initialize_variable-JobFunction': {
          runAfter: {
            'Initialize_variable-ReportFilterForHistoricalData': [
              'Succeeded'
            ]
          }
          type: 'InitializeVariable'
          inputs: {
            variables: [
              {
                name: 'JobFunction'
                type: 'string'
                value: '@{variables(\'workspacesToQuery_Custom\')}\n// Report filters\n@{variables(\'ReportFilter_Trend\')}\nlet _ProtectionStateList = "*";\nlet _DatasourceSetName = "*";\nlet _BackupInstanceName = "*";\nlet _JobOperationList = "*";\nlet _JobStatusList = "*";\nlet _JobFailureCodeList = "*";\nlet _ExcludeLog = true;\n// Other Vars\nlet ExtRangeStart = _RangeStart - 2d;\nlet ExtRangeEnd = _RangeEnd + 2d;\nlet AsonDay =  _RangeEnd-1d;\nlet AzureStorageCutoffDate = datetime(6/01/2020, 12:00:00.000 AM);\n// HelperFunctions\nlet Extend_BackupSolution = (T:(BackupManagementType:string, BackupItemType:string))\n{\nT | extend BackupSolution = iff(BackupManagementType == "IaaSVM", "Azure Virtual Machine Backup", \niff(BackupManagementType == "MAB", "Azure Backup Agent", \niff(BackupManagementType == "DPM", "DPM", \niff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", \niff(BackupManagementType == "AzureStorage", "Azure Storage (Azure Files) Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", "SQL in Azure VM Backup", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", "SAP HANA in Azure VM Backup", "")))))))\n};\nlet Extend_DatasourceType = (T:(BackupManagementType:string, BackupItemType:string))\n{\nT | extend DatasourceType = iff(BackupManagementType == "IaaSVM", "Microsoft.Compute/virtualMachines", \niff(BackupManagementType == "MAB", BackupItemType, \niff(BackupManagementType == "DPM", iff(BackupItemType == "SQLDB","SQLDataBase",BackupItemType), \niff(BackupManagementType == "AzureBackupServer", iff(BackupItemType == "SQLDB","SQLDataBase",BackupItemType), \niff(BackupManagementType == "AzureStorage", "Microsoft.Storage/storageAccounts/fileServices/shares", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", "SQLDataBase", \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", "SAPHanaDatabase", "")))))))\n};\nlet Extend_BackupInstanceId = (T:(ResourceId:string, BackupManagementType:string, BackupItemType:string, ProtectedContainerName:string, BackupItemName:string))\n{\nT | extend BackupInstanceId =  toupper(iff ((BackupManagementType == "IaaSVM" and BackupItemType == "VM"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/IaasVMContainer;", ProtectedContainerName, "/protectedItems/VM;", ProtectedContainerName),\niff((BackupManagementType == "AzureStorage" and BackupItemType == "AzureFileShare"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/StorageContainer;", ProtectedContainerName, "/protectedItems/AzureFileShare;", BackupItemName) , \niff((BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/VMAppContainer;", ProtectedContainerName, "/protectedItems/SQLDataBase;", BackupItemName) , \niff((BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase"), strcat(ResourceId,"/backupFabrics/Azure/protectionContainers/VMAppContainer;", ProtectedContainerName, "/protectedItems/SAPHanaDatabase;", BackupItemName), "")))))\n};\nlet Extend_DatasourceSetResourceId_DatasourceSetType_DatasourceResourceId = (T:(ResourceId:string, ProtectedContainerName:string, BackupManagementType:string, BackupItemType:string, BackupItemUniqueId:string, BackupItemName:string, BackupItemFriendlyName:string))\n{\nT | extend prefix = array_strcat(array_split(split(ResourceId,"/"), 4)[0] ,"/")\n|  extend container_array = split(ProtectedContainerName,";")\n|  extend container_arraylen = array_length(container_array)\n| extend containerNameString = iff(container_arraylen == 3, ProtectedContainerName, "")\n| parse containerNameString with entityType:string ";" rgName:string ";" entityName:string\n| extend entityURL = iff((BackupManagementType == "AzureStorage" and BackupItemType == "AzureFileShare"), iff(entityType == "storage", "/Microsoft.Storage/storageAccounts/", "/Microsoft.ClassicStorage/storageAccounts/"), iff((BackupManagementType == "IaaSVM" and BackupItemType == "VM"), iff(entityType =~ "iaasvmcontainerv2", "/Microsoft.Compute/virtualMachines/", "/Microsoft.ClassicCompute/virtualMachines/"), iff(((BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase") or (BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase")), iff(entityType =~ "compute", "/Microsoft.Compute/virtualMachines/", "/Microsoft.ClassicCompute/virtualMachines/"), "")))\n| extend DatasourceSetResourceId = toupper(iff(BackupManagementType in ("DPM", "AzureBackupServer", "MAB"), "" , iff(containerNameString != "", strcat(prefix, "/", rgName, "/providers", entityURL, entityName), "")))\n//BackupSolution\n| extend DatasourceSetType = iff(BackupManagementType == "IaaSVM", iff(entityType =~ "iaasvmcontainerv2", "Microsoft.Compute/virtualMachines", "Microsoft.ClassicCompute/virtualMachines"),  \niff(BackupManagementType == "MAB", "Azure Backup Agent", \niff(BackupManagementType == "DPM", "DPM", \niff(BackupManagementType == "AzureBackupServer", "Azure Backup Server", \niff(BackupManagementType == "AzureStorage", iff(entityType == "storage", "Microsoft.Storage/storageAccounts", "Microsoft.ClassicStorage/storageAccounts"), \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase", iff(entityType =~ "compute", "Microsoft.Compute/virtualMachines", "Microsoft.ClassicCompute/virtualMachines"), \niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase", iff(entityType =~ "compute", "Microsoft.Compute/virtualMachines", "Microsoft.ClassicCompute/virtualMachines"), "")))))))\n| extend DatasourceResourceId = toupper(iff(BackupManagementType in ("DPM", "AzureBackupServer", "MAB"), BackupItemUniqueId, \niff(BackupManagementType == "IaaSVM", DatasourceSetResourceId, \niff(BackupManagementType == "AzureStorage", strcat(DatasourceSetResourceId, "/fileServices/default/shares/", BackupItemFriendlyName),\niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SQLDataBase",iff(DatasourceSetResourceId != "",strcat(DatasourceSetResourceId, "/providers/Microsoft.RecoveryServices/backupProtectedItem/SQLDataBase;", BackupItemName),""),\niff(BackupManagementType == "AzureWorkload" and BackupItemType == "SAPHanaDatabase",iff(DatasourceSetResourceId != "",strcat(DatasourceSetResourceId, "/providers/Microsoft.RecoveryServices/backupProtectedItem/SAPHanaDatabase;", BackupItemName),""),""))))))\n| project-away prefix, container_array, container_arraylen, containerNameString, entityURL \n};\n// Source Tables\nlet VaultUnderAzureDiagnostics = ()\n{\nAzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "Vault" and columnifexists("SchemaVersion_s", "") == "V2"\n| project VaultName = columnifexists("VaultName_s", ""), VaultUniqueId = columnifexists("VaultUniqueId_s", ""), VaultTags = columnifexists("VaultTags_s", ""), AzureDataCenter =  columnifexists("AzureDataCenter_s", ""), ResourceGroupName =  columnifexists("ResourceGroupName_s", ""), SubscriptionId = toupper(SubscriptionId), StorageReplicationType = columnifexists("StorageReplicationType_s", ""), ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated\n};\nlet VaultUnderResourceSpecific = ()\n{\nCoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "Vault" \n| project StorageReplicationType, VaultUniqueId, VaultName, VaultTags, SubscriptionId = toupper(SubscriptionId), ResourceGroupName, AzureDataCenter, ResourceId, TimeGenerated \n| where SubscriptionId in~ (_VaultSubscriptionList) or \'*\' in (_VaultSubscriptionList)\n| where AzureDataCenter in~ (_VaultLocationList) or \'*\' in (_VaultLocationList)\n| where VaultName in~  (_VaultList) or \'*\' in (_VaultList)\n| summarize arg_max(TimeGenerated, *) by ResourceId\n};\nlet ResourceIdListUnderAzureDiagnostics = materialize(VaultUnderAzureDiagnostics | distinct ResourceId);\nlet ResourceIdListUnderResourceSpecific = materialize(VaultUnderResourceSpecific | distinct ResourceId);\nlet BackupItemUnderAzureDiagnostics = ()\n{\nlet SourceBackupItemTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "BackupItem" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupItemProtectionState = columnifexists("BackupItemProtectionState_s", ""), BackupItemAppVersion = columnifexists("BackupItemAppVersion_s", ""),SecondaryBackupProtectionState = columnifexists("SecondaryBackupProtectionState_s", ""), BackupItemName = columnifexists("BackupItemName_s", ""), BackupItemFriendlyName = columnifexists("BackupItemFriendlyName_s", ""),\nBackupItemType = columnifexists("BackupItemType_s", ""),  ProtectionGroupName = columnifexists("ProtectionGroupName_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet BackupItemUnderResourceSpecific = ()\n{\nlet SourceBackupItemTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "BackupItem" and State != "Deleted"\n//Handle MAB system state\n// Excluding SecondaryBackupProtectionState, BackupItemAppVersion, ProtectionGroupName\n|  project BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupItemName = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), "System State", BackupItemName), BackupItemProtectionState, BackupItemAppVersion, SecondaryBackupProtectionState, ProtectionGroupName, BackupItemFriendlyName, BackupItemType, BackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage");\nlet BackupItemTable = Extend_BackupSolution(SourceBackupItemTable)\n| where BackupSolution in~ (_BackupSolutionList) or \'*\' in (_BackupSolutionList)\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nVaultUnderResourceSpecific | join   (\n   BackupItemTable \n) on ResourceId\n| project-away ResourceId1, TimeGenerated1;\n};\nlet ProtectedContainerUnderAzureDiagnostics = ()\n{\nlet ProtectedContainerTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where Category == "AzureBackupReport" and OperationName == "ProtectedContainer"  and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""),  ProtectedContainerFriendlyName = columnifexists("ProtectedContainerFriendlyName_s", ""), AgentVersion = columnifexists("AgentVersion_s", ""),\nProtectedContainerOSType = columnifexists("ProtectedContainerOSType_s", ""), ProtectedContainerOSVersion = columnifexists("ProtectedContainerOSVersion_s", ""), ProtectedContainerWorkloadType = columnifexists("ProtectedContainerWorkloadType_s", ""),  ProtectedContainerName = columnifexists("ProtectedContainerName_s", ""), ProtectedContainerProtectionState = columnifexists("ProtectedContainerProtectionState_s", ""), ProtectedContainerLocation = columnifexists("ProtectedContainerLocation_s", ""), ProtectedContainerType = columnifexists("ProtectedContainerType_s", ""),\nBackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated, ResourceId \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderAzureDiagnostics | join   (\n   ProtectedContainerTable \n) on ResourceId;\n};\nlet ProtectedContainerUnderResourceSpecific = ()\n{\nlet ProtectedContainerTable = CoreAzureBackup\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where OperationName == "ProtectedContainer" and State != "Deleted"\n| project ProtectedContainerUniqueId,  ProtectedContainerFriendlyName, AgentVersion,\nProtectedContainerOSType, ProtectedContainerOSVersion, ProtectedContainerWorkloadType,  ProtectedContainerName, ProtectedContainerProtectionState, ProtectedContainerLocation, ProtectedContainerType,\nBackupManagementType, TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by ProtectedContainerUniqueId;\nVaultUnderResourceSpecific | join   (\n   ProtectedContainerTable \n) on ResourceId;\n};\nlet BackupItemAssociationUnderAzureDiagnostics = ()\n{\n let BackupItemAssociationTable = AzureDiagnostics \n // Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "BackupItemAssociation" and columnifexists("SchemaVersion_s", "") == "V2" and columnifexists("State_s", "") != "Deleted"\n| project BackupItemUniqueId = columnifexists("BackupItemUniqueId_s", ""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s", ""), ProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s", ""), \nVaultUniqueId = columnifexists("VaultUniqueId_s", ""), BackupManagementType = columnifexists("BackupManagementType_s", ""), PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", "") , PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""),\nTimeGenerated, ResourceId  \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n// PolicyUniqueId can be either guid or string due to AzureDiagnostics behaviour\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet BackupItemAssociationUnderResourceSpecific = ()\n{\nlet BackupItemAssociationTable = CoreAzureBackup \n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "BackupItemAssociation" and State != "Deleted"\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n// Handle MAB SystemState\n| project PolicyUniqueId, BackupItemUniqueId = iff((BackupManagementType == "MAB" and BackupItemUniqueId contains "ssbv\\\\"), replace(@"[^;]+$", @"systemstate", BackupItemUniqueId ), BackupItemUniqueId), BackupManagementServerUniqueId, ProtectedContainerUniqueId, VaultUniqueId, BackupManagementType, TimeGenerated, ResourceId\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId;\nBackupItemAssociationTable\n};\nlet PolicyUnderAzureDiagnostics = ()\n{\nlet PolicyTable = AzureDiagnostics\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where OperationName == "Policy" and columnifexists("SchemaVersion_s", "") == "V2"\n| project PolicyUniqueIdGuid = columnifexists("PolicyUniqueId_g", "") , PolicyUniqueIdStr = columnifexists("PolicyUniqueId_s", ""), PolicyName = columnifexists("PolicyName_s", ""), ResourceId, BackupManagementType = columnifexists("BackupManagementType_s", ""), TimeGenerated\n| project PolicyUniqueId = iff(PolicyUniqueIdGuid == "", PolicyUniqueIdStr, PolicyUniqueIdGuid), BackupManagementType, PolicyName, ResourceId, TimeGenerated \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by PolicyUniqueId,  ResourceId;\nPolicyTable\n};\nlet PolicyUnderResourceSpecific = ()\n{\nlet PolicyTable = AddonAzureBackupPolicy\n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= _RangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "Policy" \n| project PolicyUniqueId, PolicyName, ResourceId, TimeGenerated, BackupManagementType\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n//| where BackupManagementType in (BackupManagementTypeParam) or \'*\' in (BackupManagementTypeParam)\n| summarize arg_max(TimeGenerated, *) by PolicyUniqueId,  ResourceId;\nPolicyTable\n};\nlet JobUnderAzureDiagnostics = (IsBackupItemAssociatedJobsOnly:bool)\n{\nlet JobTable = AzureDiagnostics \n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= ExtRangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderAzureDiagnostics)\n| where Category == "AzureBackupReport" and OperationName == "Job" and columnifexists("SchemaVersion_s", "") == "V2"\n// Exclude Log Jobs and InProgress Jobs\n| project JobOperation = columnifexists("JobOperation_s", "") , JobOperationSubType = columnifexists("JobOperationSubType_s", ""), JobUniqueIdGuid = columnifexists("JobUniqueId_g", "") , JobUniqueIdStr = columnifexists("JobUniqueId_s", ""),\nProtectedContainerUniqueId = columnifexists("ProtectedContainerUniqueId_s",""), AdHocOrScheduledJob = columnifexists("AdHocOrScheduledJob_s",""), RecoveryJobDestination = columnifexists("RecoveryJobDestination_s",""),\nRecoveryJobRPDateTime = todatetime(columnifexists("RecoveryJobRPDateTime_s","")), RecoveryJobRPLocation = columnifexists("RecoveryJobRPLocation_s",""), RecoveryLocationType = columnifexists("RecoveryLocationType_s",""),\nBackupItemUniqueId = columnifexists("BackupItemUniqueId_s",""), BackupManagementServerUniqueId = columnifexists("BackupManagementServerUniqueId_s",""), VaultUniqueId = columnifexists("VaultUniqueId_s",""),\nJobStatus = columnifexists("JobStatus_s",""), JobFailureCode = columnifexists("JobFailureCode_s",""), JobStartDateTime = todatetime(columnifexists("JobStartDateTime_s","")), JobDurationInSecs = todouble(columnifexists("JobDurationInSecs_s", "")),\nDataTransferredInMB = todouble(columnifexists("DataTransferredInMB_s","")), BackupManagementType = columnifexists("BackupManagementType_s",""), TimeGenerated, ResourceId\n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (IsBackupItemAssociatedJobsOnly and BackupItemUniqueId != "") or ( not(IsBackupItemAssociatedJobsOnly))\n// Exclude Log Jobs and InProgress Jobs\n| where not(JobStatus == "InProgress")\n| where ( _ExcludeLog and not((JobOperation == "Backup" and JobOperationSubType == "Log") or (JobOperation  == "Backup" and JobOperationSubType == "Recovery point_Log"))) or not(_ExcludeLog) \n| extend JobUniqueId = iff(JobUniqueIdGuid == "", JobUniqueIdStr, JobUniqueIdGuid) \n| project-away JobUniqueIdGuid, JobUniqueIdStr\n| where JobStartDateTime >= _RangeStart and JobStartDateTime <= _RangeEnd\n| summarize arg_max(TimeGenerated, *)  by  BackupItemUniqueId, JobUniqueId ;\nJobTable\n};\nlet JobUnderResourceSpecific = (IsBackupItemAssociatedJobsOnly:bool)\n{\nlet JobTable = AddonAzureBackupJobs \n// Take records until previous day\n| where TimeGenerated >= ExtRangeStart and TimeGenerated <= ExtRangeEnd and TimeGenerated < startofday(now())\n| where ResourceId in (ResourceIdListUnderResourceSpecific)\n| where OperationName == "Job" \n| where not(TimeGenerated <= AzureStorageCutoffDate and BackupManagementType == "AzureStorage")\n| where (IsBackupItemAssociatedJobsOnly and BackupItemUniqueId != "") or ( not(IsBackupItemAssociatedJobsOnly))\n// Exclude Log Jobs and InProgress Jobs\n| where not(JobStatus == "InProgress")\n| where ( _ExcludeLog and not((JobOperation == "Backup" and JobOperationSubType == "Log") or (JobOperation  == "Backup" and JobOperationSubType == "Recovery point_Log"))) or not(_ExcludeLog)\n| where JobStartDateTime >= _RangeStart and JobStartDateTime <= _RangeEnd\n| summarize arg_max(TimeGenerated, *)  by BackupItemUniqueId, JobUniqueId;\nJobTable\n};\n// BusinessLogic\nlet TotalBackupItemDimensionTable = () {union isfuzzy = true \n(BackupItemUnderAzureDiagnostics()),\n(BackupItemUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *)   by BackupItemUniqueId\n| where isempty(_BackupInstanceName) or _BackupInstanceName == "*" or  BackupItemFriendlyName contains (_BackupInstanceName)\n| extend BackupItemProtectionState = iff(BackupItemProtectionState in ("Protected", "ActivelyProtected","ProtectionError"), "Protected", iff(BackupItemProtectionState in ("IRPending"), "InitialBackupPending", iff(isnotempty(BackupItemProtectionState),"ProtectionStopped",BackupItemProtectionState)))\n//| where BackupItemProtectionState in~ (_ProtectionInfoList) or \'*\' in (_ProtectionInfoList)\n| project BackupItemUniqueId,  BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nStorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter};\nlet BI_CombinationUnderAzureDiagnostics = ()\n{\nlet JoinWithPolicy = (T:(PolicyUniqueId:string, ResourceId:string))\n{\nT | join kind= leftouter (\n PolicyUnderAzureDiagnostics | project PolicyUniqueId, PolicyName, ResourceId) on PolicyUniqueId, ResourceId\n};\nlet Base = () {ProtectedContainerUnderAzureDiagnostics | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n| join kind= rightouter  (\n    BackupItemAssociationUnderAzureDiagnostics \n\t// To show as per as on \'AsonDay\'\n\t| where startofday(TimeGenerated) == AsonDay\n\t| project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n) on ProtectedContainerUniqueId \n| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n};\nlet Base_Policy = ()\n{\nJoinWithPolicy(Base) \n| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, TimeGenerated, ResourceId\n};\nBase_Policy\n};\nlet BI_CombinationUnderResourceSpecific = ()\n{\nlet JoinWithPolicy = (T:(PolicyUniqueId:string, ResourceId:string))\n{\nT | join kind= leftouter (\n PolicyUnderResourceSpecific | project PolicyUniqueId, PolicyName, ResourceId) on PolicyUniqueId, ResourceId\n};\nlet Base = () {ProtectedContainerUnderResourceSpecific | distinct ProtectedContainerName, ProtectedContainerFriendlyName, ProtectedContainerUniqueId \n| join kind= rightouter  (\n    BackupItemAssociationUnderResourceSpecific \n\t// To show as per as on \'AsonDay\'\n\t| where startofday(TimeGenerated) == AsonDay\n\t| project ProtectedContainerUniqueId, BackupItemUniqueId, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n) on ProtectedContainerUniqueId \n| project BackupItemUniqueId, ProtectedContainerUniqueId = ProtectedContainerUniqueId1, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, TimeGenerated, ResourceId\n};\nlet Base_Policy = ()\n{\nJoinWithPolicy(Base) \n| project BackupItemUniqueId, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, TimeGenerated, ResourceId\n};\nBase_Policy\n};\nlet LatestBackupItemWithProtectedContainerTable = () \n{\nTotalBackupItemDimensionTable\n| join  (union isfuzzy = true   \n(BI_CombinationUnderAzureDiagnostics()| where _ExcludeLegacyEvent == false),\n(BI_CombinationUnderResourceSpecific())\n| summarize arg_max(TimeGenerated, *) by BackupItemUniqueId) on BackupItemUniqueId\n| where isempty(_DatasourceSetName) or _DatasourceSetName == "*" or ProtectedContainerFriendlyName contains (_DatasourceSetName)\n| project BackupItemUniqueId,  BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState,\nStorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName, BackupManagementServerUniqueId, PolicyUniqueId, PolicyName, TimeGenerated\n};\nlet JobFinalTable = (){\n union isfuzzy = true \n(JobUnderAzureDiagnostics(true)| where _ExcludeLegacyEvent == false),\n(JobUnderResourceSpecific(true))\n| project JobStatus, JobUniqueId, JobOperation, JobFailureCode, JobOperationSubType, JobStartDateTime, DataTransferredInMB, AdHocOrScheduledJob, JobDurationInSecs, RecoveryJobDestination,\nRecoveryJobRPDateTime, RecoveryJobRPLocation, RecoveryLocationType, BackupItemUniqueId, ProtectedContainerUniqueId, TimeGenerated \n| summarize arg_max(TimeGenerated, *)  by BackupItemUniqueId, JobUniqueId\n| where JobOperation in~ (_JobOperationList) or \'*\' in (_JobOperationList)\n| where JobStatus in~ (_JobStatusList) or \'*\' in (_JobStatusList)\n| where JobFailureCode in~ (_JobFailureCodeList) or \'*\' in (_JobFailureCodeList)\n| join kind= inner (LatestBackupItemWithProtectedContainerTable) on BackupItemUniqueId\n| project JobUniqueId, JobOperation, JobStatus, JobFailureCode, JobOperationSubType, JobStartDateTime, JobDurationInSecs, DataTransferredInMB, AdHocOrScheduledJob, RecoveryJobDestination,\nRecoveryJobRPDateTime, RecoveryJobRPLocation, RecoveryLocationType, BackupItemUniqueId = BackupItemUniqueId1, BackupItemName, BackupItemFriendlyName, BackupManagementType, BackupItemType, BackupSolution, BackupItemProtectionState, StorageReplicationType, ResourceId, VaultUniqueId, VaultName, VaultTags, SubscriptionId, ResourceGroupName, AzureDataCenter, ProtectedContainerUniqueId, ProtectedContainerName, ProtectedContainerFriendlyName,  PolicyUniqueId, PolicyName, TimeGenerated\n};\nlet FinalTable_V1Vault = () {Extend_DatasourceType(Extend_BackupInstanceId(Extend_DatasourceSetResourceId_DatasourceSetType_DatasourceResourceId(JobFinalTable)))\n| project UniqueId = JobUniqueId, OperationCategory = JobOperation, Operation = JobOperationSubType, Status = JobStatus, ErrorTitle = JobFailureCode, StartTime = JobStartDateTime, DurationInSecs = JobDurationInSecs, DataTransferredInMBs = DataTransferredInMB, RestoreJobRPDateTime = RecoveryJobRPDateTime, RestoreJobRPLocation = RecoveryJobRPLocation, BackupInstanceUniqueId = BackupItemUniqueId, BackupInstanceId, BackupInstanceFriendlyName = BackupItemFriendlyName, DatasourceResourceId, DatasourceFriendlyName = BackupItemFriendlyName, DatasourceType, BackupSolution,  DatasourceSetResourceId, DatasourceSetType, DatasourceSetFriendlyName = ProtectedContainerFriendlyName, VaultResourceId = ResourceId, VaultUniqueId, VaultName, VaultTags, VaultSubscriptionId = SubscriptionId, VaultLocation = AzureDataCenter, VaultStore_StorageReplicationType = StorageReplicationType,   VaultType = "Microsoft.RecoveryServices/vaults", TimeGenerated};\nFinalTable_V1Vault \n| where "Microsoft.RecoveryServices/vaults" in~ (_VaultTypeList) or \'*\' in (_VaultTypeList)'
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
            'Create_CSV_table-JobList': {
              runAfter: {
                'Run_query_and_list_results-JobList': [
                  'Succeeded'
                ]
              }
              type: 'Table'
              inputs: {
                format: 'CSV'
                from: '@if(empty(body(\'Run_query_and_list_results-JobList\')?[\'value\']),variables(\'NoDataMessage\'),body(\'Run_query_and_list_results-JobList\')?[\'value\'])'
              }
            }
            'Run_query_and_list_results-JobList': {
              runAfter: {
                'Run_query_and_visualize_results-JobFailureCode': [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'JobFunction\')}\n| project BackupInstance=BackupInstanceFriendlyName, BackupInstanceId, Container=DatasourceSetFriendlyName, ResourceGroup=iff(DatasourceType=="Azure Backup Agent" or DatasourceType=="Azure Backup Server" or DatasourceType=="DPM","(none)",split(split(tostring(tolower(DatasourceSetResourceId)), \'/resourcegroups/\')[1],\'/\')[0]\n), OperationCategory, JobStatus=Status,  JobStartDateTime=StartTime, JobDuration=DurationInSecs/3600, ErrorTitle, DataTransferred=DataTransferredInMBs, AzureResource=DatasourceSetResourceId, DatasourceType '
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
            'Run_query_and_visualize_results-JobFailureCode': {
              runAfter: {
                'Run_query_and_visualize_results-JobOperation': [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'JobFunction\')}\n// query to transform function output\n| where Status == "Failed"\n| summarize JobFailureCode = any(ErrorTitle), JobOperation = any(OperationCategory) by UniqueId\n| summarize count(JobOperation) by JobFailureCode\n| sort by count_JobOperation'
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
                  visType: 'Pie Chart'
                }
              }
            }
            'Run_query_and_visualize_results-JobOperation': {
              runAfter: {
                'Run_query_and_visualize_results-JobStatus': [
                  'Succeeded'
                ]
              }
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'JobFunction\')}\n// query to transform function output\n| summarize Status = any(Status), Operation = any(OperationCategory) by UniqueId\n| summarize count(Status) by Operation\n| sort by Operation'
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
                  visType: 'Bar Chart'
                }
              }
            }
            'Run_query_and_visualize_results-JobStatus': {
              type: 'ApiConnection'
              inputs: {
                body: '@{variables(\'JobFunction\')}\n// query to transform function output\n| summarize arg_max(TimeGenerated, Status) by UniqueId\n| summarize count(Status) by  Status, bin(TimeGenerated, 1d)\n| project TimeGenerated, count_Status, JobStatus = ( iff(Status == "Completed", "Succeeded", iff(Status == "CompletedWithWarnings", "SucceededWithWarnings", Status)))\n| sort by TimeGenerated asc'
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
                  visType: 'Bar Chart'
                }
              }
            }
            'Set_variable-EmailBodyForSuccessfulRun': {
              runAfter: {
                'Create_CSV_table-JobList': [
                  'Succeeded'
                ]
              }
              type: 'SetVariable'
              inputs: {
                name: 'visual'
                value: '<div>\n<h3> Jobs by Status </h3>\n<br>\n<img src="cid:@{body(\'Run_query_and_visualize_results-JobStatus\')?[\'attachmentName\']}" width:"50px"/>\n<br>\n<h3> Jobs by JobOperation </h3>\n<br>\n<img src="cid:@{body(\'Run_query_and_visualize_results-JobOperation\')?[\'attachmentName\']}" width:"50px"/>\n<br>\n<h3> Jobs by Failure Code</h3> \n<br>\n<img src="cid:@{body(\'Run_query_and_visualize_results-JobFailureCode\')?[\'attachmentName\']}" width:"50px"/>\n<br>\n</div>'
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