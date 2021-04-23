@minLength(1)
@description('The email address of the owner of the service')
param apiManagementPublisherEmail string

@minLength(1)
@description('The name of the owner of the service')
param apiManagementPublisherName string

@allowed([
  'Developer'
  'Standard'
  'Premium'
])
@description('The pricing tiers of this API Management service')
param apiManagementSku string = 'Developer'

@description('The instance size of this API Management service.')
param apiManagementSkuCount int = 1

@allowed([
  'Southeast Asia'
  'Australia Southeast'
  'West Europe'
  'East US'
])
@description('Specify the region for your OMS workspace')
param workspaceRegion string = 'East US'

@allowed([
  'free'
  'standalone'
  'pernode'
])
@description('Select the SKU for your workspace')
param omsSku string = 'free'

@description('Location for all resources.')
param location string = resourceGroup().location

var apiManagementServiceName_var = 'apiservice${uniqueString(resourceGroup().id)}'
var omsWorkspaceName_var = 'omsworkspace${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName 'Microsoft.ApiManagement/service@2017-03-01' = {
  name: apiManagementServiceName_var
  location: location
  tags: {}
  sku: {
    name: apiManagementSku
    capacity: apiManagementSkuCount
  }
  properties: {
    publisherEmail: apiManagementPublisherEmail
    publisherName: apiManagementPublisherName
  }
}

resource omsWorkspaceName 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: omsWorkspaceName_var
  location: workspaceRegion
  properties: {
    sku: {
      name: omsSku
    }
  }
}

resource apiManagementServiceName_Microsoft_Insights_service 'Microsoft.ApiManagement/service/providers/diagnosticSettings@2015-07-01' = {
  name: '${apiManagementServiceName_var}/Microsoft.Insights/service'
  properties: {
    workspaceId: omsWorkspaceName.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
  }
  dependsOn: [
    apiManagementServiceName
  ]
}