@description('The name of the logic app to create.')
param logicAppName string

@description('A test URI')
param testUri string = 'https://status.azure.com/en-us/status/'

@description('Location for all resources.')
param location string = resourceGroup().location

resource logicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  tags: {
    displayName: 'LogicApp'
  }
  properties: {
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        testUri: {
          type: 'string'
          defaultValue: testUri
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
        http: {
          type: 'Http'
          inputs: {
            method: 'GET'
            uri: '@parameters(\'testUri\')'
          }
        }
      }
    }
  }
}