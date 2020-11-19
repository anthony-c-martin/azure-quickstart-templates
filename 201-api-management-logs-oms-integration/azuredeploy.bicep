param apiManagementPublisherEmail string {
  minLength: 1
  metadata: {
    description: 'The email address of the owner of the service'
  }
}
param apiManagementPublisherName string {
  minLength: 1
  metadata: {
    description: 'The name of the owner of the service'
  }
}
param apiManagementSku string {
  allowed: [
    'Developer'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tiers of this API Management service'
  }
  default: 'Developer'
}
param apiManagementSkuCount int {
  metadata: {
    description: 'The instance size of this API Management service.'
  }
  default: 1
}
param workspaceRegion string {
  allowed: [
    'Southeast Asia'
    'Australia Southeast'
    'West Europe'
    'East US'
  ]
  metadata: {
    description: 'Specify the region for your OMS workspace'
  }
  default: 'East US'
}
param omsSku string {
  allowed: [
    'free'
    'standalone'
    'pernode'
  ]
  metadata: {
    description: 'Select the SKU for your workspace'
  }
  default: 'free'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var apiManagementServiceName = 'apiservice${uniqueString(resourceGroup().id)}'
var omsWorkspaceName = 'omsworkspace${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName_resource 'Microsoft.ApiManagement/service@2017-03-01' = {
  name: apiManagementServiceName
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

resource omsWorkspaceName_resource 'Microsoft.OperationalInsights/workspaces@2015-11-01-preview' = {
  name: omsWorkspaceName
  location: workspaceRegion
  properties: {
    sku: {
      name: omsSku
    }
  }
}

resource apiManagementServiceName_Microsoft_Insights_service 'Microsoft.ApiManagement/service/providers/diagnosticSettings@2015-07-01' = {
  name: '${apiManagementServiceName}/Microsoft.Insights/service'
  properties: {
    workspaceId: omsWorkspaceName_resource.id
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
      }
    ]
  }
  dependsOn: [
    apiManagementServiceName_resource
    omsWorkspaceName_resource
  ]
}