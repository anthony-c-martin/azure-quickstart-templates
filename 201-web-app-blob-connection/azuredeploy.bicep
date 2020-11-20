param webAppSvcPlanName string {
  minLength: 1
  metadata: {
    description: 'Name of AppSvc Plan.'
  }
  default: 'AppSvcPlan'
}
param webAppSvcPlanSku string {
  allowed: [
    'Free'
    'Shared'
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'App Svc Plan SKU.'
  }
  default: 'Basic'
}
param webAppSvcPlanWorkerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'Size of AppSvc Worker.'
  }
  default: '0'
}
param webAppName string {
  minLength: 1
  metadata: {
    description: 'Name of web site.'
  }
}
param storageAccountName string {
  metadata: {
    description: 'Storage Account to access blob storage.'
  }
}
param deployPackageUri string {
  minLength: 1
  metadata: {
    description: 'WebDeploy package location.'
  }
}
param sasToken string {
  metadata: {
    description: 'Sas token to be appended to DeployPackageURI.'
  }
  default: ' '
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var packageURI = concat(deployPackageUri, sasToken)
var storageAccountId = '${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageAccountName}'

resource WebAppSvcPlanName_res 'Microsoft.Web/serverfarms@2014-06-01' = {
  name: webAppSvcPlanName
  location: location
  tags: {
    displayName: 'AppSvcPlan'
  }
  properties: {
    name: webAppSvcPlanName
    sku: webAppSvcPlanSku
    workerSize: webAppSvcPlanWorkerSize
    numberOfWorkers: 1
  }
  dependsOn: []
}

resource WebAppName_res 'Microsoft.Web/sites@2015-08-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${webAppSvcPlanName}': 'Resource'
    displayName: 'WebApp'
  }
  properties: {
    name: webAppName
    serverFarmId: WebAppSvcPlanName_res.id
  }
}

resource WebAppName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${webAppName}/web'
  tags: {
    displayName: 'WebAppConfig'
  }
  properties: {
    phpVersion: '5.6'
    netFrameworkVersion: 'v4.6'
    use32BitWorkerProcess: false
    webSocketsEnabled: true
    alwaysOn: false
    remoteDebuggingEnabled: true
    remoteDebuggingVersion: 'VS2015'
  }
  dependsOn: [
    WebAppName_res
  ]
}

resource WebAppName_MSDeploy 'Microsoft.Web/sites/extensions@2015-08-01' = {
  name: '${webAppName}/MSDeploy'
  location: location
  tags: {
    displayName: 'WebAppMSDeploy'
  }
  properties: {
    packageUri: packageURI
  }
  dependsOn: [
    WebAppName_res
  ]
}

resource WebAppName_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  name: '${webAppName}/connectionstrings'
  tags: {
    displayName: 'WebAppConnectionStrings'
  }
  properties: {
    BlobConnection: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2015-05-01-preview').key1}'
      type: 'Custom'
    }
  }
  dependsOn: [
    WebAppName_res
  ]
}