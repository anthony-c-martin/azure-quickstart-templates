@description('The name of the HDInsight cluster to create.')
param clusterName string

@description('These credentials can be used to submit jobs to the cluster and to log into cluster dashboards.')
param clusterLoginUserName string = 'admin'

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param clusterLoginPassword string

@description('These credentials can be used to remotely access the cluster.')
param sshUserName string = 'sshuser'

@description('The password must be at least 10 characters in length and must contain at least one digit, one non-alphanumeric character, and one upper or lower case letter.')
@secure()
param sshPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var vNet = {
  name: '${clusterName}-vnet'
  addressSpacePrefix: '10.0.0.0/16'
  subnetName: 'subnet1'
  subnetPrefix: '10.0.0.0/24'
  subnet: resourceId('Microsoft.Network/virtualNetworks/subnets', '${clusterName}-vnet', 'subnet1')
}
var networkSecurityGroup = {
  name: '${clusterName}-nsg'
}
var defaultStorageAccount = {
  name: uniqueString(resourceGroup().id)
  type: 'Standard_LRS'
}

resource networkSecurityGroup_name 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroup.name
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow_HDInsight_Management_Traffic'
        properties: {
          description: 'Allow traffic from the Azure health and management services to reach HDInsight'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'HDInsight'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow_Azure_Resolver_Traffic'
        properties: {
          description: 'Allow access from Azure\'s recursive resolver'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '168.63.129.16'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 301
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource vNet_name 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: vNet.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNet.addressSpacePrefix
      ]
    }
    subnets: [
      {
        name: vNet.subnetName
        properties: {
          addressPrefix: vNet.subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup_name.id
          }
        }
      }
    ]
  }
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
          name: replace(replace(concat(reference(defaultStorageAccount_name.id, '2019-06-01').primaryEndpoints.blob), 'https:', ''), '/', '')
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
          virtualNetworkProfile: {
            id: vNet_name.id
            subnet: vNet.subnet
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
          virtualNetworkProfile: {
            id: vNet_name.id
            subnet: vNet.subnet
          }
        }
      ]
    }
  }
}

output storage object = defaultStorageAccount_name.properties
output vnet object = vNet_name.properties
output cluster object = clusterName_resource.properties