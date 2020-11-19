param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to create.'
  }
}
param clusterType string {
  allowed: [
    'hadoop'
    'intractivehive'
    'hbase'
    'storm'
    'spark'
  ]
  metadata: {
    description: 'The type of the HDInsight cluster to create.'
  }
  default: 'hadoop'
}
param clusterVersion string {
  allowed: [
    '3.4'
    '3.5'
    '3.6'
  ]
  metadata: {
    description: 'The type of the HDInsight cluster to create.'
  }
  default: '3.6'
}
param clusterLoginUserName string {
  metadata: {
    description: 'These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.'
  }
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
}
param sshPassword string {
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
}
param linkedStorageAccountName string {
  metadata: {
    description: 'The short name of the default Azure storage account name. This account needs to be secure transfer enabled.'
  }
}
param linkedStorageAccountKey string {
  metadata: {
    description: 'The key of the default storage account.'
  }
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

resource defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  name: defaultStorageAccount.name
  location: location
  sku: {
    name: defaultStorageAccount.type
  }
  kind: 'Storage'
  properties: {}
}

resource clusterName_res 'Microsoft.HDInsight/clusters@2015-03-01-preview' = {
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
output cluster object = clusterName_res.properties