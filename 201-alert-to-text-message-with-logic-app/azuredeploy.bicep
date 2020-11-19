param logicAppName string {
  metadata: {
    description: 'The name for the logic app.'
  }
}
param twilioSid string {
  metadata: {
    description: 'Your Twilio SID.'
  }
  secure: true
}
param twilioToken string {
  metadata: {
    description: 'Your Twilio AuthToken.'
  }
  secure: true
}
param twilioConnectionName string {
  metadata: {
    description: 'The name for the Twilio connection.'
  }
  default: 'TwilioConnection'
}
param twilioAccountNumber string {
  metadata: {
    description: 'The Twilio number the message will send from.'
  }
}
param toPhoneNumber string {
  metadata: {
    description: 'The phone number the message will send to.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource twilioConnectionName_res 'Microsoft.Web/connections@2016-06-01' = {
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

resource logicAppName_res 'Microsoft.Logic/workflows@2016-06-01' = {
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
            connectionId: twilioConnectionName_res.id
          }
        }
      }
    }
  }
}

output WebHookURI string = listCallbackURL('${logicAppName_res.id}/triggers/manual', '2016-06-01').value