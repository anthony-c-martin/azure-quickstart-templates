@description('Specify the name of your Automation Account')
param automationAccountName string

@allowed([
  'westeurope'
  'southeastasia'
  'eastus2'
  'southcentralus'
  'japaneast'
  'northeurope'
  'canadacentral'
  'australiasoutheast'
  'centralindia'
  'westcentralus'
])
@description('Specify the region for your automation account')
param automationRegion string

@description('URI to artifacts location')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/asr-automation-recovery'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

var assets = {
  aaVariables: {
    AzureSubscriptionId: {
      name: 'AzureSubscriptionId'
      description: 'Azure subscription Id'
    }
  }
}
var asrScripts = {
  runbooks: [
    {
      name: 'ASR-AddPublicIp'
      url: '${artifactsLocation}/scripts/ASR-AddPublicIp.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShell'
      description: 'ASR Runbook to enable public IP on every VM in a Recovery Plan'
    }
    {
      name: 'ASR-SQL-FailoverAG'
      url: '${artifactsLocation}/scripts/ASR-SQL-FailoverAG.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShellWorkflow'
      description: 'ASR Runbook to handle SQL Always On failover'
    }
    {
      name: 'ASR-AddSingleNSGPublicIp'
      url: '${artifactsLocation}/scripts/ASR-AddSingleNSGPublicIp.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShell'
      description: 'ASR Runbook to enable NSG and Public IP on every VM in a Recovery Plan'
    }
    {
      name: 'ASR-AddSingleLoadBalancer'
      url: '${artifactsLocation}/scripts/ASR-AddSingleLoadBalancer.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShell'
      description: 'ASR Runbook to enable a single Load Balancer for all the VMs in the recovery plan'
    }
    {
      name: 'ASR-AddMulitpleLoadBalancers'
      url: '${artifactsLocation}/scripts/ASR-AddMultipleLoadBalancers.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShell'
      description: 'ASR Runbook to enable multiple Load Balancers for selected VMs in the recovery plan'
    }
    {
      name: 'ASR-DNS-UpdateIP'
      url: '${artifactsLocation}/scripts/ASR-DNS-UpdateIP.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShellWorkflow'
      description: 'ASR Runbook to update DNS for VMs within the recovery plan'
    }
    {
      name: 'ASR-Wordpress-ChangeMysqlConfig'
      url: '${artifactsLocation}/scripts/ASR-Wordpress-ChangeMysqlConfig.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShellWorkflow'
      description: 'ASR Runbook to configure Mysql as part of a recovery plan'
    }
    {
      name: 'ASR-SQL-FailoverAGClassic'
      url: '${artifactsLocation}/scripts/ASR-SQL-FailoverAGClassic.ps1${artifactsLocationSasToken}'
      version: '1.0.0.0'
      type: 'PowerShellWorkflow'
      description: 'ASR Runbook to failover SQL Availability Groups'
    }
  ]
  modules: [
    {
      name: 'AzureRm.Compute'
      url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.compute.2.8.0.nupkg'
    }
    {
      name: 'AzureRm.Resources'
      url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.resources.3.7.0.nupkg'
    }
    {
      name: 'AzureRm.Network'
      url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.network.3.6.0.nupkg'
    }
    {
      name: 'AzureRm.Automation'
      url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.automation.1.0.3.nupkg'
    }
  ]
}
var azureRmProfile = {
  name: 'AzureRm.Profile'
  url: 'https://devopsgallerystorage.blob.core.windows.net/packages/azurerm.profile.2.7.0.nupkg'
}

resource automationAccountName_resource 'Microsoft.Automation/automationAccounts@2015-10-31' = {
  name: automationAccountName
  location: automationRegion
  properties: {
    sku: {
      name: 'Basic'
    }
  }
}

resource automationAccountName_assets_aaVariables_AzureSubscriptionId_name 'Microsoft.Automation/automationAccounts/variables@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${assets.aaVariables.AzureSubscriptionId.name}'
  tags: {}
  properties: {
    description: assets.aaVariables.AzureSubscriptionId.description
    value: '"${subscription().subscriptionId}"'
  }
}

resource automationAccountName_asrScripts_runbooks_Name 'Microsoft.Automation/automationAccounts/runbooks@2015-10-31' = [for i in range(0, length(asrScripts.runbooks)): {
  name: '${automationAccountName}/${asrScripts.runbooks[i].Name}'
  location: automationRegion
  properties: {
    description: asrScripts.runbooks[i].description
    runbookType: asrScripts.runbooks[i].type
    logProgress: false
    logVerbose: true
    publishContentLink: {
      uri: asrScripts.runbooks[i].url
      version: asrScripts.runbooks[i].version
    }
  }
  dependsOn: [
    automationAccountName_resource
  ]
}]

resource automationAccountName_azureRmProfile_name 'Microsoft.Automation/automationAccounts/modules@2015-10-31' = {
  parent: automationAccountName_resource
  name: '${azureRmProfile.name}'
  location: automationRegion
  properties: {
    contentLink: {
      uri: azureRmProfile.url
    }
  }
}

resource automationAccountName_asrScripts_modules_Name 'Microsoft.Automation/automationAccounts/modules@2015-10-31' = [for i in range(0, length(asrScripts.modules)): {
  name: '${automationAccountName}/${asrScripts.modules[i].Name}'
  location: automationRegion
  properties: {
    contentLink: {
      uri: asrScripts.modules[i].url
    }
  }
  dependsOn: [
    automationAccountName_resource
    automationAccountName_azureRmProfile_name
  ]
}]