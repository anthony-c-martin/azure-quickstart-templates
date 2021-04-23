@allowed([
  'australiaeast'
  'australiasoutheast'
  'eastus'
  'westus2'
  'westeurope'
  'northeurope'
  'canadacentral'
  'canadaeast'
  'japaneast'
  'japanwest'
])
@description('Location for the resources.')
param location string

@description('Name of the logic app to be created.')
param logicAppName string = uniqueString(resourceGroup().id)

@description('Name of the custom provider to be created.')
param customResourceProviderName string = uniqueString(resourceGroup().id)

@description('Name of the custom resource that is being created.')
param customResourceName string = 'myDemoCustomResource'

resource logicAppName_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: logicAppName
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      actions: {
        Switch: {
          cases: {
            CreateResource: {
              actions: {
                CreateCustomResource: {
                  inputs: {
                    body: {
                      properties: '@addProperty(triggerBody().Body[\'properties\'], \'myDynamicProperty\', \'myDynamicValue\')'
                    }
                    statusCode: 200
                  }
                  kind: 'Http'
                  type: 'Response'
                }
              }
              case: 'CREATE'
            }
          }
          default: {
            actions: {
              DefaultHttpResponse: {
                inputs: {
                  statusCode: 200
                }
                kind: 'Http'
                type: 'Response'
              }
            }
          }
          expression: '@triggerBody().operationType'
          type: 'Switch'
        }
      }
      contentVersion: '1.0.0.0'
      outputs: {}
      parameters: {}
      triggers: {
        CustomProviderWebhook: {
          inputs: {
            schema: {
              required: [
                'OperationType'
                'ResourceType'
                'ResourceId'
                'ResourceName'
                'Body'
              ]
              properties: {
                OperationType: {
                  '$id': '#/properties/OperationType'
                  type: 'string'
                  enum: [
                    'CREATE'
                    'DELETE'
                    'GET'
                    'LIST'
                    'TRIGGER'
                  ]
                }
                ResourceType: {
                  '$id': '#/properties/ResourceType'
                  type: 'string'
                }
                ResourceId: {
                  '$id': '#/properties/ResourceId'
                  type: 'string'
                }
                ResourceName: {
                  '$id': '#/properties/ResourceName'
                  type: 'string'
                }
                Body: {
                  '$id': '#/properties/Body'
                  type: 'object'
                }
              }
            }
          }
          kind: 'Http'
          type: 'Request'
        }
      }
    }
  }
}

resource customResourceProviderName_resource 'Microsoft.CustomProviders/resourceProviders@2018-09-01-preview' = {
  name: customResourceProviderName
  location: location
  properties: {
    resourceTypes: [
      {
        name: 'customResources'
        mode: 'Secure'
        routingType: 'Webhook,Cache'
        endpoint: listCallbackURL(resourceId('Microsoft.Logic/workflows/triggers', logicAppName, 'CustomProviderWebhook'), '2019-05-01').value
      }
    ]
  }
  dependsOn: [
    logicAppName_resource
  ]
}

resource customResourceProviderName_customResourceName 'Microsoft.CustomProviders/resourceProviders/customResources@2018-09-01-preview' = {
  parent: customResourceProviderName_resource
  name: '${customResourceName}'
  location: location
  properties: {
    myCustomInputProperty: 'myCustomInputValue'
    myCustomInputObject: {
      Property1: 'Value1'
    }
  }
}

output customResource object = reference(customResourceName, '2018-09-01-preview', 'Full')