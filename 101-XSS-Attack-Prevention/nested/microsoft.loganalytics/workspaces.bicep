param omsWorkspaceName string = 'oms-workspace${uniqueString(resourceGroup().id)}'
param omsSolutionsName array
param tags object

@allowed([
  'Free'
  'Standalone'
  'PerNode'
])
@description('Service Tier: Free, Standalone, or PerNode')
param sku string = 'Free'

@minValue(7)
@maxValue(730)
@description('Number of days of retention. Free plans can only have 7 days, Standalone and OMS plans include 30 days for free')
param dataRetention int = 90

@allowed([
  'East US'
  'West Europe'
  'Southeast Asia'
  'Australia Southeast'
])
param location string = 'East US'

resource omsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2017-04-26-preview' = {
  name: omsWorkspaceName
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retention: dataRetention
  }
}

resource omsSolutionsName_omsWorkspaceName 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = [for item in omsSolutionsName: {
  name: '${item}(${omsWorkspaceName})'
  location: location
  plan: {
    name: '${item}(${omsWorkspaceName})'
    product: 'OMSGallery/${item}'
    promotionCode: ''
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: omsWorkspaceName_resource.id
  }
  dependsOn: [
    omsWorkspaceName
  ]
}]

resource omsWorkspaceName_subscriptionId 'Microsoft.OperationalInsights/workspaces/datasources@2015-11-01-preview' = {
  parent: omsWorkspaceName_resource
  kind: 'AzureActivityLog'
  name: '${subscription().subscriptionId}'
  location: location
  properties: {
    linkedResourceId: '${subscription().id}/providers/microsoft.insights/eventTypes/management'
  }
  dependsOn: [
    omsWorkspaceName
  ]
}

output workspaceName string = omsWorkspaceName
output workspaceId string = omsWorkspaceName_resource.id
output workspaceKey string = listKeys(omsWorkspaceName_resource.id, '2017-04-26-preview').primarySharedKey