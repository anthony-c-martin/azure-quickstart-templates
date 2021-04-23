@description('Prefix for all items created by this template.')
param clusterName string

@description('Unique public DNS prefix for the deployment. The fqdn will look something like \'<dnsname>.westus.cloudapp.azure.com\'. Up to 62 chars, digits or dashes, lowercase, should start with a letter: must conform to \'^[a-z][a-z0-9-]{1,61}[a-z0-9]$\'.')
param publicDnsName string

@description('The name of the administrator of the new VM. Exclusion list: \'admin\',\'administrator\'')
param adminUsername string

@description('The password for the administrator account of the new VM')
@secure()
param adminPassword string

@description('Size of the repository.')
param repositoryVMSize string = 'Standard_A1'

@description('Size of the slave.')
param slaveVMSize string = 'Standard_A1'

@description('The number of slave vms to start.')
param numberOfSlaves int

@description('Location for all resources.')
param location string = resourceGroup().location

var storageAccountName = '${uniqueString(resourceGroup().id)}storage'
var virtualNetworkName_var = '${clusterName}-vnet'
var vnetAddressRange = '10.0.0.0/16'
var subnetAddressRange = '10.0.0.0/24'
var subnetName = '${clusterName}-subnet'
var subnet_id = '${virtualNetworkName.id}/subnets/${subnetName}'
var repositoryName_var = '${clusterName}-repository'
var slaveName_var = '${clusterName}-slave'
var publicIpName_var = '${clusterName}-publicIp'
var networkSecurityGroupName_var = '${clusterName}-nsg'
var networkInterfaceName_var = '${clusterName}-nif'
var fullDnsName = concat(clusterName, publicDnsName)

resource publicIpName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = {
  name: publicIpName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: fullDnsName
    }
  }
}

resource Microsoft_Network_publicIPAddresses_publicIpName 'Microsoft.Network/publicIPAddresses@2015-05-01-preview' = [for i in range(0, numberOfSlaves): {
  name: concat(publicIpName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: concat(fullDnsName, i)
    }
  }
}]

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2015-05-01-preview' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'mongo'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '27070'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'rdp'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-05-01-preview' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressRange
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetAddressRange
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = {
  name: networkInterfaceName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
          publicIPAddress: {
            id: publicIpName.id
          }
        }
      }
    ]
  }
}

resource Microsoft_Network_networkInterfaces_networkInterfaceName 'Microsoft.Network/networkInterfaces@2015-05-01-preview' = [for i in range(0, numberOfSlaves): {
  name: concat(networkInterfaceName_var, i)
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnet_id
          }
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIpName_var, i))
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
    resourceId('Microsoft.Network/publicIPAddresses', concat(publicIpName_var, i))
  ]
}]

resource repositoryName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: repositoryName_var
  location: location
  plan: {
    name: 'deadline-repository-7-2'
    publisher: 'thinkboxsoftware'
    product: 'deadline7-2'
  }
  properties: {
    hardwareProfile: {
      vmSize: repositoryVMSize
    }
    osProfile: {
      computerName: 'azure-repo'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'thinkboxsoftware'
        offer: 'deadline7-2'
        sku: 'deadline-repository-7-2'
        version: '1.0.0'
      }
      osDisk: {
        name: '${repositoryName_var}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
  }
}

resource repositoryName_autoconf 'Microsoft.Compute/virtualMachines/extensions@2015-05-01-preview' = {
  parent: repositoryName
  name: 'autoconf'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.4'
    settings: {
      fileUris: [
        'https://deadline.blob.core.windows.net/scripts/repo-autoconf.py'
      ]
      commandToExecute: 'python repo-autoconf.py'
    }
  }
}

resource slaveName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfSlaves): {
  name: concat(slaveName_var, i)
  location: location
  plan: {
    name: 'deadline-slave-7-2'
    publisher: 'thinkboxsoftware'
    product: 'deadline7-2'
  }
  properties: {
    hardwareProfile: {
      vmSize: slaveVMSize
    }
    osProfile: {
      computerName: 'azure-slave${i}'
      adminUsername: adminUsername
      adminPassword: adminPassword
      customData: base64(reference(networkInterfaceName_var).ipConfigurations[0].properties.privateIPAddress)
    }
    storageProfile: {
      imageReference: {
        publisher: 'thinkboxsoftware'
        offer: 'deadline7-2'
        sku: 'deadline-slave-7-2'
        version: '1.0.0'
      }
      osDisk: {
        name: '${slaveName_var}${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(networkInterfaceName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', concat(networkInterfaceName_var, i))
    repositoryName
    repositoryName_autoconf
  ]
}]