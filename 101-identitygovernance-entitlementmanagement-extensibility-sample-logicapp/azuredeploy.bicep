@metadata({
  Description: 'Name of the Logicapp'
})
param name string

@metadata({
  Description: 'Deployment location'
})
param location string = resourceGroup().location

@metadata({
  Description: 'Catalog Id from ELM'
})
param catalogId string

var catalogIdExpression = '@{triggerBody()?[\'CatalogId\']}'

resource name_resource 'Microsoft.Logic/workflows@2019-05-01' = {
  name: name
  location: location
  properties: {
    state: 'Enabled'
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {}
      triggers: {
        manual: {
          type: 'Request'
          kind: 'Http'
          inputs: {
            schema: {
              properties: {
                AccessPackageId: {
                  type: 'string'
                }
                AccessPackageName: {
                  type: 'string'
                }
                AccessPackagePolicyName: {
                  type: 'string'
                }
                CatalogId: {
                  type: 'string'
                }
                CatalogName: {
                  type: 'string'
                }
                ConnectedOrganizationName: {
                  type: 'string'
                }
                Event: {
                  type: 'string'
                }
                GrantRequestCreatedDateTime: {
                  type: 'string'
                }
                Roles: {
                  items: {
                    properties: {
                      Id: {
                        type: 'string'
                      }
                      Name: {
                        type: 'string'
                      }
                      ResourceId: {
                        type: 'string'
                      }
                      ResourceName: {
                        type: 'string'
                      }
                    }
                    required: [
                      'Id'
                      'Name'
                      'ResourceId'
                      'ResourceName'
                    ]
                    type: 'object'
                  }
                  type: 'array'
                }
                UserEmail: {
                  type: 'string'
                }
                UserId: {
                  type: 'string'
                }
                UserName: {
                  type: 'string'
                }
              }
              type: 'object'
            }
          }
          operationOptions: 'IncludeAuthorizationHeadersInOutputs'
        }
      }
      actions: {
        Condition: {
          actions: {
            Condition_2: {
              actions: {
                Response_2: {
                  inputs: {
                    statusCode: 200
                  }
                  kind: 'Http'
                  type: 'Response'
                }
              }
              expression: {
                and: [
                  {
                    equals: [
                      '@triggerBody()?[\'Event\']'
                      'CustomActionConnectionTest'
                    ]
                  }
                ]
              }
              type: 'If'
            }
          }
          else: {
            actions: {
              Response: {
                inputs: {
                  body: 'CatalogId mismatch, expected CatalogId:  ${catalogId} Provided CatalogId: ${catalogIdExpression}'
                  statusCode: 400
                }
                kind: 'Http'
                type: 'Response'
              }
            }
          }
          expression: {
            and: [
              {
                equals: [
                  catalogIdExpression
                  catalogId
                ]
              }
            ]
          }
          type: 'If'
        }
      }
      outputs: {}
    }
    parameters: {}
    accessControl: {
      triggers: {
        openAuthenticationPolicies: {
          policies: {
            ELMAuthPolicy: {
              type: 'AAD'
              claims: [
                {
                  name: 'iss'
                  value: 'https://sts.windows.net/${subscription().tenantId}/'
                }
                {
                  name: 'aud'
                  value: environment().authentication.audiences[0]
                }
                {
                  name: 'appid'
                  value: '810dcf14-1858-4bf2-8134-4c369fa3235b'
                }
              ]
            }
          }
        }
      }
    }
  }
}