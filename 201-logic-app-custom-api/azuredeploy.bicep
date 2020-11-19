param tenantId string {
  metadata: {
    description: 'The tenant ID that you Azure subscription is in.'
  }
}
param webAppName string {
  metadata: {
    description: 'The name of the Web app.'
  }
}
param webAppClientId string {
  metadata: {
    description: 'The client ID of the application identity that is used to secure the Web app.'
  }
}
param logicAppName string {
  metadata: {
    description: 'The name of the logic app to create.'
  }
}
param logicAppClientID string {
  metadata: {
    description: 'The client ID of the application identity that the Logic app has to call your Web app.'
  }
}
param logicAppClientSecret string {
  metadata: {
    description: 'The client secret (key or password) of the application identity that the Logic app has to call your Web app.'
  }
  secure: true
}
param svcPlanName string {
  metadata: {
    description: 'The name of the App Service plan to create for hosting the logic app.'
  }
  default: 'Plan'
}
param sku string {
  allowed: [
    'Free'
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier for the App Service plan.'
  }
  default: 'Standard'
}
param svcPlanSize string {
  metadata: {
    description: 'The instance size of the app.'
  }
  default: 'S1'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource svcPlanName_res 'Microsoft.Web/serverfarms@2018-02-01' = {
  name: svcPlanName
  location: location
  sku: {
    name: svcPlanSize
    tier: sku
    capacity: 1
  }
}

resource webAppName_res 'Microsoft.Web/sites@2018-11-01' = {
  kind: 'api'
  name: webAppName
  location: location
  properties: {
    serverFarmId: svcPlanName_res.id
  }
}

resource webAppName_web 'Microsoft.Web/sites/config@2018-11-01' = {
  name: '${webAppName}/web'
  properties: {
    siteAuthEnabled: true
    siteAuthSettings: {
      clientId: webAppClientId
      issuer: 'https://sts.windows.net/${tenantId}/'
    }
  }
}

resource logicAppName_res 'Microsoft.Logic/workflows@2017-07-01' = {
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
            uri: 'https://${webAppName_res.properties.hostNames[0]}'
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
  dependsOn: [
    webAppName_res
  ]
}