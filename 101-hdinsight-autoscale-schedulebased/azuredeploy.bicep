param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to create.'
  }
  default: 'hdi${uniqueString(resourceGroup().id)}'
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

resource defaultStorageAccount_name 'Microsoft.Storage/storageAccounts@2018-11-01' = {
  name: defaultStorageAccount.name
  location: location
  sku: {
    name: defaultStorageAccount.type
  }
  kind: 'Storage'
  properties: {}
}

resource clusterName_res 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    tier: 'Standard'
    clusterDefinition: {
      kind: 'spark'
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
          name: replace(replace(reference(defaultStorageAccount_name.id, '2018-11-01').primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(defaultStorageAccount_name.id, '2018-11-01').keys[0].value
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
          autoscale: {
            recurrence: {
              timeZone: 'Pacific Standard Time'
              schedule: [
                {
                  days: [
                    'Monday'
                    'Tuesday'
                    'Wednesday'
                    'Thursday'
                    'Friday'
                  ]
                  timeAndCapacity: {
                    time: '08:00'
                    minInstanceCount: 6
                    maxInstanceCount: 6
                  }
                }
                {
                  days: [
                    'Monday'
                    'Tuesday'
                    'Wednesday'
                    'Thursday'
                    'Friday'
                  ]
                  timeAndCapacity: {
                    time: '13:00'
                    minInstanceCount: 8
                    maxInstanceCount: 8
                  }
                }
                {
                  days: [
                    'Monday'
                    'Tuesday'
                    'Wednesday'
                    'Thursday'
                    'Friday'
                  ]
                  timeAndCapacity: {
                    time: '18:00'
                    minInstanceCount: 3
                    maxInstanceCount: 3
                  }
                }
                {
                  days: [
                    'Monday'
                    'Tuesday'
                    'Wednesday'
                    'Thursday'
                    'Friday'
                  ]
                  timeAndCapacity: {
                    time: '23:00'
                    minInstanceCount: 2
                    maxInstanceCount: 2
                  }
                }
                {
                  days: [
                    'Saturday'
                    'Sunday'
                  ]
                  timeAndCapacity: {
                    time: '09:00'
                    minInstanceCount: 5
                    maxInstanceCount: 5
                  }
                }
                {
                  days: [
                    'Saturday'
                    'Sunday'
                  ]
                  timeAndCapacity: {
                    time: '18:00'
                    minInstanceCount: 2
                    maxInstanceCount: 2
                  }
                }
              ]
            }
          }
          hardwareProfile: {
            vmSize: 'Standard_D13_v2'
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

output storage object = defaultStorageAccount_name.properties
output cluster object = clusterName_res.properties