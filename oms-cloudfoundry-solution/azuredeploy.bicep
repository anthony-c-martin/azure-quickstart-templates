@description('Input the name of your Log Analytic Workspace, a new workspace will be created if workspace with given name and location doesn\'t exist.')
param omsWorkspaceName string = 'log-analytics-workspace-${uniqueString(resourceGroup().id)}'

@allowed([
  'Australia Southeast'
  'East US'
  'Japan East'
  'Southeast Asia'
  'UK South'
  'West Central US'
  'West Europe'
  'North Europe'
])
@description('Specify the region for your Workspace')
param omsWorkspaceRegion string = 'East US'

@allowed([
  'Pre April 2018'
  'April 2018'
])
@description('Select Azure Monitor pricing model your subscription has enabled, NOTE that April 2018 pricing model would be enabled automatically if you onboard Azure Monitor later than April 2, 2018')
param azureMonitorPricingModel string = 'Pre April 2018'

@allowed([
  'free'
  'pernode'
  'standalone'
])
@description('Select the SKU for your workspace [This setting will be ignored if you enabled new pricing model April 2018]')
param omsWorkspaceSku string = 'free'

@allowed([
  '2.0+'
  '1.12 or earlier'
])
@description('Cloud Foundry environment has version 2.0+')
param cloudFoundryVersion string = '2.0+'

@allowed([
  'None'
  'Microsoft Azure OMS Agent Only'
  'BOSH Health Metrics Forwarder Only'
  'Both Azure OMS Agent and BOSH Health Metrics Forwarder'
])
@description('Select your provider of system metrics')
param systemMetricsProvider string = 'BOSH Health Metrics Forwarder Only'

@description('The name of the action group for alert actions')
param actionGroupName string

@description('The base URI where artifacts required by this template are located')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/oms-cloudfoundry-solution'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

var nestedTemplates = {
  omsWorkspace: uri('${artifactsLocation}/', 'nested/omsWorkspace.json${artifactsLocationSasToken}')
  omsSavedSearches: uri('${artifactsLocation}/', 'nested/omsSavedSearches.json${artifactsLocationSasToken}')
  omsCustomViews: uri('${artifactsLocation}/', 'nested/omsCustomViews.json${artifactsLocationSasToken}')
  omsAlerts: uri('${artifactsLocation}/', 'nested/omsAlerts.json${artifactsLocationSasToken}')
}

module omsWorkspace '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsWorkspace]*/ = {
  name: 'omsWorkspace'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsWorkspaceRegion: omsWorkspaceRegion
    omsWorkspaceSku: omsWorkspaceSku
    azureMonitorPricingModel: azureMonitorPricingModel
  }
}

module omsSavedSearches '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsSavedSearches]*/ = {
  name: 'omsSavedSearches'
  params: {
    omsWorkspaceName: omsWorkspaceName
  }
  dependsOn: [
    omsWorkspace
  ]
}

module omsCustomViews '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsCustomViews]*/ = {
  name: 'omsCustomViews'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsWorkspaceRegion: omsWorkspaceRegion
    systemMetricsProvider: systemMetricsProvider
    cloudFoundryVersion: cloudFoundryVersion
  }
  dependsOn: [
    omsWorkspace
  ]
}

module omsAlerts '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsAlerts]*/ = {
  name: 'omsAlerts'
  params: {
    omsWorkspaceName: omsWorkspaceName
    actionGroupName: actionGroupName
  }
  dependsOn: [
    omsWorkspace
  ]
}

output omsPortal string = 'https://${omsWorkspaceName}.portal.mms.microsoft.com'