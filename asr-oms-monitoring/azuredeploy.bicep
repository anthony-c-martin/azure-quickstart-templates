param omsLogAnalyticsWorkspaceName string {
  metadata: {
    description: 'Create new or refer to an existing Log Analytic Workspace'
  }
  default: 'omslawsasr'
}
param omsLogAnalyticsRegion string {
  allowed: [
    'westeurope'
    'eastus'
    'southeastasia'
  ]
  metadata: {
    description: 'Specify the Azure Region for your new or existing OMS workspace'
  }
  default: 'westeurope'
}
param omsAutomationAccountName string {
  metadata: {
    description: 'Use an existing Automation account or create a new'
  }
  default: 'omsaaasr'
}
param omsAutomationRegion string {
  allowed: [
    'westeurope'
    'southeastasia'
    'eastus2'
    'southcentralus'
    'japaneast'
  ]
  metadata: {
    description: 'Specify the Azure Region for your OMS Automation Account'
  }
  default: 'westeurope'
}
param ingestScheduleGuid string {
  metadata: {
    description: 'GUID for the schedule creation - create a unique before deploy'
  }
  default: '66533407-3d53-4131-a2a6-ead17a08fa0c'
}
param assetLocation string {
  metadata: {
    description: 'Path of the template folder.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/asr-oms-monitoring'
}

var psModules = {
  azureRmProfile: {
    name: 'AzureRm.Profile'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.profile.1.0.11.nupkg'
  }
  azureRmResources: {
    name: 'AzureRm.Resources'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.resources.2.0.2.nupkg'
  }
  azureStorage: {
    name: 'Azure.Storage'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azure.storage.1.1.5.nupkg'
  }
  azureRmStorage: {
    name: 'AzureRm.Storage'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.storage.1.1.3.nupkg'
  }
  azureRmOperationalInsights: {
    name: 'AzureRm.OperationalInsights'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.operationalinsights.1.0.9.nupkg'
  }
  azureRmSiteRecovery: {
    name: 'AzureRm.SiteRecovery'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.siterecovery.1.1.10.nupkg'
  }
  azureRmRecoveryServices: {
    name: 'AzureRm.RecoveryServices'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.recoveryservices.1.1.3.nupkg'
  }
  azureRmBackup: {
    name: 'AzureRm.Backup'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.backup.1.0.9.nupkg'
  }
  azureRmCompute: {
    name: 'AzureRm.Compute'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.compute.1.3.3.nupkg'
  }
  azureRmAutomation: {
    name: 'AzureRm.Automation'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.automation.1.0.11.nupkg'
  }
  omsASRMonitoring: {
    name: 'OMSIngestionAPI'
    url: 'https://github.com/krnese/AzureDeploy/raw/master/OMS/OMSIngestionAPI.zip'
  }
}
var runbooks = {
  omsASRMonitoring: {
    name: 'OMSASRMonitoring'
    version: '1.0.0.0'
    description: 'Runbook to automatically ingest Recovery Services data and events into OMS Log Analytics'
    type: 'PowerShell'
    Id: ''
  }
}
var ingestScheduleName = 'IngestAPISchedule'
var ingestionScriptUri = '${assetLocation}/scripts/OMSASRMonitoring.ps1'
var ingestInterval = '1'
var ingestFrequency = 'hour'
var azureSubscriptionId = 'AzureSubscriptionId'
var omsWorkspaceId = 'OMSWorkspaceId'
var omsWorkspaceKey = 'OMSWorkspacekey'

resource omslogAnalyticsWorkspaceName_res 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: omsLogAnalyticsWorkspaceName
  location: omsLogAnalyticsRegion
}

resource omslogAnalyticsWorkspaceName_Microsoft_Windows_Hyper_V_VMMS_Admin 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Microsoft-Windows-Hyper-V-VMMS-Admin'
  kind: 'WindowsEvent'
  properties: {
    eventLogName: 'Microsoft-Windows-Hyper-V-VMMS-Admin'
    eventTypes: [
      {
        eventType: 'Error'
      }
      {
        eventType: 'Warning'
      }
      {
        eventType: 'Information'
      }
    ]
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent1 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent1'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Average Replication Size'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent2 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent2'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Replication Throughput'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent3 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent3'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Network Send Throughput'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent4 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent4'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Replication Count'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent5 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent5'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Network Bytes Sent'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent6 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent6'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Last Replication Size'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent7 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  name: '${omsLogAnalyticsWorkspaceName}/Hyper-VAzureReplicationAgent7'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Resynchronized Bytes'
  }
  dependsOn: [
    omslogAnalyticsWorkspaceName_res
  ]
}

resource omsAutomationAccountName_res 'Microsoft.Automation/automationAccounts@2015-10-31' = {
  location: omsAutomationRegion
  name: omsAutomationAccountName
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource omsAutomationAccountName_omsWorkspaceId 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${omsAutomationAccountName}/${omsWorkspaceId}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'OMS Workspace Id'
    value: '"${reference(omslogAnalyticsWorkspaceName_res.id, '2015-11-01-preview').customerId}"'
  }
  dependsOn: [
    omsAutomationAccountName_res
  ]
}

resource omsAutomationAccountName_omsWorkspaceKey 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${omsAutomationAccountName}/${omsWorkspaceKey}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'OMS Workspace key'
    value: '"${listKeys(omslogAnalyticsWorkspaceName_res.id, '2015-11-01-preview').primarySharedKey}"'
  }
  dependsOn: [
    omsAutomationAccountName_res
  ]
}

resource omsAutomationAccountName_azureSubscriptionId 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  name: '${omsAutomationAccountName}/${azureSubscriptionId}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'Azure Subscription Id'
    isEncrypted: false
    type: 'string'
    value: '"${subscription().subscriptionId}"'
  }
  dependsOn: [
    omsAutomationAccountName_res
  ]
}

resource omsAutomationAccountName_psModules_azureRmOperationalInsights_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmOperationalInsights.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRMOperationalInsights.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmResources_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmResources.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.AzureRMResources.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmAutomation_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmAutomation.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRMAutomation.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureRmResources_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmStorage_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmStorage.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmStorage.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureStorage_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureStorage.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureStorage.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmCompute_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmCompute.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmCompute.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmSiteRecovery_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmSiteRecovery.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.AzureRmSiteRecovery.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmbackup_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmbackup.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmBackup.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmRecoveryServices_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmRecoveryServices.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmRecoveryServices.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmProfile_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.azureRmProfile.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmProfile.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
  ]
}

resource omsAutomationAccountName_psModules_omsASRMonitoring_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${psModules.omsASRMonitoring.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.omsASRMonitoring.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_runbooks_omsASRMonitoring_name 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = {
  name: '${omsAutomationAccountName}/${runbooks.omsASRMonitoring.name}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    runbookType: runbooks.omsASRMonitoring.type
    logProgress: false
    logVerbose: false
    description: runbooks.omsASRMonitoring.description
    publishContentLink: {
      uri: ingestionScriptUri
      version: runbooks.omsASRMonitoring.version
    }
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_azureSubscriptionId
    omsAutomationAccountName_omsWorkspaceId
    omsAutomationAccountName_omsWorkspaceKey
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureRmResources_name
    omsAutomationAccountName_psModules_azureRmCompute_name
    omsAutomationAccountName_psModules_azureStorage_name
    omsAutomationAccountName_psModules_azureRmStorage_name
    omsAutomationAccountName_psModules_azureRmRecoveryServices_name
    omsAutomationAccountName_psModules_azureRmSiteRecovery_name
    omsAutomationAccountName_psModules_azureRmbackup_name
    omsAutomationAccountName_psModules_azureRmOperationalInsights_name
    omsAutomationAccountName_psModules_azureRmAutomation_name
    omsAutomationAccountName_psModules_omsASRMonitoring_name
  ]
}

resource omsAutomationAccountName_ingestscheduleName 'microsoft.automation/automationAccounts/schedules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${ingestScheduleName}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'OMS Ingestion API Scheduler'
    startTime: ''
    isEnabled: 'true'
    interval: ingestInterval
    frequency: ingestFrequency
  }
  dependsOn: [
    omsAutomationAccountName_res
    omsAutomationAccountName_runbooks_omsASRMonitoring_name
  ]
}

resource omsAutomationAccountName_IngestScheduleGuid 'microsoft.automation/automationAccounts/jobSchedules@2015-10-31' = {
  name: '${omsAutomationAccountName}/${ingestScheduleGuid}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    schedule: {
      name: ingestScheduleName
    }
    runbook: {
      name: runbooks.omsASRMonitoring.name
    }
  }
  dependsOn: [
    omsAutomationAccountName_ingestscheduleName
    omsAutomationAccountName_runbooks_omsASRMonitoring_name
    omsAutomationAccountName_res
  ]
}

output AutomationAccontName string = 'Microsoft.Automation/automationAccounts/${omsAutomationAccountName}'
output LogAnalyticsworkspacename string = 'Microsoft.OperationalInsights/workspaces/${omsLogAnalyticsWorkspaceName}'