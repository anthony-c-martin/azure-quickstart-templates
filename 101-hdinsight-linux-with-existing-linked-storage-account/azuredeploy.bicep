@description('The name of the HDInsight cluster to create.')
param clusterName string

@allowed([
  'hadoop'
  'intractivehive'
  'hbase'
  'storm'
  'spark'
])
@description('The type of the HDInsight cluster to create.')
param clusterType string = 'hadoop'

@allowed([
  '3.4'
  '3.5'
  '3.6'
])
@description('The type of the HDInsight cluster to create.')
param clusterVersion string = '3.6'

@description('These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.')
param clusterLoginUserName string

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param clusterLoginPassword string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param sshPassword string

@description('The short name of the default Azure storage account name. This account needs to be secure transfer enabled.')
param linkedStorageAccountName string

@description('The key of the default storage account.')
param linkedStorageAccountKey string

@description('Location for all resources.')
param location string = resourceGroup().location

var defaultStorageAccount = {
  name: uniqueString(resourceGroup().id)
  type: 'Standard_LRS'
}

resource defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: defaultStorageAccount.name
  location: location
  sku: {
    name: defaultStorageAccount.type
  }
  kind: 'Storage'
  properties: {}
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2015-03-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: clusterVersion
    osType: 'Linux'
    tier: 'Standard'
    clusterDefinition: {
      kind: clusterType
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
          name: replace(replace(concat(reference('Microsoft.Storage/storageAccounts/${defaultStorageAccount.name}', '2016-01-01').primaryEndpoints.blob), 'https:', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(defaultStorageAccount_name.id, '2016-01-01').keys[0].value
        }
        {
          name: '${linkedStorageAccountName}.blob.core.windows.net'
          isDefault: false
          container: 'blank'
          key: linkedStorageAccountKey
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
  dependsOn: []
}

output storage object = defaultStorageAccount_name.properties
output cluster object = clusterName_resource.properties