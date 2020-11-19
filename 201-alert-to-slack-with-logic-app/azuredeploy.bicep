param logicAppName string {
  metadata: {
    description: 'The name for the logic app.'
  }
}
param slackConnectionName string {
  metadata: {
    description: 'The name for the Slack connection.'
  }
  default: 'SlackConnection'
}
param slackChannel string {
  metadata: {
    description: 'The Slack channel to post to.'
  }
  default: '#general'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource slackConnectionName_res 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: slackConnectionName
  properties: {
    api: {
      id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'slack')
    }
    displayName: 'slack'
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
          inputs: {
            schema: {
              '$schema': 'http://json-schema.org/draft-04/schema#'
              properties: {
                context: {
                  properties: {
                    name: {
                      type: 'string'
                    }
                    portalLink: {
                      type: 'string'
                    }
                    resourceName: {
                      type: 'string'
                    }
                  }
                  required: [
                    'name'
                    'portalLink'
                    'resourceName'
                  ]
                  type: 'object'
                }
                status: {
                  type: 'string'
                }
              }
              required: [
                'status'
                'context'
              ]
              type: 'object'
            }
          }
        }
      }
      actions: {
        Http: {
          type: 'Http'
          inputs: {
            body: {
              longUrl: '@{triggerBody()[\'context\'][\'portalLink\']}'
            }
            headers: {
              'Content-Type': 'application/json'
            }
            method: 'POST'
            uri: 'https://www.googleapis.com/urlshortener/v1/url?key=AIzaSyBkT1BRbA-uULHz8HMUAi0ywJtpNLXHShI'
          }
        }
        Post_Message: {
          type: 'ApiConnection'
          inputs: {
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'slack\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/chat.postMessage'
            queries: {
              channel: slackChannel
              text: 'Azure Alert - \'@{triggerBody()[\'context\'][\'name\']}\' @{triggerBody()[\'status\']} on \'@{triggerBody()[\'context\'][\'resourceName\']}\'.  Details: @{body(\'Http\')[\'id\']}'
            }
          }
          runAfter: {
            Http: [
              'Succeeded'
            ]
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          slack: {
            id: subscriptionResourceId('Microsoft.Web/locations/managedApis', location, 'slack')
            connectionId: slackConnectionName_res.id
          }
        }
      }
    }
  }
}

output WebHookURI string = 'Use \'listCallbackURL(resourceId(\'Microsoft.Logic/workflows/triggers\', parameters(\'logicAppName\'), \'manual\'), \'2019-05-01\').value\' to retrieve the callback URL, the value contains a secret and is not recommended in an output.'