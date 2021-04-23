@description('The Linux VM user name')
param adminUsername string

@minValue(1)
@maxValue(50)
@description('Number Of Slaves')
param numberOfSlaves int = 1

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/spark-2.0-on-suse/'

@description('The sasToken required to access _artifactsLocation. When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var resourceGroupLocation = location
var storageAccountName_var = '${uniqueString(resourceGroup().id)}storageac'
var sparkMasterMachineName_var = 'sparkmaster'
var sparkSlaveMachineName_var = 'sparkslave'
var sparkMasterSize = 'Standard_D3_v2'
var sparkSlavesSize = 'Standard_D3_v2'
var sparkMasterPublicIpName_var = 'sparkMasterPublicIp'
var sparkNetWorkSecurityGroupName_var = 'nsgroup'
var sparkVirtualNetworkName_var = 'sparkVirtualNetwork'
var virtualNetworkAddressPrefix = '10.0.0.0/16'
var defaultSubnetAddressPrefix = '10.0.0.0/24'
var sparkMasterNetworkInterfaceName_var = 'ni_master'
var sparkSlaveNetworkInterfaceName_var = 'ni_slave'
var sparkMasterInternalIP = '10.0.0.4'
var ScriptFolder = 'scripts'
var sparkInstallScriptName = 'install_spark_environment.sh'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminPasswordOrKey
      }
    ]
  }
}

resource sparkMasterMachineName 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: sparkMasterMachineName_var
  location: resourceGroupLocation
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: sparkMasterNetworkInterfaceName.id
        }
      ]
    }
    hardwareProfile: {
      vmSize: sparkMasterSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'SUSE'
        offer: 'SLES'
        sku: '12-SP4'
        version: 'latest'
      }
      osDisk: {
        name: '${sparkMasterMachineName_var}_OSDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: sparkMasterMachineName_var
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
}

resource sparkMasterMachineName_configuresparkonmaster 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  parent: sparkMasterMachineName
  name: 'configuresparkonmaster'
  location: resourceGroupLocation
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, '${ScriptFolder}/${sparkInstallScriptName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sudo sh install_spark_environment.sh -m 1 -i ${reference(sparkMasterNetworkInterfaceName_var).ipConfigurations[0].properties.privateIPAddress} -k ${listKeys(storageAccountName.id, '2016-01-01').keys[0].value} -a ${storageAccountName_var}${artifactsLocationSasToken}'
    }
  }
  dependsOn: [
    sparkMasterNetworkInterfaceName
  ]
}

resource sparkSlaveMachineName 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, numberOfSlaves): {
  name: concat(sparkSlaveMachineName_var, i)
  location: resourceGroupLocation
  properties: {
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(sparkSlaveNetworkInterfaceName_var, i))
        }
      ]
    }
    hardwareProfile: {
      vmSize: sparkSlavesSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'SUSE'
        offer: 'SLES'
        sku: '12-SP4'
        version: 'latest'
      }
      osDisk: {
        name: '${sparkSlaveMachineName_var}${i}_OSDisk'
        createOption: 'FromImage'
        caching: 'ReadWrite'
      }
    }
    osProfile: {
      computerName: concat(sparkSlaveMachineName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', concat(sparkSlaveNetworkInterfaceName_var, i))
  ]
}]

resource sparkSlaveMachineName_configuresparkonslave 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfSlaves): {
  name: '${sparkSlaveMachineName_var}${i}/configuresparkonslave'
  location: resourceGroupLocation
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        uri(artifactsLocation, '${ScriptFolder}/${sparkInstallScriptName}${artifactsLocationSasToken}')
      ]
      commandToExecute: 'sudo sh install_spark_environment.sh -m 0 -i ${reference(sparkMasterNetworkInterfaceName_var).ipConfigurations[0].properties.privateIPAddress} -k ${listKeys(storageAccountName.id, '2016-01-01').keys[0].value} -a ${storageAccountName_var}${artifactsLocationSasToken}'
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', concat(sparkSlaveNetworkInterfaceName_var, i))
    resourceId('Microsoft.Compute/virtualMachines', concat(sparkSlaveMachineName_var, i))
    'Microsoft.Compute/virtualMachines/sparkmaster/extensions/configuresparkonmaster'
  ]
}]

resource sparkMasterNetworkInterfaceName 'Microsoft.Network/networkInterfaces@2016-03-30' = {
  name: sparkMasterNetworkInterfaceName_var
  location: resourceGroupLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddress: sparkMasterInternalIP
          privateIPAllocationMethod: 'Static'
          publicIPAddress: {
            id: sparkMasterPublicIpName.id
          }
          subnet: {
            id: '${sparkVirtualNetworkName.id}/subnets/default'
          }
        }
      }
    ]
    dnsSettings: {}
    enableIPForwarding: false
    networkSecurityGroup: {
      id: sparkNetWorkSecurityGroupName.id
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses', 'sparkMasterPublicIp')
  ]
}

resource sparkSlaveNetworkInterfaceName 'Microsoft.Network/networkInterfaces@2016-03-30' = [for i in range(0, numberOfSlaves): {
  name: concat(sparkSlaveNetworkInterfaceName_var, i)
  location: resourceGroupLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: '${sparkVirtualNetworkName.id}/subnets/default'
          }
        }
      }
    ]
    dnsSettings: {}
    enableIPForwarding: false
    networkSecurityGroup: {
      id: sparkNetWorkSecurityGroupName.id
    }
  }
  dependsOn: [
    sparkMasterNetworkInterfaceName
    sparkVirtualNetworkName
    sparkNetWorkSecurityGroupName
  ]
}]

resource sparkMasterPublicIpName 'Microsoft.Network/publicIPAddresses@2016-03-30' = {
  name: sparkMasterPublicIpName_var
  location: resourceGroupLocation
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    idleTimeoutInMinutes: 4
  }
}

resource sparkVirtualNetworkName 'Microsoft.Network/virtualNetworks@2016-03-30' = {
  name: sparkVirtualNetworkName_var
  location: resourceGroupLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'default'
        properties: {
          addressPrefix: defaultSubnetAddressPrefix
        }
      }
    ]
  }
}

resource sparkNetWorkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2016-03-30' = {
  name: sparkNetWorkSecurityGroupName_var
  location: resourceGroupLocation
  properties: {
    securityRules: [
      {
        name: 'default-allow-ssh'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'SparkUI'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '4040'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1010
          direction: 'Inbound'
        }
      }
      {
        name: 'SparkMasterUI'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1020
          direction: 'Inbound'
        }
      }
      {
        name: 'SparkHistoryServer'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '18080'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1030
          direction: 'Inbound'
        }
      }
      {
        name: 'MesosMaster'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '5050'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1040
          direction: 'Inbound'
        }
      }
      {
        name: 'SparkWorker'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '8081'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1050
          direction: 'Inbound'
        }
      }
      {
        name: 'SparkMasterService'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '7077'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1060
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2016-01-01' = {
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  name: storageAccountName_var
  location: resourceGroupLocation
  tags: {}
  properties: {}
}

output masterPrivateIP string = reference(sparkMasterNetworkInterfaceName_var).ipConfigurations[0].properties.privateIPAddress