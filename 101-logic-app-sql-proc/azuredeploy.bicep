@description('The name of the logic app.')
param logicAppName string

@description('The name of the SQL connection being created.')
param sqlConnectionName string

@description('The URI of the SQL Server')
param sqlServer string

@description('The name of the SQL database.')
param sqlDatabase string

@description('The username for the SQL server.')
param sqlUser string

@description('The password for the SQL server.')
@secure()
param sqlPassword string

@description('The procedure to run.')
param sqlProcedure string

@description('Location for all resources.')
param location string = resourceGroup().location

var singleQuote = '\''

resource sqlConnectionName_resource 'Microsoft.Web/connections@2018-07-01-preview' = {
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
            connectionId: sqlConnectionName_resource.id
            connectionName: sqlConnectionName
            id: '${subscription().id}/providers/Microsoft.Web/locations/${location}/managedApis/sql'
          }
        }
      }
    }
  }
}