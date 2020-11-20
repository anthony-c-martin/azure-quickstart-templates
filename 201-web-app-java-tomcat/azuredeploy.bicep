param hostingPlanName string {
  minLength: 1
  metadata: {
    description: 'Name of the hosting plan to use in Azure.'
  }
}
param webSiteName string {
  minLength: 1
  metadata: {
    description: 'Name of the Azure Web app to create.'
  }
}
param skuName string {
  allowed: [
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
  ]
  metadata: {
    description: 'Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/'
  }
  default: 'F1'
}
param skuCapacity int {
  minValue: 1
  maxValue: 3
  metadata: {
    description: 'Describes plan\'s instance count'
  }
  default: 1
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource hostingPlanName_res 'Microsoft.Web/serverfarms@2020-06-01' = {
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

resource webSiteName_res 'Microsoft.Web/sites@2020-06-01' = {
  name: webSiteName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${hostingPlanName}': 'Resource'
    displayName: 'Website'
  }
  properties: {
    name: webSiteName
    serverFarmId: hostingPlanName_res.id
  }
}

resource webSiteName_web 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${webSiteName}/web'
  properties: {
    javaVersion: '1.8'
    javaContainer: 'TOMCAT'
    javaContainerVersion: '9.0'
  }
  dependsOn: [
    webSiteName_res
  ]
}