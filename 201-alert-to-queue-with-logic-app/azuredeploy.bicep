@description('The name for the logic app.')
param logicAppName string

@description('The Azure Service Bus namespace connection string.')
@secure()
param serviceBusConnectionString string

@description('The name for the Service Bus connection.')
param serviceBusConnectionName string

@description('The name of the queue to add a message to.')
param serviceBusQueueName string

@description('Location for all resources.')
param location string = resourceGroup().location

var singleQuote = '\''

resource serviceBusConnectionName_resource 'Microsoft.Web/connections@2018-07-01-preview' = {
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

resource logicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
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
            connectionId: serviceBusConnectionName_resource.id
          }
        }
      }
    }
  }
}

output WebHookURI string = 'Use listCallbackURL(resourceId(\'Microsoft.Logic/workflows/triggers\', parameters(\'logicAppName\'), \'manual\'), \'2019-05-01\').value to retrieve the URL.  The value contains a secret.'