param sqlServerPrimaryName string {
  metadata: {
    description: 'The name of the primary SQL Server.'
  }
}
param sqlServerPrimaryAdminUsername string {
  metadata: {
    description: 'The administrator username of the primary SQL Server.'
  }
}
param sqlServerPrimaryAdminPassword string {
  metadata: {
    description: 'The administrator password of the primary SQL Server.'
  }
  secure: true
}
param sqlServerSecondaryName string {
  metadata: {
    description: 'The name of the secondary SQL Server.'
  }
}
param sqlServerSecondaryRegion string {
  metadata: {
    description: 'The location of the secondary SQL Server.'
  }
}
param sqlServerSecondaryAdminUsername string {
  metadata: {
    description: 'The administrator username of the secondary SQL Server.'
  }
}
param sqlServerSecondaryAdminPassword string {
  metadata: {
    description: 'The administrator password of the secondary SQL Server.'
  }
  secure: true
}
param sqlFailoverGroupName string {
  metadata: {
    description: 'The name of the failover group.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var sqlDatabaseName = 'MyData'
var sqlDatabaseServiceObjective = 'Basic'
var sqlDatabaseEdition = 'Basic'

resource sqlServerPrimaryName_res 'Microsoft.Sql/servers@2020-02-02-preview' = {
  kind: 'v12.0'
  name: sqlServerPrimaryName
  location: location
  properties: {
    administratorLogin: sqlServerPrimaryAdminUsername
    administratorLoginPassword: sqlServerPrimaryAdminPassword
    version: '12.0'
  }
}

resource sqlServerPrimaryName_sqlFailoverGroupName 'Microsoft.Sql/servers/failoverGroups@2020-02-02-preview' = {
  name: '${sqlServerPrimaryName}/${sqlFailoverGroupName}'
  properties: {
    serverName: sqlServerPrimaryName
    partnerServers: [
      {
        id: sqlServerSecondaryName_res.id
      }
    ]
    readWriteEndpoint: {
      failoverPolicy: 'Automatic'
      failoverWithDataLossGracePeriodMinutes: 60
    }
    readOnlyEndpoint: {
      failoverPolicy: 'Disabled'
    }
    databases: [
      sqlServerPrimaryName_sqlDatabaseName.id
    ]
  }
  dependsOn: [
    sqlServerPrimaryName_res
  ]
}

resource sqlServerPrimaryName_sqlDatabaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: '${sqlServerPrimaryName}/${sqlDatabaseName}'
  location: location
  properties: {
    edition: sqlDatabaseEdition
    requestedServiceObjectiveName: sqlDatabaseServiceObjective
  }
  dependsOn: [
    sqlServerPrimaryName_res
  ]
}

resource sqlServerSecondaryName_res 'Microsoft.Sql/servers@2020-02-02-preview' = {
  kind: 'v12.0'
  name: sqlServerSecondaryName
  location: sqlServerSecondaryRegion
  properties: {
    administratorLogin: sqlServerSecondaryAdminUsername
    administratorLoginPassword: sqlServerSecondaryAdminPassword
    version: '12.0'
  }
}