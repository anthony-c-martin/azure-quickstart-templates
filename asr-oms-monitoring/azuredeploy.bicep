@description('Create new or refer to an existing Log Analytic Workspace')
param omsLogAnalyticsWorkspaceName string = 'omslawsasr'

@allowed([
  'westeurope'
  'eastus'
  'southeastasia'
])
@description('Specify the Azure Region for your new or existing OMS workspace')
param omsLogAnalyticsRegion string = 'westeurope'

@description('Use an existing Automation account or create a new')
param omsAutomationAccountName string = 'omsaaasr'

@allowed([
  'westeurope'
  'southeastasia'
  'eastus2'
  'southcentralus'
  'japaneast'
])
@description('Specify the Azure Region for your OMS Automation Account')
param omsAutomationRegion string = 'westeurope'

@description('GUID for the schedule creation - create a unique before deploy')
param ingestScheduleGuid string = '66533407-3d53-4131-a2a6-ead17a08fa0c'

@description('Path of the template folder.')
param assetLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/asr-oms-monitoring'

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

resource omslogAnalyticsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: omsLogAnalyticsWorkspaceName
  location: omsLogAnalyticsRegion
}

resource omslogAnalyticsWorkspaceName_Microsoft_Windows_Hyper_V_VMMS_Admin 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Microsoft-Windows-Hyper-V-VMMS-Admin'
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
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent1 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent1'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Average Replication Size'
  }
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent2 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent2'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Replication Throughput'
  }
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent3 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent3'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Network Send Throughput'
  }
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent4 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent4'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Replication Count'
  }
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent5 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent5'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Network Bytes Sent'
  }
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent6 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent6'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Last Replication Size'
  }
}

resource omslogAnalyticsWorkspaceName_Hyper_VAzureReplicationAgent7 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omslogAnalyticsWorkspaceName_resource
  name: 'Hyper-VAzureReplicationAgent7'
  kind: 'WindowsPerformanceCounter'
  properties: {
    objectName: 'Hyper-V Azure Replication Agent'
    instanceName: '*'
    intervalSeconds: 10
    counterName: 'Resynchronized Bytes'
  }
}

resource omsAutomationAccountName_resource 'Microsoft.Automation/automationAccounts@2015-10-31' = {
  location: omsAutomationRegion
  name: omsAutomationAccountName
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource omsAutomationAccountName_omsWorkspaceId 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${omsWorkspaceId}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'OMS Workspace Id'
    value: '"${reference(omslogAnalyticsWorkspaceName_resource.id, '2015-11-01-preview').customerId}"'
  }
}

resource omsAutomationAccountName_omsWorkspaceKey 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${omsWorkspaceKey}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'OMS Workspace key'
    value: '"${listKeys(omslogAnalyticsWorkspaceName_resource.id, '2015-11-01-preview').primarySharedKey}"'
  }
}

resource omsAutomationAccountName_azureSubscriptionId 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${azureSubscriptionId}'
  location: omsAutomationRegion
  tags: {}
  properties: {
    description: 'Azure Subscription Id'
    isEncrypted: false
    type: 'string'
    value: '"${subscription().subscriptionId}"'
  }
}

resource omsAutomationAccountName_psModules_azureRmOperationalInsights_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmOperationalInsights.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmOperationalInsights.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmResources_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmResources.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmResources.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmAutomation_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmAutomation.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmAutomation.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureRmResources_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmStorage_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmStorage.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmStorage.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureStorage_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureStorage.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureStorage.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmCompute_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmCompute.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmCompute.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmSiteRecovery_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmSiteRecovery.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmSiteRecovery.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmbackup_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmBackup.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmBackup.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmRecoveryServices_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmRecoveryServices.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmRecoveryServices.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureRmProfile_name
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_psModules_azureRmProfile_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.azureRmProfile.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.azureRmProfile.url
    }
  }
}

resource omsAutomationAccountName_psModules_omsASRMonitoring_name 'Microsoft.Automation/automationAccounts/Modules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${psModules.omsASRMonitoring.name}'
  tags: {}
  properties: {
    contentLink: {
      uri: psModules.omsASRMonitoring.url
    }
  }
  dependsOn: [
    omsAutomationAccountName_psModules_azureStorage_name
  ]
}

resource omsAutomationAccountName_runbooks_omsASRMonitoring_name 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${runbooks.omsASRMonitoring.name}'
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
  parent: omsAutomationAccountName_resource
  name: '${ingestScheduleName}'
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
    omsAutomationAccountName_runbooks_omsASRMonitoring_name
  ]
}

resource omsAutomationAccountName_IngestScheduleGuid 'microsoft.automation/automationAccounts/jobSchedules@2015-10-31' = {
  parent: omsAutomationAccountName_resource
  name: '${ingestScheduleGuid}'
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
  ]
}

output AutomationAccontName string = 'Microsoft.Automation/automationAccounts/${omsAutomationAccountName}'
output LogAnalyticsworkspacename string = 'Microsoft.OperationalInsights/workspaces/${omsLogAnalyticsWorkspaceName}'