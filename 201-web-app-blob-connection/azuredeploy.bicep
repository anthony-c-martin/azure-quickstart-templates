@minLength(1)
@description('Name of AppSvc Plan.')
param webAppSvcPlanName string = 'AppSvcPlan'

@allowed([
  'Free'
  'Shared'
  'Basic'
  'Standard'
])
@description('App Svc Plan SKU.')
param webAppSvcPlanSku string = 'Basic'

@allowed([
  '0'
  '1'
  '2'
])
@description('Size of AppSvc Worker.')
param webAppSvcPlanWorkerSize string = '0'

@minLength(1)
@description('Name of web site.')
param webAppName string

@description('Storage Account to access blob storage.')
param storageAccountName string

@minLength(1)
@description('WebDeploy package location.')
param deployPackageUri string

@description('Sas token to be appended to DeployPackageURI.')
param sasToken string = ' '

@description('Location for all resources.')
param location string = resourceGroup().location

var packageURI = concat(deployPackageUri, sasToken)
var storageAccountId = '${resourceGroup().id}/providers/Microsoft.Storage/storageAccounts/${storageAccountName}'

resource WebAppSvcPlanName_resource 'Microsoft.Web/serverfarms@2014-06-01' = {
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

resource WebAppName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: webAppName
  location: location
  tags: {
    'hidden-related:${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${webAppSvcPlanName}': 'Resource'
    displayName: 'WebApp'
  }
  properties: {
    name: webAppName
    serverFarmId: WebAppSvcPlanName_resource.id
  }
}

resource WebAppName_web 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: WebAppName_resource
  name: 'web'
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
}

resource WebAppName_MSDeploy 'Microsoft.Web/sites/extensions@2015-08-01' = {
  parent: WebAppName_resource
  name: 'MSDeploy'
  location: location
  tags: {
    displayName: 'WebAppMSDeploy'
  }
  properties: {
    packageUri: packageURI
  }
}

resource WebAppName_connectionstrings 'Microsoft.Web/sites/config@2015-08-01' = {
  parent: WebAppName_resource
  name: 'connectionstrings'
  tags: {
    displayName: 'WebAppConnectionStrings'
  }
  properties: {
    BlobConnection: {
      value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listKeys(storageAccountId, '2015-05-01-preview').key1}'
      type: 'Custom'
    }
  }
}