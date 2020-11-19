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
param defaultStorageAccountName string {
  metadata: {
    description: 'The short name of the default Azure storage account name. This account needs to be secure transfer enabled.'
  }
}
param defaultStorageAccountKey string {
  metadata: {
    description: 'The key of the default storage account.'
  }
}
param defaultContainerName string {
  metadata: {
    description: 'The name of the existing Azure blob storage container.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
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
          name: '${defaultStorageAccountName}.blob.core.windows.net'
          isDefault: true
          container: defaultContainerName
          key: defaultStorageAccountKey
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

output cluster object = clusterName_resource.properties