param logicAppName string {
  metadata: {
    description: 'The name of the logic app.'
  }
}
param sqlConnectionName string {
  metadata: {
    description: 'The name of the SQL connection being created.'
  }
}
param sqlServer string {
  metadata: {
    description: 'The URI of the SQL Server'
  }
}
param sqlDatabase string {
  metadata: {
    description: 'The name of the SQL database.'
  }
}
param sqlUser string {
  metadata: {
    description: 'The username for the SQL server.'
  }
}
param sqlPassword string {
  metadata: {
    description: 'The password for the SQL server.'
  }
  secure: true
}
param sqlProcedure string {
  metadata: {
    description: 'The procedure to run.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var singleQuote = '\''

resource sqlConnectionName_res 'Microsoft.Web/connections@2018-07-01-preview' = {
  location: location
  name: sqlConnectionName
  properties: {
    api: {
      id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
    }
    displayName: 'sql_connection'
    parameterValues: {
      server: sqlServer
      database: sqlDatabase
      authType: 'windows'
      username: sqlUser
      password: sqlPassword
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
        Recurrence: {
          recurrence: {
            frequency: 'Hour'
            interval: 1
          }
          type: 'Recurrence'
        }
      }
      actions: {
        Execute_stored_procedure: {
          runAfter: {}
          type: 'ApiConnection'
          inputs: {
            body: {}
            host: {
              api: {
                runtimeUrl: 'https://logic-apis-${location}.azure-apim.net/apim/sql'
              }
              connection: {
                name: '@parameters(\'$connections\')[\'sql\'][\'connectionId\']'
              }
            }
            method: 'post'
            path: '/datasets/default/procedures/@{encodeURIComponent(encodeURIComponent(${singleQuote}${sqlProcedure}${singleQuote}))}'
          }
        }
      }
      outputs: {}
    }
    parameters: {
      '$connections': {
        value: {
          sql: {
            connectionId: sqlConnectionName_res.id
            connectionName: sqlConnectionName
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
          }
        }
      }
    }
  }
}