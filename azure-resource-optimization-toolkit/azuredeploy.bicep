@description('Enter new GUID, you can generate one from Powershell using new-guid or get one from this site: <a target=new href=https://guidgenerator.com/online-guid-generator.aspx>GUID Generator</a>')
param newGuid string = newGuid()

@description('Assign a name for the Automation account of your choosing.  Must be a unique name as Azure Automation accounts are FQDNs')
param automationAccountName string = 'aa-${uniqueString(resourceGroup().id)}'

@description('Specify the region for your Automation account')
param location string = resourceGroup().location

@description('Enter your service admin user, ex: serviceaccount@microsoft.com.  Must be owner on the subscription you\'re deploying to during template deployment.')
param azureAdmin string

@description('Enter the password for the service admin user. The pwd is encrypted during runtime and in the Automation assets')
@secure()
param azureAdminPwd string

@description('The base URI where artifacts required by this template are located')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

var omsWorkspaceId = ''
var AzureRM_Profile = {
  name: 'AzureRm.Profile'
  url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.profile.2.8.0.nupkg'
}
var psModules = [
  {
    name: 'AzureRM.Compute'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.compute.2.9.0.nupkg'
  }
  {
    name: 'AzureRm.Resources'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.resources.3.8.0.nupkg'
  }
  {
    name: 'AzureRm.KeyVault'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.keyvault.2.8.0.nupkg'
  }
  {
    name: 'AzureRm.Automation'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.automation.2.8.0.nupkg'
  }
  {
    name: 'AzureRm.OperationalInsights'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.operationalinsights.2.8.0.nupkg'
  }
  {
    name: 'AzureRm.SiteRecovery'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.siterecovery.3.7.0.nupkg'
  }
  {
    name: 'AzureRm.RecoveryServices'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.recoveryservices.2.8.0.nupkg'
  }
  {
    name: 'AzureRm.Backup'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.backup.2.8.0.nupkg'
  }
  {
    name: 'AzureRm.Insights'
    url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.insights.2.8.0.nupkg'
  }
]
var runbooks = [
  {
    name: 'Bootstrap_Main'
    version: '1.0.0.0'
    description: 'Configurates Azure Automation account for anything we can\'t handle in ARM'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/Bootstrap_Main.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'SequencedSnooze_Parent'
    version: '1.0.0.0'
    description: 'Sequenced Snooze(stop) or UnSnooze(start)'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/SequencedSnooze/SequencedSnooze_Parent.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'DisableAllOptimizations'
    version: '1.0.0.0'
    description: 'Abort the ARO Toolkit'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/DisableAllOptimizations.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'AROToolkit_AutoUpdate'
    version: '1.0.0.0'
    description: 'Autoupdate the ARO Toolkit'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/AROToolkit_AutoUpdate.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'ScheduledSnooze_Parent'
    version: '1.0.0.0'
    description: 'Parallel execution of scheduled snooze actions'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/ScheduleSnooze/ScheduledSnooze_Parent.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'ScheduledSnooze_Child'
    version: '1.0.0.0'
    description: 'Placeholder'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/ScheduleSnooze/ScheduledSnooze_Child.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'AutoSnooze_StopVM_Child'
    version: '1.0.0.0'
    description: 'Runbook to stop indivual ARM VM, called by CreateAlertsForAzureRmVM'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/Snooze/AutoSnooze_StopVM_Child.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'AutoSnooze_CreateAlert_Parent'
    version: '1.0.0.0'
    description: 'Runbook to create alerts for AutoSnooze'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/Snooze/AutoSnooze_CreateAlert_Parent.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'AutoSnooze_CreateAlert_Child'
    version: '1.0.0.0'
    description: 'Runbook to create or disable alert for AutoSnooze'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/Snooze/AutoSnooze_CreateAlert_Child.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'AutoSnooze_Disable'
    version: '1.0.0.0'
    description: 'Disable the AutoSnooze'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/Snooze/AutoSnooze_Disable.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'DeleteResourceGroups_Parent'
    version: '1.0.0.0'
    description: 'This runbook will delete resource groups'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/DeleteRG/DeleteResourceGroups_Parent.ps1${artifactsLocationSasToken}')
  }
  {
    name: 'DeleteResourceGroup_Child'
    version: '1.0.0.0'
    description: 'This runbook will delete resource groups'
    type: 'PowerShell'
    Id: ''
    scriptUri: uri(artifactsLocation, 'scripts/DeleteRG/DeleteResourceGroup_Child.ps1${artifactsLocationSasToken}')
  }
]
var internalAzureSubscriptionId = {
  name: 'Internal_AzureSubscriptionId'
  description: 'Azure Subscription Id'
  value: '"${subscription().subscriptionId}"'
}
var automationVariables = [
  {
    name: 'Internal_AROAutomationAccountName'
    description: 'OMS Azure Automation Account Name'
    value: '"${automationAccountName}"'
  }
  {
    name: 'Internal_AROResourceGroupName'
    description: 'ARO Azure Automation Account resource group name'
    value: '"${resourceGroup().name}"'
  }
  {
    name: 'External_ExcludeVMNames'
    description: 'Excluded VMs as comma separated list: vm1,vm2,vm3'
    value: '""'
  }
  {
    name: 'External_ResourceGroupNames'
    description: 'Resource groups (as comma seperated) targeted for Snooze actions: rg1,rg2,rg3'
    value: '""'
  }
  {
    name: 'External_AutoSnooze_Condition'
    description: 'This is the conditional operator required for configuring the condition before triggering an alert. Possible values are [GreaterThan, GreaterThanOrEqual, LessThan, LessThanOrEqual]'
    value: '"LessThan"'
  }
  {
    name: 'External_AutoSnooze_Description'
    description: 'Alert to stop the VM if the CPU % exceed the threshold'
    value: '"Alert to stop the VM if the CPU % exceed the threshold"'
  }
  {
    name: 'External_AutoSnooze_MetricName'
    description: 'Name of the metric the Azure Alert rule is to be configured for'
    value: '"Percentage CPU"'
  }
  {
    name: 'External_AutoSnooze_Threshold'
    description: 'Threshold for the Azure Alert rule. Possible percentage values ranging from 1 to 100'
    value: '"5"'
  }
  {
    name: 'External_AutoSnooze_TimeAggregationOperator'
    description: 'The time aggregation operator which will be applied to the selected window size to evaluate the condition. Possible values are [Average, Minimum, Maximum, Total, Last]'
    value: '"Average"'
  }
  {
    name: 'External_AutoSnooze_TimeWindow'
    description: 'The window size over which Azure will analyze selected metric for triggering an alert. This parameter accepts input in timespan format. Possible values are from 5 mins to 6 hours.'
    value: '"06:00:00"'
  }
  {
    name: 'Internal_OMSWorkspaceId'
    description: 'OMS Log Analytics Location Id'
    value: '"${omsWorkspaceId}"'
  }
]
var azureCredentials = 'AzureCredentials'
var AROToolkitVersion = '1.0.0.0'

resource automationAccountName_resource 'Microsoft.Automation/automationAccounts@2020-01-13-preview' = {
  location: location
  name: automationAccountName
  tags: {
    AROToolkitVersion: AROToolkitVersion
  }
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationAccountName_automationVariables_name 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = [for item in automationVariables: {
  name: '${automationAccountName}/${item.name}'
  properties: {
    description: item.description
    value: item.value
  }
  dependsOn: [
    automationAccountName_resource
  ]
}]

resource automationAccountName_internalAzureSubscriptionId_name 'Microsoft.Automation/automationAccounts/variables@2020-01-13-preview' = {
  parent: automationAccountName_resource
  name: '${internalAzureSubscriptionId.name}'
  properties: {
    description: internalAzureSubscriptionId.description
    isEncrypted: 1
    type: 'string'
    value: internalAzureSubscriptionId.value
  }
}

resource automationAccountName_azureCredentials 'Microsoft.Automation/automationAccounts/credentials@2020-01-13-preview' = {
  parent: automationAccountName_resource
  name: '${azureCredentials}'
  properties: {
    description: 'Azure Subscription Credentials'
    password: azureAdminPwd
    userName: azureAdmin
  }
}

resource automationAccountName_AzureRM_Profile_name 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = {
  parent: automationAccountName_resource
  name: '${AzureRM_Profile.name}'
  properties: {
    contentLink: {
      uri: AzureRM_Profile.url
    }
  }
}

resource automationAccountName_psModules_name 'Microsoft.Automation/automationAccounts/modules@2020-01-13-preview' = [for item in psModules: {
  name: '${automationAccountName}/${item.name}'
  properties: {
    contentLink: {
      uri: item.url
    }
  }
  dependsOn: [
    automationAccountName_resource
    automationAccountName_AzureRM_Profile_name
  ]
}]

resource automationAccountName_runbooks_name 'Microsoft.Automation/automationAccounts/runbooks@2018-06-30' = [for item in runbooks: {
  name: '${automationAccountName}/${item.name}'
  location: location
  tags: {
    version: item.version
  }
  properties: {
    runbookType: item.type
    logProgress: false
    logVerbose: false
    description: item.description
    publishContentLink: {
      uri: item.scriptUri
      version: item.version
    }
  }
  dependsOn: [
    automationAccountName_resource
    automationAccountName_AzureRM_Profile_name
    automationAccountName_psModules_name
  ]
}]

resource automationAccountName_startBootstrap 'Microsoft.Automation/automationAccounts/schedules@2020-01-13-preview' = {
  parent: automationAccountName_resource
  name: 'startBootstrap'
  properties: {
    description: 'Starts the bootstrap runbooks'
    expiryTime: '12/31/9999 6:59:00 PM'
    isEnabled: true
    frequency: 'OneTime'
  }
  dependsOn: [
    runbooks[0].name
  ]
}

resource automationAccountName_newGuid 'Microsoft.Automation/automationAccounts/jobSchedules@2020-01-13-preview' = {
  parent: automationAccountName_resource
  name: '${newGuid}'
  location: location
  properties: {
    schedule: {
      name: 'startBootstrap'
    }
    runbook: {
      name: 'Bootstrap_Main'
    }
  }
  dependsOn: [
    automationAccountName_startBootstrap
    automationAccountName_psModules_name
  ]
}