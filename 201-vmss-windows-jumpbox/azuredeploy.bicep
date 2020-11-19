param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1'
}
param windowsOSVersion string {
  allowed: [
    '2008-R2-SP1'
    '2012-Datacenter'
    '2012-R2-Datacenter'
    '2016-Datacenter'
  ]
  metadata: {
    description: 'The Windows version for the VM. This will pick a fully patched image of this given Windows version. Allowed values: 2008-R2-SP1, 2012-Datacenter, 2012-R2-Datacenter.'
  }
  default: '2016-Datacenter'
}
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources. Must be 3-61 characters in length and globally unique across Azure. A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param instanceCount int {
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password on all VMs.'
  }
  secure: true
}

var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var longNamingInfix = toLower(vmssName)
var jumpBoxName = '${namingInfix}jbox'
var jumpBoxSAName = '${uniqueString('${resourceGroup().id}${newStorageAccountSuffix}jumpboxsa')}jb'
var jumpBoxOSDiskName = '${jumpBoxName}_OSDisk'
var jumpBoxVHDContainerName = '${jumpBoxName}vhd'
var jumpBoxIPConfigName = '${jumpBoxName}ipconfig'
var jumpBoxNicName = '${jumpBoxName}nic'
var storageAccountType = 'Standard_LRS'
var newStorageAccountSuffix = '${namingInfix}sa'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPAddressName = '${namingInfix}pip'
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var osType = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: windowsOSVersion
  version: 'latest'
}
var imageReference = osType
var networkSecurityGroupName = 'default-NSG'

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2019-08-01' = {
  name: networkSecurityGroupName
  location: resourceGroup().location
  properties: {
    securityRules: [
      {
        name: 'default-allow-3389'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2017-04-01' = {
  name: virtualNetworkName
  location: resourceGroup().location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupName_resource.id
          }
        }
      }
    ]
  }
  dependsOn: [
    networkSecurityGroupName_resource
  ]
}

resource jumpBoxSAName_resource 'Microsoft.Storage/storageAccounts@2015-06-15' = {
  name: jumpBoxSAName
  location: resourceGroup().location
  properties: {
    accountType: storageAccountType
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2017-04-01' = {
  name: publicIPAddressName
  location: resourceGroup().location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource jumpBoxNicName_resource 'Microsoft.Network/networkInterfaces@2017-04-01' = {
  name: jumpBoxNicName
  location: resourceGroup().location
  properties: {
    ipConfigurations: [
      {
        name: jumpBoxIPConfigName
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIPAddressName_resource.id
          }
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
    virtualNetworkName_resource
  ]
}

resource jumpBoxName_resource 'Microsoft.Compute/virtualMachines@2017-03-30' = {
  name: jumpBoxName
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    osProfile: {
      computerName: jumpBoxName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: jumpBoxOSDiskName
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: jumpBoxNicName_resource.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: 'http://${jumpBoxSAName}.blob.core.windows.net'
      }
    }
  }
  dependsOn: [
    jumpBoxSAName_resource
    jumpBoxNicName_resource
  ]
}

resource namingInfix_resource 'Microsoft.Compute/virtualMachineScaleSets@2017-03-30' = {
  name: namingInfix
  location: resourceGroup().location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: 'true'
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}/subnets/${subnetName}'
                    }
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}