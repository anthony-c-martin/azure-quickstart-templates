param omsWorkspaceName string {
  metadata: {
    description: 'Input the name of your Log Analytic Workspace, a new workspace will be created if workspace with given name and location doesn\'t exist.'
  }
  default: 'log-analytics-workspace-${uniqueString(resourceGroup().id)}'
}
param omsWorkspaceRegion string {
  allowed: [
    'Australia Southeast'
    'East US'
    'Japan East'
    'Southeast Asia'
    'UK South'
    'West Central US'
    'West Europe'
    'North Europe'
  ]
  metadata: {
    description: 'Specify the region for your Workspace'
  }
  default: 'East US'
}
param azureMonitorPricingModel string {
  allowed: [
    'Pre April 2018'
    'April 2018'
  ]
  metadata: {
    description: 'Select Azure Monitor pricing model your subscription has enabled, NOTE that April 2018 pricing model would be enabled automatically if you onboard Azure Monitor later than April 2, 2018'
  }
  default: 'Pre April 2018'
}
param omsWorkspaceSku string {
  allowed: [
    'free'
    'pernode'
    'standalone'
  ]
  metadata: {
    description: 'Select the SKU for your workspace [This setting will be ignored if you enabled new pricing model April 2018]'
  }
  default: 'free'
}
param cloudFoundryVersion string {
  allowed: [
    '2.0+'
    '1.12 or earlier'
  ]
  metadata: {
    description: 'Cloud Foundry environment has version 2.0+'
  }
  default: '2.0+'
}
param systemMetricsProvider string {
  allowed: [
    'None'
    'Microsoft Azure OMS Agent Only'
    'BOSH Health Metrics Forwarder Only'
    'Both Azure OMS Agent and BOSH Health Metrics Forwarder'
  ]
  metadata: {
    description: 'Select your provider of system metrics'
  }
  default: 'BOSH Health Metrics Forwarder Only'
}
param actionGroupName string {
  metadata: {
    description: 'The name of the action group for alert actions'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/oms-cloudfoundry-solution'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated'
  }
  secure: true
  default: ''
}

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