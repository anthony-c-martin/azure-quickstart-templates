param appSvcPlanName string {
  metadata: {
    description: 'The name of the App Service Plan that will host the Web App.'
  }
}
param svcPlanSize string {
  metadata: {
    description: 'The instance size of the App Service Plan.'
  }
  default: 'F1'
}
param svcPlanSku string {
  allowed: [
    'Free'
    'Shared'
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier of the App Service plan.'
  }
  default: 'Standard'
}
param webAppName string {
  metadata: {
    description: 'The name of the Web App.'
  }
}
param jobCollectionName string {
  metadata: {
    description: 'The name of the job collection.'
  }
}
param jobName string {
  metadata: {
    description: 'The name of the job.'
  }
}
param sku object {
  metadata: {
    description: 'sku for job collection.'
  }
  default: {
    name: 'Standard'
  }
}

resource appSvcPlanName_res 'Microsoft.Web/serverfarms@2015-08-01' = {
  name: appSvcPlanName
  location: resourceGroup().location
  sku: {
    name: svcPlanSize
    tier: svcPlanSku
    capacity: 1
  }
}

resource webAppName_res 'Microsoft.Web/sites@2015-08-01' = {
  name: webAppName
  location: resourceGroup().location
  properties: {
    name: webAppName
    serverFarmId: appSvcPlanName
  }
  dependsOn: [
    appSvcPlanName_res
  ]
}

resource jobCollectionName_res 'Microsoft.Scheduler/jobCollections@2016-03-01' = {
  name: jobCollectionName
  location: resourceGroup().location
  properties: {
    sku: sku
  }
}

resource jobCollectionName_jobName 'Microsoft.Scheduler/jobCollections/jobs@2016-03-01' = {
  name: '${jobCollectionName}/${jobName}'
  properties: {
    state: 'Enabled'
    action: {
      type: 'Http'
      request: {
        uri: 'http://${webAppName_res.properties.hostNames[0]}'
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
  dependsOn: [
    jobCollectionName_res
  ]
}