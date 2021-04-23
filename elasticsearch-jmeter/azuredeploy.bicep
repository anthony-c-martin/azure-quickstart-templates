@description('Admin username used when provisioning virtual machines')
param adminUsername string

@description('Existing virtual network name to deploy into which contains Elasticsearch nodes')
param existingVirtualNetworkName string = 'es-vnet'

@allowed([
  1
  2
  3
  4
  5
  6
  7
  8
  9
])
@description('Number of subordinate JMeter nodes to provision')
param subNodeCount int = 2

@allowed([
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
  'Standard_A5'
  'Standard_A6'
  'Standard_A7'
])
@description('Size of the subordinate JMeter nodes')
param subNodeSize string = 'Standard_D2_v2'

@allowed([
  'Standard_D2_v2'
  'Standard_D3_v2'
  'Standard_D4_v2'
  'Standard_A2'
  'Standard_A3'
  'Standard_A4'
])
@description('Size of the boss JMeter node')
param bossNodeSize string = 'Standard_D2_v2'

@description('The location of the test library and jar dependencies. This is extracted to every node under /opt/jmeter/apache-jmeter-2.13/lib/junit')
param jarball string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/elasticsearch-jmeter/resources/jarball.zip'

@description('The location of the test jmx and run properties. This is extracted to the JMeter master node only, in /opt/jmeter')
param testpack string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/elasticsearch-jmeter/resources/testpack.zip'

@description('The name of the Elasticsearch cluster to target')
param esClusterName string = 'elasticsearch'

@description('Change this value to your repo name if deploying from a fork')
param templateBase string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master'

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

var apiVersion = '2015-06-15'
var templateBaseUrl = '${templateBase}/elasticsearch-jmeter/'
var storageAccountName_var = '${substring(uniqueString(resourceGroup().id, 'jmeter'), 0, 6)}jmeter'
var bossNodeIp = '10.0.4.10'
var subNodesIpPrefix = '10.0.4.2'
var networkSettings = {
  virtualNetworkName: existingVirtualNetworkName
  addressPrefix: '10.0.0.0/16'
  subnet: {
    jmeter: {
      name: 'jmeter'
      prefix: '10.0.4.0/24'
      vnet: existingVirtualNetworkName
    }
  }
}
var subnetRef = '${resourceId('Microsoft.Network/virtualNetworks', existingVirtualNetworkName)}/subnets/jmeter'
var nicName = 'jmeter-nic'
var vmName = 'jmeter-vm'
var setupScripts = [
  '${templateBaseUrl}jmeter-install.sh'
]
var settings = {
  imageReference: {
    publisher: 'Canonical'
    offer: 'UbuntuServer'
    sku: '14.04.5-LTS'
    version: 'latest'
  }
  managementPort: '22'
  extensionSettings: {
    boss: {
      publisher: 'Microsoft.Azure.Extensions'
      type: 'CustomScript'
      typeHandlerVersion: '2.0'
      autoUpgradeMinorVersion: true
      settings: {
        fileUris: setupScripts
        commandToExecute: 'bash jmeter-install.sh -mr ${subNodesIpPrefix}-${subNodeCount} -j ${jarball} -t ${testpack}'
      }
    }
    sub: {
      publisher: 'Microsoft.Azure.Extensions'
      type: 'CustomScript'
      typeHandlerVersion: '2.0'
      autoUpgradeMinorVersion: true
      settings: {
        fileUris: setupScripts
        commandToExecute: 'bash jmeter-install.sh -j ${jarball}'
      }
    }
  }
}
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

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: 'Standard_LRS'
  }
}

resource jmeter_pip 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: 'jmeter-pip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource jmeter_nsg 'Microsoft.Network/networkSecurityGroups@2015-06-15' = {
  name: 'jmeter-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          description: 'Allows SSH traffic'
          protocol: 'Tcp'
          sourcePortRange: settings.managementPort
          destinationPortRange: settings.managementPort
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource networkSettings_virtualNetworkName_jmeter 'Microsoft.Network/virtualNetworks/subnets@2015-06-15' = {
  name: '${networkSettings.virtualNetworkName}/jmeter'
  location: location
  properties: {
    addressPrefix: networkSettings.subnet.jmeter.prefix
  }
}

resource nicName_sub 'Microsoft.Network/networkInterfaces@2015-06-15' = [for i in range(0, subNodeCount): {
  name: '${nicName}-sub${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigsub'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: concat(subNodesIpPrefix, i)
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSettings_virtualNetworkName_jmeter
  ]
}]

resource nicName_boss 'Microsoft.Network/networkInterfaces@2015-06-15' = {
  name: '${nicName}-boss'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigboss'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: bossNodeIp
          publicIPAddress: {
            id: jmeter_pip.id
          }
          subnet: {
            id: subnetRef
          }
          networkSecurityGroup: {
            id: jmeter_nsg.id
          }
        }
      }
    ]
  }
}

resource vmName_boss 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: '${vmName}-boss'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: bossNodeSize
    }
    osProfile: {
      computerName: 'jmeter-boss'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: settings.imageReference
      osDisk: {
        name: '${vmName}-boss_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName_boss.id
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${nicName}-boss'
    storageAccountName
  ]
}

resource vmName_boss_installjmeter 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = {
  name: '${vmName}-boss/installjmeter'
  location: location
  properties: {
    publisher: settings.extensionSettings.boss.publisher
    type: settings.extensionSettings.boss.type
    typeHandlerVersion: settings.extensionSettings.boss.typeHandlerVersion
    settings: {
      fileUris: settings.extensionSettings.boss.settings.fileUris
      commandToExecute: concat(settings.extensionSettings.boss.settings.commandToExecute)
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName}-boss'
  ]
}

resource vmName_sub 'Microsoft.Compute/virtualMachines@2017-03-30' = [for i in range(0, subNodeCount): {
  name: '${vmName}-sub${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: subNodeSize
    }
    osProfile: {
      computerName: 'jmeter-sub${i}'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: settings.imageReference
      osDisk: {
        name: '${vmName}-sub${i}_OSDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', '${nicName}-sub${i}')
        }
      ]
    }
  }
  dependsOn: [
    'Microsoft.Network/networkInterfaces/${nicName}-sub${i}'
    storageAccountName
  ]
}]

resource vmName_sub_installjmeter 'Microsoft.Compute/virtualMachines/extensions@[variables(\'apiVersion\')]' = [for i in range(0, subNodeCount): {
  name: '${vmName}-sub${i}/installjmeter'
  location: location
  properties: {
    publisher: settings.extensionSettings.sub.publisher
    type: settings.extensionSettings.sub.type
    typeHandlerVersion: settings.extensionSettings.sub.typeHandlerVersion
    settings: {
      fileUris: settings.extensionSettings.sub.settings.fileUris
      commandToExecute: concat(settings.extensionSettings.sub.settings.commandToExecute)
    }
  }
  dependsOn: [
    'Microsoft.Compute/virtualMachines/${vmName}-sub${i}'
  ]
}]

output boss_pip string = reference('Microsoft.Network/publicIPAddresses/jmeter-pip').ipAddress