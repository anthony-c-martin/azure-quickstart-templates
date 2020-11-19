param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to be created. The cluster name must be globally unique.'
  }
}
param clusterLoginUserName string {
  metadata: {
    description: 'These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.'
  }
  default: 'admin'
}
param clusterLoginPassword string {
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
}
param sshUserName string {
  metadata: {
    description: 'These credentials can be used to remotely access the cluster.'
  }
  default: 'sshuser'
}
param sshPassword string {
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
}
param sqlAdminLogin string {
  metadata: {
    description: 'These credentials can be used to access the Azure SQL database.'
  }
  default: 'sqluser'
}
param sqlAdminPassword string {
  metadata: {
    description: 'The password can be used to access the SQL database.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-hdinsight-linux-with-sql-database/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param bacpacFileName string {
  metadata: {
    description: 'The backpac for configure the database and tables for the Use Sqoop in HDInsight tutorial.'
  }
  default: 'SqoopTutorial-2016-2-23-11-2.bacpac'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var defaultStorageAccount = {
  name: uniqueString(resourceGroup().id)
  type: 'Standard_LRS'
}
var sqlDatabase = {
  serverName: '${clusterName}dbserver'
  databaseName: '${clusterName}db'
}

resource defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: defaultStorageAccount.name
  location: location
  sku: {
    name: defaultStorageAccount.type
  }
  kind: 'StorageV2'
  properties: {}
}

resource clusterName_res 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    clusterDefinition: {
      kind: 'hadoop'
      configurations: {
        gateway: {
          'restAuthCredential.isEnabled': true
          'restAuthCredential.username': clusterLoginUserName
          'restAuthCredential.password': clusterLoginPassword
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: replace(replace(reference(defaultStorageAccount_name.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(defaultStorageAccount_name.id, '2019-06-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D3_v2'
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
        }
        {
          name: 'workernode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D3_v2'
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
        }
      ]
    }
  }
}

resource sqlDatabase_serverName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlDatabase.serverName
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    version: '12.0'
  }
}

resource sqlDatabase_serverName_sqlDatabase_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: '${sqlDatabase.serverName}/${sqlDatabase.databaseName}'
  location: location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: 'Basic'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: 'Basic'
  }
}

resource sqlDatabase_serverName_sqlDatabase_databaseName_Import 'Microsoft.Sql/servers/databases/extensions@2014-04-01' = {
  name: '${sqlDatabase.serverName}/${sqlDatabase.databaseName}/Import'
  properties: {
    operationMode: 'Import'
    storageKey: artifactsLocationSasToken
    storageKeyType: 'SharedAccessKey'
    administratorLogin: sqlAdminLogin
    administratorLoginPassword: sqlAdminPassword
    storageUri: '${artifactsLocation}Bacpac/${bacpacFileName}'
  }
}

resource sqlDatabase_serverName_AllowAllAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  name: '${sqlDatabase.serverName}/AllowAllAzureIps'
  location: location
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

output storage object = defaultStorageAccount_name.properties
output cluster object = clusterName_res.properties
output sqlSvrFqdn string = sqlDatabase_serverName.properties.fullyQualifiedDomainName