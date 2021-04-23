param location string
param logicAppName string
param customResourceProviderName string

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
            CreateAssociation: {
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
        name: 'associations'
        mode: 'Secure'
        routingType: 'Webhook,Cache,Extension'
        endpoint: listCallbackURL(resourceId('Microsoft.Logic/workflows/triggers', logicAppName, 'CustomProviderWebhook'), '2019-05-01').value
      }
    ]
  }
}

output customProviderResourceId string = customResourceProviderName_resource.id