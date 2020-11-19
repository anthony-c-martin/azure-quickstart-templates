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
param osType string {
  allowed: [
    'windows'
    'linux'
  ]
  metadata: {
    description: 'OS Type for the VMSS.'
  }
  default: 'windows'
}
param location string {
  metadata: {
    description: 'Location for the resources.'
  }
  default: resourceGroup().location
}

var osType_variable = {
  windows: {
    marketplacePlan: {
      name: 'windows2016'
      publisher: 'microsoft-ads'
      product: 'windows-data-science-vm'
    }
    imageReference: {
      publisher: 'microsoft-ads'
      offer: 'windows-data-science-vm'
      sku: 'windows2016'
      version: 'latest'
    }
    natBackendPort: 3389
  }
  linux: {
    marketplacePlan: {
      name: 'linuxdsvmubuntu'
      publisher: 'microsoft-ads'
      product: 'linux-data-science-vm-ubuntu'
    }
    imageReference: {
      publisher: 'microsoft-ads'
      offer: 'linux-data-science-vm-ubuntu'
      sku: 'linuxdsvmubuntu'
      version: 'latest'
    }
    natBackendPort: 3389
  }
}
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${vmssName}vnet'
var publicIPAddressName = '${vmssName}pip'
var subnetName = '${vmssName}subnet'
var loadBalancerName = '${vmssName}lb'
var publicIPAddressID = publicIPAddressName_resource.id
var natPoolName = '${vmssName}natpool'
var bePoolName = '${vmssName}bepool'
var natStartPort = 50000
var natEndPort = 50120
var nicName = '${vmssName}nic'
var ipConfigName = '${vmssName}ipconfig'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
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
        }
      }
    ]
  }
}

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2019-04-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: vmssName
    }
  }
}

resource loadBalancerName_resource 'Microsoft.Network/loadBalancers@2019-04-01' = {
  name: loadBalancerName
  location: location
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
          backendPort: osType_variable[osType].natBackendPort
        }
      }
    ]
  }
  dependsOn: [
    publicIPAddressName_resource
  ]
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  plan: osType_variable[osType].marketplacePlan
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
        }
        imageReference: osType_variable[osType].imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
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
    loadBalancerName_resource
    virtualNetworkName_resource
  ]
}