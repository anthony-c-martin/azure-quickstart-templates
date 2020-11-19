param logicAppName string {
  metadata: {
    description: 'The name for the logic app.'
  }
}
param serviceBusConnectionString string {
  metadata: {
    description: 'The Azure Service Bus namespace connection string.'
  }
  secure: true
}
param serviceBusConnectionName string {
  metadata: {
    description: 'The name for the Service Bus connection.'
  }
}
param serviceBusQueueName string {
  metadata: {
    description: 'The name of the queue to add a message to.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var singleQuote = '\''

resource serviceBusConnectionName_res 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: serviceBusConnectionName
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
    }
    displayName: 'servicebus'
    parameterValues: {
      connectionString: serviceBusConnectionString
    }
  }
}

resource logicAppName_res 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        '$connections': {
          defaultValue: {}
          type: 'Object'
        }
      }
      triggers: {
        manual: {
          type: 'request'
          kind: 'Http'
        }
      }
      actions: {
        Send_message: {
          type: 'ApiConnection'
          inputs: {
            body: {
              ContentData: '@{encodeBase64(triggerBody())}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'servicebus\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/@{encodeURIComponent(${singleQuote}${serviceBusQueueName}${singleQuote})}/messages'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          servicebus: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'servicebus')
            connectionId: serviceBusConnectionName_res.id
          }
        }
      }
    }
  }
}

output WebHookURI string = 'Use listCallbackURL(resourceId(\'Microsoft.Logic/workflows/triggers\', parameters(\'logicAppName\'), \'manual\'), \'2019-05-01\').value to retrieve the URL.  The value contains a secret.'