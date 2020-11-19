param siteName string {
  metadata: {
    description: 'The name of you Web Site.'
  }
  default: 'WebApp-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param sku string {
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
    description: 'The pricing tier for the hosting plan.'
  }
  default: 'F1'
}
param workerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'The instance size of the hosting plan (small, medium, or large).'
  }
  default: '0'
}
param repoURL string {
  metadata: {
    description: 'The URL for the GitHub repository that contains the project to deploy.'
  }
  default: 'https://github.com/Azure-Samples/app-service-web-html-get-started.git'
}
param branch string {
  metadata: {
    description: 'The branch of the GitHub repository to use.'
  }
  default: 'master'
}

var hostingPlanName = 'hpn-${resourceGroup().name}'

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: hostingPlanName
  location: location
  sku: {
    name: sku
    capacity: workerSize
  }
  properties: {
    name: hostingPlanName
  }
}

resource siteName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: siteName
  location: location
  properties: {
    serverFarmId: hostingPlanName
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource siteName_web 'Microsoft.Web/sites/sourcecontrols@2020-06-01' = {
  name: '${siteName}/web'
  location: location
  properties: {
    repoUrl: repoURL
    branch: branch
    isManualIntegration: true
  }
  dependsOn: [
    siteName_resource
  ]
}