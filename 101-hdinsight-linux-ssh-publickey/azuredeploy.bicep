@allowed([
  'hadoop'
  'hbase'
  'storm'
  'spark'
])
@description('The type of the HDInsight cluster to create.')
param clusterType string

@description('The name of the HDInsight cluster to create.')
param clusterName string

@description('These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.')
param clusterLoginUserName string

@minLength(10)
@description('The password must be at least 10 characters in length and must contain at least one digit, one upper case letter, one lower case letter, and one non-alphanumeric character except (single-quote, double-quote, backslash, right-bracket, full-stop). Also, the password must not contain 3 consecutive characters from the cluster username or SSH username.')
@secure()
param clusterLoginPassword string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string

@description('This field must be a valid SSH public key.')
@secure()
param sshPublicKey string

@description('The number of nodes in the HDInsight cluster.')
param clusterWorkerNodeCount int = 4

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
])
@description('This is the headnode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param HeadNodeVirtualMachineSize string = 'Standard_D3_v2'

@allowed([
  'Standard_A4_v2'
  'Standard_A8_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_D5_v2'
  'Standard_D12_v2'
  'Standard_D13_v2'
])
@description('This is the worerdnode Azure Virtual Machine size, and will affect the cost. If you don\'t know, just leave the default value.')
param WorkerNodeVirtualMachineSize string = 'Standard_D3_v2'

var storageAccountName_var = '${uniqueString(resourceGroup().id)}storage'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
  properties: {}
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
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
          name: replace(replace(concat(reference(storageAccountName.id, '2019-06-01').primaryEndpoints.blob), 'https:', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(storageAccountName.id, '2019-06-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: HeadNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              sshProfile: {
                publicKeys: [
                  {
                    certificateData: sshPublicKey
                  }
                ]
              }
            }
          }
        }
        {
          name: 'workernode'
          targetInstanceCount: clusterWorkerNodeCount
          hardwareProfile: {
            vmSize: WorkerNodeVirtualMachineSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: sshUserName
              sshProfile: {
                publicKeys: [
                  {
                    certificateData: sshPublicKey
                  }
                ]
              }
            }
          }
        }
      ]
    }
  }
}

output cluster object = clusterName_resource.properties