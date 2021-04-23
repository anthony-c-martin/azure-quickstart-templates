@minLength(1)
@description('Name of the hosting plan to use in Azure.')
param hostingPlanName string

@minLength(1)
@description('Name of the Azure Web app to create.')
param webSiteName string

@allowed([
  'F1'
  'D1'
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P4'
])
@description('Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/')
param skuName string = 'F1'

@minValue(1)
@maxValue(3)
@description('Describes plan\'s instance count')
param skuCapacity int = 1

@description('Location for all resources.')
param location string = resourceGroup().location

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName
  }
}

resource webSiteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    displayName: 'Website'
  }
  properties: {
    name: webSiteName
    serverFarmId: hostingPlanName_resource.id
  }
}

resource webSiteName_web 'Microsoft.Web/sites/config@2020-06-01' = {
  parent: webSiteName_resource
  name: 'web'
  properties: {
    javaVersion: '1.8'
    javaContainer: 'TOMCAT'
    javaContainerVersion: '9.0'
  }
}