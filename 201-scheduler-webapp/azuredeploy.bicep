@description('The name of the App Service Plan that will host the Web App.')
param appSvcPlanName string

@description('The instance size of the App Service Plan.')
param svcPlanSize string = 'F1'

@allowed([
  'Free'
  'Shared'
  'Basic'
  'Standard'
  'Premium'
])
@description('The pricing tier of the App Service plan.')
param svcPlanSku string = 'Standard'

@description('The name of the Web App.')
param webAppName string

@description('The name of the job collection.')
param jobCollectionName string

@description('The name of the job.')
param jobName string

@description('sku for job collection.')
param sku object = {
  name: 'Standard'
}

resource appSvcPlanName_resource 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: appSvcPlanName
  location: resourceGroup().location
  sku: {
    name: svcPlanSize
    tier: svcPlanSku
    capacity: 1
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: webAppName
  location: resourceGroup().location
  properties: {
    name: webAppName
    serverFarmId: appSvcPlanName
  }
  dependsOn: [
    appSvcPlanName_resource
  ]
}

resource jobCollectionName_resource 'Microsoft.Scheduler/jobCollections@2016-03-01' = {
  name: jobCollectionName
  location: resourceGroup().location
  properties: {
    sku: sku
  }
}

resource jobCollectionName_jobName 'Microsoft.Scheduler/jobCollections/jobs@2016-03-01' = {
  parent: jobCollectionName_resource
  name: '${jobName}'
  properties: {
    state: 'Enabled'
    action: {
      type: 'Http'
      request: {
        uri: 'http://${webAppName_resource.properties.hostNames[0]}'
        method: 'GET'
        retryPolicy: {
          retryType: 'None'
        }
      }
    }
    recurrence: {
      interval: 1
      frequency: 'Week'
      schedule: {
        weekDays: [
          'Monday'
          'Tuesday'
          'Wednesday'
          'Thursday'
          'Friday'
        ]
        hours: [
          10
          12
        ]
        minutes: [
          0
          30
        ]
      }
    }
  }
}