param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_A1_v2'
}
param ubuntuOSVersion string {
  allowed: [
    '18.04-LTS'
    '16.04-LTS'
    '14.04.4-LTS'
  ]
  metadata: {
    description: 'The Ubuntu version for the VM. This will pick a fully patched image of this given Ubuntu version. Allowed values are: 18.04-LTS, 16.04-LTS, 14.04.4-LTS.'
  }
  default: '18.04-LTS'
}
param vmssName string {
  maxLength: 61
  metadata: {
    description: 'String used as a base for naming resources (9 characters or less). A hash is prepended to this string for some resources, and resource-specific information is appended.'
  }
}
param instanceCount int {
  minValue: 1
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
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var namingInfix = toLower(substring(concat(vmssName, uniqueString(resourceGroup().id)), 0, 9))
var newStorageAccountSuffix = '${namingInfix}sa'
var longNamingInfix = toLower(vmssName)
var jumpBoxName = '${namingInfix}jbox'
var jumpBoxSAName = '${uniqueString('${resourceGroup().id}${newStorageAccountSuffix}jumpboxsa')}jb'
var jumpBoxOSDiskName = '${jumpBoxName}osdisk'
var jumpBoxIPConfigName = '${jumpBoxName}ipconfig'
var jumpBoxNicName = '${jumpBoxName}nic'
var storageAccountType = 'Standard_LRS'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${namingInfix}vnet'
var subnetName = '${namingInfix}subnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPAddressName = '${namingInfix}pip'
var loadBalancerName = '${namingInfix}lb'
var natPoolName = '${namingInfix}natpool'
var bePoolName = '${namingInfix}bepool'
var natStartPort = 50000
var natEndPort = 50119
var natBackendPort = 22
var nicName = '${namingInfix}nic'
var ipConfigName = '${namingInfix}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: ubuntuOSVersion
  version: 'latest'
}
var imageReference = osType
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
var networkSecurityGroupName = '${subnetName}-nsg'

resource networkSecurityGroupName_resource 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'default-allow-22'
        properties: {
          priority: 1000
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '22'
          protocol: 'Tcp'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
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

resource jumpBoxSAName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: jumpBoxSAName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource jumpBoxNicName_resource 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: jumpBoxNicName
  location: location
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

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: longNamingInfix
    }
  }
}

resource jumpBoxName_resource 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: jumpBoxName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSku
    }
    osProfile: {
      computerName: jumpBoxName
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    storageProfile: {
      imageReference: imageReference
      osDisk: {
        name: '${jumpBoxOSDiskName}_OSDisk'
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
        storageUri: reference(jumpBoxSAName, '2018-02-01').primaryEndpoints.blob
      }
    }
  }
  dependsOn: [
    jumpBoxSAName_resource
    jumpBoxNicName_resource
  ]
}

resource loadBalancerName_resource 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: loadBalancerName
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource namingInfix_resource 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: namingInfix
  location: location
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
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: namingInfix
        adminUsername: adminUsername
        adminPassword: adminPasswordOrKey
        linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
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
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName, natPoolName)
                      }
                    ]
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
    loadBalancerName_resource
  ]
}