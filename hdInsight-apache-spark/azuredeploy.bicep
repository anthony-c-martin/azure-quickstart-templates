@description('The name of the HDInsight cluster to create.')
param clusterName string

@description('These credentials can be used to submit jobs to the cluster, log into cluster dashboards, log into Ambari, and SSH into the cluster.')
param loginUsername string

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param loginPassword string

@allowed([
  'Standard_D12_v2'
  'Standard_D13_v2'
  'Standard_D14_v2'
])
@description('All nodes will be deployed using the specified hardware profile: D12(4 CPU Cores, 28GB of RAM), D13(8 CPU Cores, 56GB of RAM), D14(16 CPU Cores, 112 GB of RAM).')
param clusterNodeSize string = 'Standard_D12_v2'

@description('The number of worker nodes in the HDInsight cluster.')
param clusterWorkerNodeCount int = 2

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/hdInsight-apache-spark/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var clusterType = 'hadoop'
var clusterVnetSubnetName = '${clusterName}-subnet'
var clusterVnetAddressSpace = '172.16.228.0/23'
var clusterVNetSubnetAddressRange = '172.16.229.0/24'
var clusterStorageAccountName_var = take('store${clusterName}', 24)
var clusterVNetName_var = '${clusterName}-vnet'

resource clusterVNetName 'Microsoft.Network/virtualNetworks@2019-06-01' = {
  name: clusterVNetName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        clusterVnetAddressSpace
      ]
    }
    subnets: [
      {
        name: clusterVnetSubnetName
        properties: {
          addressPrefix: clusterVNetSubnetAddressRange
        }
      }
    ]
  }
}

resource clusterStorageAccountName 'Microsoft.Storage/storageAccounts@2019-04-01' = {
  name: clusterStorageAccountName_var
  location: location
  kind: 'Storage'
  sku: {
    name: 'Standard_LRS'
  }
}

resource clusterName_resource 'Microsoft.HDInsight/clusters@2018-06-01-preview' = {
  name: clusterName
  location: location
  properties: {
    clusterVersion: '3.6'
    osType: 'Linux'
    clusterDefinition: {
      kind: clusterType
      componentVersion: {
        Spark: '2.3'
      }
      configurations: {
        gateway: {
          'restAuthCredential.isEnabled': true
          'restAuthCredential.username': loginUsername
          'restAuthCredential.password': loginPassword
        }
        'hive-site': {
          'hive.metastore.client.connect.retry.delay': '5'
          'hive.execution.engine': 'mr'
          'hive.security.authorization.manager': 'org.apache.hadoop.hive.ql.security.authorization.DefaultHiveAuthorizationProvider'
        }
      }
    }
    storageProfile: {
      storageaccounts: [
        {
          name: replace(replace(clusterStorageAccountName.properties.primaryEndpoints.blob, 'https://', ''), '/', '')
          isDefault: true
          container: clusterName
          key: listKeys(clusterStorageAccountName.id, '2019-04-01').keys[0].value
        }
      ]
    }
    computeProfile: {
      roles: [
        {
          name: 'headnode'
          targetInstanceCount: 2
          hardwareProfile: {
            vmSize: clusterNodeSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: loginUsername
              password: loginPassword
            }
          }
          virtualNetworkProfile: {
            id: clusterVNetName.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVNetName_var, clusterVnetSubnetName)
          }
          scriptActions: [
            {
              name: 'Apache Spark 1.4.1'
              uri: uri(artifactsLocation, 'spark141-installer-v04.sh${artifactsLocationSasToken}')
            }
          ]
        }
        {
          name: 'workernode'
          targetInstanceCount: clusterWorkerNodeCount
          hardwareProfile: {
            vmSize: clusterNodeSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: loginUsername
              password: loginPassword
            }
          }
          virtualNetworkProfile: {
            id: clusterVNetName.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVNetName_var, clusterVnetSubnetName)
          }
        }
        {
          name: 'zookeepernode'
          targetInstanceCount: 3
          hardwareProfile: {
            vmSize: clusterNodeSize
          }
          osProfile: {
            linuxOperatingSystemProfile: {
              username: loginUsername
              password: loginPassword
            }
          }
          virtualNetworkProfile: {
            id: clusterVNetName.id
            subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', clusterVNetName_var, clusterVnetSubnetName)
          }
        }
      ]
    }
  }
}

output vnet object = clusterVNetName.properties
output cluster object = clusterName_resource.properties