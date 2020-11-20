param location string {
  metadata: {
    description: 'Location for resources. Default is the current resource group location.'
  }
  default: resourceGroup().location
}
param vmSku string {
  metadata: {
    description: 'Size of VMs in the VM Scale Set.'
  }
  default: 'Standard_D1_v2'
}
param vmssName string {
  maxLength: 9
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
  default: 5
}
param adminUsername string {
  metadata: {
    description: 'Admin username on all VMs.'
  }
}
param publicIPPrefixLength int {
  minValue: 28
  maxValue: 31
  metadata: {
    description: 'Length of public IP prefix.'
  }
  default: 28
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

var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var publicIPPrefixName_var = '${vmssName}pubipprefix'
var dnsName = 'dns${toLower(vmssName)}'
var virtualNetworkName_var = '${vmssName}vnet'
var publicIPAddressName_var = '${vmssName}pip'
var subnetName = '${vmssName}subnet'
var loadBalancerName_var = '${vmssName}lb'
var publicIPAddressID = publicIPAddressName.id
var natPoolName = '${vmssName}natpool'
var bePoolName = '${vmssName}bepool'
var natStartPort = 50000
var natEndPort = 50120
var natBackendPort = 22
var nicName = '${vmssName}nic'
var ipConfigName = '${vmssName}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName_var, 'loadBalancerFrontEnd')
var osType = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '16.04-LTS'
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

resource publicIPPrefixName 'Microsoft.Network/publicIPPrefixes@2018-07-01' = {
  name: publicIPPrefixName_var
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    prefixLength: publicIPPrefixLength
    publicIPAddressVersion: 'IPv4'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2018-08-01' = {
  name: virtualNetworkName_var
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
        }
      }
    ]
  }
}

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2018-08-01' = {
  name: publicIPAddressName_var
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource loadBalancerName 'Microsoft.Network/loadBalancers@2018-08-01' = {
  name: loadBalancerName_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: publicIPAddressID
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
}

resource vmssName_res 'Microsoft.Compute/virtualMachineScaleSets@2018-10-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadOnly'
          createOption: 'FromImage'
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
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
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
                    }
                    publicIPAddressConfiguration: {
                      name: 'pub1'
                      properties: {
                        idleTimeoutInMinutes: 15
                        publicIPPrefix: {
                          id: publicIPPrefixName.id
                        }
                      }
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName_var, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName_var, natPoolName)
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
    loadBalancerName
    virtualNetworkName
  ]
}