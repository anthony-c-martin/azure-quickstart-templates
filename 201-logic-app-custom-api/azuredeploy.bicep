@description('The tenant ID that you Azure subscription is in.')
param tenantId string

@description('The name of the Web app.')
param webAppName string

@description('The client ID of the application identity that is used to secure the Web app.')
param webAppClientId string

@description('The name of the logic app to create.')
param logicAppName string

@description('The client ID of the application identity that the Logic app has to call your Web app.')
param logicAppClientID string

@description('The client secret (key or password) of the application identity that the Logic app has to call your Web app.')
@secure()
param logicAppClientSecret string

@description('The name of the App Service plan to create for hosting the logic app.')
param svcPlanName string = 'Plan'

@allowed([
  'Free'
  'Basic'
  'Standard'
  'Premium'
])
@description('The pricing tier for the App Service plan.')
param sku string = 'Standard'

@description('The instance size of the app.')
param svcPlanSize string = 'S1'

@description('Location for all resources.')
param location string = resourceGroup().location

resource svcPlanName_resource 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: svcPlanName
  location: location
  sku: {
    name: svcPlanSize
    tier: sku
    capacity: 1
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2018-11-01' = {
  kind: 'api'
  name: webAppName
  location: location
  properties: {
    serverFarmId: svcPlanName_resource.id
  }
}

resource webAppName_web 'Microsoft.Web/sites/config@2018-11-01' = {
  parent: webAppName_resource
  name: 'web'
  properties: {
    siteAuthEnabled: true
    siteAuthSettings: {
      clientId: webAppClientId
      issuer: 'https://sts.windows.net/${tenantId}/'
    }
  }
}

resource logicAppName_resource 'Microsoft.Logic/workflows@2017-07-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        clientSecret: {
          type: 'SecureString'
          defaultValue: '<<Specify the secret for this logic app\'s application identity in the parameters>>'
        }
      }
      triggers: {
        recurrence: {
          type: 'recurrence'
          recurrence: {
            frequency: 'Hour'
            interval: 1
          }
        }
      }
      actions: {
        pingSite: {
          type: 'Http'
          inputs: {
            uri: 'https://${webAppName_resource.properties.hostNames[0]}'
            method: 'Get'
            authentication: {
              type: 'ActiveDirectoryOAuth'
              tenant: tenantId
              audience: webAppClientId
              clientId: logicAppClientID
              secret: '@parameters(\'clientSecret\')'
            }
          }
        }
      }
      outputs: {
        result: {
          type: 'string'
          value: '@actions(\'pingSite\').code'
        }
      }
    }
    parameters: {
      clientSecret: {
        value: logicAppClientSecret
      }
    }
  }
}