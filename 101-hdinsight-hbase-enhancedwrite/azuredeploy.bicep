param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to create.'
  }
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
  minLength: 10
  metadata: {
    description: 'The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.'
  }
  secure: true
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

resource defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: defaultStorageAccount.name
  location: location
  sku: {
    name: defaultStorageAccount.type
  }
  kind: 'StorageV2'
  properties: {}
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    clusterDefinition: {
      kind: 'hbase'
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
          name: replace(replace(reference(defaultStorageAccount_name.id, '2018-07-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(defaultStorageAccount_name.id, '2018-07-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: 'Standard_D12_v2'
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
          targetInstanceCount: 3
          hardwareProfile: {
            vmSize: 'Standard_D12_v2'
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              password: sshPassword
            }
          }
          dataDisksGroups: [
            {
              disksPerNode: 1
            }
          ]
        }
        {
          name: 'zookeepernode'
          targetInstanceCount: 3
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
  dependsOn: [
    defaultStorageAccount_name
  ]
}

output cluster object = clusterName_resource.properties