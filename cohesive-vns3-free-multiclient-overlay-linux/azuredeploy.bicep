@description('Admin User Name for VNS3 (required but not used)')
param adminUsername string

@description('Admin Password for VNS3 (required but not used)')
@secure()
param adminPassword string

@description('Admin User Name for Ubuntu VM')
param adminUsernameUbuntu string

@description('Admin Password for Ubuntu VM')
@secure()
param adminPasswordUbuntu string

@minValue(1)
@maxValue(5)
@description('VMs to deploy, max 5 as free edition only supports 5 clientpacks')
param numberOfInstances int

@description('Deployment location')
param location string = resourceGroup().location

@description('Size of VM instance, defaults to Standard_B1ms to keep within core limits while giving reasonable performance')
param instanceSize string = 'Standard_B1ms'

@description('The base URI where artifacts required by this template are located including a trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/cohesive-vns3-free-multiclient-overlay-linux/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var suffix = uniqueString(resourceGroup().id, location)
var resourceGroupName = toLower(resourceGroup().name)
var storageAccount_var = substring('${location}storage${suffix}', 0, 24)
var virtualNetworkName_var = '${resourceGroupName}-vnet'
var vns3ControllerName_var = 'VNS3Controller'
var networkInterfaceName_var = toLower('${vns3ControllerName_var}-nic')
var publicIPAddresseName_var = '${vns3ControllerName_var}-ip'
var networkSecurityGroupName_var = '${vns3ControllerName_var}-nsg'
var virtualSubnetName = 'VNS3_VirtualSubnet'
var vnetSubnet = '10.10.10.0/28'
var vnsStaticIp = '10.10.10.10'
var CustomScriptForLinux = 'CustomScript'
var scriptFileUri = uri(artifactsLocation, 'scripts/customextensionlinux.sh${artifactsLocationSasToken}')
var CustomScriptCommandToExecute = 'sudo bash customextensionlinux.sh'
var ubuntu = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04.0-LTS'
  version: 'latest'
}

resource vns3ControllerName 'Microsoft.Compute/virtualMachines@2019-03-01' = {
  name: vns3ControllerName_var
  location: location
  plan: {
    name: 'cohesive-vns3-4_4_x-free'
    product: 'vns3_4x_network_security'
    publisher: 'cohesive'
  }
  tags: {
    Name: 'VNS3 Controller'
  }
  properties: {
    hardwareProfile: {
      vmSize: instanceSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'cohesive'
        offer: 'vns3_4x_network_security'
        sku: 'cohesive-vns3-4_4_x-free'
        version: 'latest'
      }
      osDisk: {
        osType: 'Linux'
        name: '${vns3ControllerName_var}-disc'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: vns3ControllerName_var
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterfaceName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: reference(storageAccount_var, '2019-04-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    storageAccount
  ]
}

resource networkInterfaceName 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: networkInterfaceName_var
  location: location
  tags: {
    Name: 'VNS3 Controller'
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Static'
          privateIPAddress: vnsStaticIp
          publicIPAddress: {
            id: publicIPAddresseName.id
          }
          subnet: {
            id: virtualNetworkName_virtualSubnetName.id
          }
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: true
    networkSecurityGroup: {
      id: networkSecurityGroupName.id
    }
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2018-10-01' = {
  name: networkSecurityGroupName_var
  location: location
  tags: {
    Name: 'VNS3 Controller'
  }
  properties: {
    securityRules: [
      {
        name: 'VNS3_Web_API_Port'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8000'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'VNS3_UDP_1194'
        properties: {
          protocol: 'Udp'
          sourcePortRange: '1194'
          destinationPortRange: '1194'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'VNS3_UDP_500'
        properties: {
          protocol: 'Udp'
          sourcePortRange: '500'
          destinationPortRange: '500'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'VNS3_NAT_T'
        properties: {
          protocol: 'Udp'
          sourcePortRange: '4500'
          destinationPortRange: '4500'
          sourceAddressPrefix: '1.2.3.4/32'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
        }
      }
    ]
  }
}

resource publicIPAddresseName 'Microsoft.Network/publicIPAddresses@2018-10-01' = {
  name: publicIPAddresseName_var
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  tags: {
    Name: 'VNS3 Controller'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-10-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetSubnet
      ]
    }
    subnets: [
      {
        name: 'VNS3_VirtualSubnet'
        properties: {
          addressPrefix: vnetSubnet
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource storageAccount 'Microsoft.Storage/storageAccounts@2018-07-01' = {
  name: storageAccount_var
  location: location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'Storage'
  properties: {
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
    supportsHttpsTrafficOnly: false
    encryption: {
      services: {
        file: {
          enabled: true
        }
        blob: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource virtualNetworkName_virtualSubnetName 'Microsoft.Network/virtualNetworks/subnets@2019-06-01' = {
  parent: virtualNetworkName
  name: '${virtualSubnetName}'
  properties: {
    addressPrefix: vnetSubnet
  }
}

resource pip_ubuntuvm 'Microsoft.Network/publicIPAddresses@2018-10-01' = [for i in range(0, numberOfInstances): {
  name: 'pip-ubuntuvm${i}'
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  tags: {
    Name: 'VNS3 Controller'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}]

resource nic_ubuntuvm 'Microsoft.Network/networkInterfaces@2019-04-01' = [for i in range(0, numberOfInstances): {
  name: 'nic-ubuntuvm${i}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', 'pip-ubuntuvm${i}')
          }
          subnet: {
            id: virtualNetworkName_virtualSubnetName.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', 'nsg-ubuntuvm${i}')
    }
  }
  dependsOn: [
    virtualNetworkName_virtualSubnetName
    nsg_ubuntuvm
    pip_ubuntuvm
  ]
}]

resource nsg_ubuntuvm 'Microsoft.Network/networkSecurityGroups@2018-12-01' = [for i in range(0, numberOfInstances): {
  name: 'nsg-ubuntuvm${i}'
  location: location
  tags: {
    Name: 'VNS3 Controller'
  }
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
    ]
  }
}]

resource ubuntuvm 'Microsoft.Compute/virtualMachines@2019-03-01' = [for i in range(0, numberOfInstances): {
  name: 'ubuntuvm${i}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: instanceSize
    }
    osProfile: {
      computerName: 'ubuntuvm${i}'
      adminUsername: adminUsernameUbuntu
      adminPassword: adminPasswordUbuntu
    }
    storageProfile: {
      imageReference: ubuntu
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'nic-ubuntuvm${i}')
        }
      ]
    }
  }
  dependsOn: [
    nic_ubuntuvm
  ]
}]

resource ubuntuvm_CustomScriptForLinux 'Microsoft.Compute/virtualMachines/extensions@2019-03-01' = [for i in range(0, numberOfInstances): {
  name: 'ubuntuvm${i}/${CustomScriptForLinux}'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: CustomScriptForLinux
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptFileUri
      ]
      commandToExecute: CustomScriptCommandToExecute
    }
  }
  dependsOn: [
    ubuntuvm
  ]
}]