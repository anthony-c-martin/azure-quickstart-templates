param variables_sqldbname ? /* TODO: fill in correct type */

@description('Location for all resources.')
param location string

resource variables_sqldbname_resource 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  location: location
  name: variables_sqldbname
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: '268435456000'
    zoneRedundant: false
    readScale: 'Disabled'
    readReplicaCount: 0
  }
  sku: {
    name: 'S2'
    tier: 'Standard'
  }
}