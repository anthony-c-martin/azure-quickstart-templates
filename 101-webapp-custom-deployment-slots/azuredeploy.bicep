@maxLength(15)
@description('Name of the resource')
param baseResourceName string

@maxLength(19)
@description('Array with the names for the environment slots')
param environments array = [
  'Dev'
  'QA'
  'UAT'
  'Preview'
]

@description('Location for all resources.')
param location string = resourceGroup().location

var standardPlanMaxAdditionalSlots = 4
var webAppPortalName_var = '${baseResourceName}Portal'
var appServicePlanName_var = 'AppServicePlan-${baseResourceName}'

resource appServicePlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  kind: 'app'
  name: appServicePlanName_var
  location: location
  tags: {
    displayName: 'AppServicePlan'
  }
  properties: {}
  sku: {
    name: ((length(environments) <= standardPlanMaxAdditionalSlots) ? 'S1' : 'P1')
  }
}

resource webAppPortalName 'Microsoft.Web/sites@2020-06-01' = {
  kind: 'app'
  name: webAppPortalName_var
  location: location
  tags: {
    displayName: 'WebApp'
  }
  properties: {
    serverFarmId: appServicePlanName.id
  }
}

resource webAppPortalName_environments 'Microsoft.Web/sites/slots@2020-06-01' = [for item in environments: {
  name: '${webAppPortalName_var}/${item}'
  kind: 'app'
  location: location
  tags: {
    displayName: 'WebAppSlots'
  }
  properties: {
    serverFarmId: appServicePlanName.id
  }
  dependsOn: [
    webAppPortalName
  ]
}]