param logicAppName string {
  metadata: {
    description: 'The name for the logic app.'
  }
}
param sendgridApiKey string {
  metadata: {
    description: 'The SendGrid API key from the SendGrid service.'
  }
  secure: true
}
param sendgridName string {
  metadata: {
    description: 'The name for the SendGrid connection.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource sendgridName_resource 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: sendgridName
  properties: {
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sendgrid'
    }
    displayName: 'sendgrid'
    parameterValues: {
      apiKey: sendgridApiKey
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
          kind: 'http'
          inputs: {
            schema: {
              '$schema': 'http://json-schema.org/draft-04/schema#'
              properties: {
                emailbody: {
                  type: 'string'
                }
                from: {
                  type: 'string'
                }
                subject: {
                  type: 'string'
                }
                to: {
                  type: 'string'
                }
              }
              required: [
                'from'
                'to'
                'subject'
                'emailbody'
              ]
              type: 'object'
            }
          }
        }
      }
      actions: {
        Send_email: {
          type: 'ApiConnection'
          inputs: {
            body: {
              body: '@{triggerBody()[\'emailbody\']}'
              from: '@{triggerBody()[\'from\']}'
              ishtml: false
              subject: '@{triggerBody()[\'subject\']}'
              to: '@{triggerBody()[\'to\']}'
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'sendgrid\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/api/mail.send.json'
          }
          runAfter: {}
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          sendgrid: {
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sendgrid'
            connectionId: sendgridName_resource.id
          }
        }
      }
    }
  }
  dependsOn: [
    sendgridName_resource
  ]
}

output triggerURI string = listCallbackURL('${logicAppName_resource.id}/triggers/manual', '2016-06-01').value