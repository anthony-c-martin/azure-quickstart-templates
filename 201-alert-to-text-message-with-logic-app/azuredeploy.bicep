@description('The name for the logic app.')
param logicAppName string

@description('Your Twilio SID.')
@secure()
param twilioSid string

@description('Your Twilio AuthToken.')
@secure()
param twilioToken string

@description('The name for the Twilio connection.')
param twilioConnectionName string = 'TwilioConnection'

@description('The Twilio number the message will send from.')
param twilioAccountNumber string

@description('The phone number the message will send to.')
param toPhoneNumber string

@description('Location for all resources.')
param location string = resourceGroup().location

resource twilioConnectionName_resource 'Microsoft.Web/connections@2016-06-01' = {
  location: location
  name: twilioConnectionName
  properties: {
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/twilio'
    }
    displayName: 'twilio'
    parameterValues: {
      sid: twilioSid
      token: twilioToken
    }
  }
}

resource logicAppName_resource 'Microsoft.Logic/workflows@2016-06-01' = {
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
          runAfter: {}
        }
        Send_Message: {
          type: 'ApiConnection'
          inputs: {
            body: {
              body: 'Azure Alert - \'@{triggerBody()[\'context\'][\'name\']}\' @{triggerBody()[\'status\']} on \'@{triggerBody()[\'context\'][\'resourceName\']}\'. Details: @{body(\'Http\')[\'id\']}'
              from: twilioAccountNumber
              to: toPhoneNumber
            }
            host: {
              connection: {
                name: '@parameters(\'$connections\')[\'twilio\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/Messages.json'
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
          twilio: {
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/twilio'
            connectionId: twilioConnectionName_resource.id
          }
        }
      }
    }
  }
}

output WebHookURI string = listCallbackURL('${logicAppName_resource.id}/triggers/manual', '2016-06-01').value