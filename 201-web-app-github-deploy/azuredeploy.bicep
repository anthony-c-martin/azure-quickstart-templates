@description('The name of you Web Site.')
param siteName string = 'WebApp-${uniqueString(resourceGroup().id)}'

@description('Location for all resources.')
param location string = resourceGroup().location

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
@description('The pricing tier for the hosting plan.')
param sku string = 'F1'

@allowed([
  '0'
  '1'
  '2'
])
@description('The instance size of the hosting plan (small, medium, or large).')
param workerSize string = '0'

@description('The URL for the GitHub repository that contains the project to deploy.')
param repoURL string = 'https://github.com/Azure-Samples/app-service-web-html-get-started.git'

@description('The branch of the GitHub repository to use.')
param branch string = 'master'

var hostingPlanName_var = 'hpn-${resourceGroup().name}'

resource hostingPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName_var
  location: location
  sku: {
    name: sku
    capacity: workerSize
  }
  properties: {
    name: hostingPlanName_var
  }
}

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    serverFarmId: hostingPlanName_var
  }
  dependsOn: [
    hostingPlanName
  ]
}

resource siteName_web 'Microsoft.Web/sites/sourcecontrols@2020-06-01' = {
  parent: siteName_resource
  name: 'web'
  location: location
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
}