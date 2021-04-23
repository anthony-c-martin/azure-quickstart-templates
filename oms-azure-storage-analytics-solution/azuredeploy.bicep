@description('Provide an unique deployment names for each deployment  subsequent deployments')
param deploymentNameSuffix string

@description('Create new or use an existing Log Analytic Workspace')
param omsLogAnalyticsWorkspaceName string

@allowed([
  'westeurope'
  'eastus'
  'southeastasia'
  'australiasoutheast'
  'westcentralus'
  'japaneast'
  'uksouth'
  'centralindia'
  'canadacentral'
])
@description('Specify the Azure Region for your new or existing OMS workspace')
param omsLogAnalyticsRegion string

@allowed([
  'free'
  'standalone'
  'pernode'
  'Per GB'
])
@description('Specify the Azure Region for your OMS Automation Account')
param omsLogAnalyticsSku string = 'free'

@description('Use an existing Automation account or create a new')
param omsAutomationAccountName string

@allowed([
  'westeurope'
  'southeastasia'
  'eastus2'
  'southcentralus'
  'japaneast'
  'southeastasia'
  'southcentralus'
  'northeurope'
  'canadacentral'
  'australiasoutheast'
  'centralindia'
  'japaneast'
  'northcentralus'
  'brazilsouth'
  'uksouth'
  'westcentralus'
])
@description('Specify the Azure Region for your OMS Automation Account')
param omsAutomationRegion string

@allowed([
  'Linked'
  'Unlinked'
])
@description('Specify the workspace type')
param omsWorkspaceType string

@allowed([
  [
    'pernode'
    'OMS'
  ]
  [
    'free'
    'free'
  ]
  [
    'Per GB'
    'OMS'
  ]
])
@description('Choose the SKU for linked workspace  , only valid  if omsWorkspaceType is Linked otherwise ignored.')
param linkedWorkspaceSKU array = [
  'pernode'
  'OMS'
]

@allowed([
  'Enabled'
  'Disabled'
])
@description('This option creates extra collectors to collect and ingest storage audit logs')
param collectAuditLogs string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Enables data collection from all subscriptions where Azure SPN has access')
param collectionFromAllSubscriptions string

@description('The base URI where artifacts required by this template are located')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/oms-azure-storage-analytics-solution'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated')
@secure()
param artifactsLocationSasToken string = ''

var nestedTemplates = {
  omsDeployWithAuditLogs: '${artifactsLocation}/nestedtemplates/omsDeployStorageAnalyticsWithAuditLogs.json${artifactsLocationSasToken}'
  omsDeployStorageAnalyticsOnly: '${artifactsLocation}/nestedtemplates/omsDeployStorageAnalyticsOnly.json${artifactsLocationSasToken}'
}

module omsDeployWithAuditLogs_deploymentNameSuffix '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsDeployWithAuditLogs]*/ = if (collectAuditLogs == 'Enabled') {
  name: 'omsDeployWithAuditLogs-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    omsLogAnalyticsWorkspaceName: omsLogAnalyticsWorkspaceName
    omsLogAnalyticsRegion: omsLogAnalyticsRegion
    omsLogAnalyticsSku: omsLogAnalyticsSku
    omsAutomationAccountName: omsAutomationAccountName
    omsAutomationRegion: omsAutomationRegion
    omsWorkspaceType: omsWorkspaceType
    linkedWorkspaceSKU: linkedWorkspaceSKU
    collectAuditLogs: collectAuditLogs
    collectionFromAllSubscriptions: collectionFromAllSubscriptions
    '_artifactsLocation': artifactsLocation
  }
  dependsOn: []
}

module omsDeployStorageAnalyticsOnly_deploymentNameSuffix '?' /*TODO: replace with correct path to [variables('nestedTemplates').omsDeployStorageAnalyticsOnly]*/ = if (collectAuditLogs == 'Disabled') {
  name: 'omsDeployStorageAnalyticsOnly-${deploymentNameSuffix}'
  params: {
    deploymentNameSuffix: deploymentNameSuffix
    omsLogAnalyticsWorkspaceName: omsLogAnalyticsWorkspaceName
    omsLogAnalyticsRegion: omsLogAnalyticsRegion
    omsLogAnalyticsSku: omsLogAnalyticsSku
    omsAutomationAccountName: omsAutomationAccountName
    omsAutomationRegion: omsAutomationRegion
    omsWorkspaceType: omsWorkspaceType
    linkedWorkspaceSKU: linkedWorkspaceSKU
    collectAuditLogs: collectAuditLogs
    collectionFromAllSubscriptions: collectionFromAllSubscriptions
    '_artifactsLocation': artifactsLocation
  }
  dependsOn: []
}