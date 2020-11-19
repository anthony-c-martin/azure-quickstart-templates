param adminUsername string {
  metadata: {
    description: 'The name of the administrator of the new VM. Exclusion list: \'admin\',\'administrator\''
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the administrator account of the new VM'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
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
    description: 'String used as a base for naming resources (9 characters or less).'
  }
  default: 'MySet'
}
param instanceCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'Number of VM instances (100 or less).'
  }
  default: 2
}

var vnetv4AddressRange = '10.0.0.0/16'
var vnetv6AddressRange = 'ace:cab:deca::/48'
var subnetv4AddressRange = '10.0.0.0/24'
var subnetv6AddressRange = 'ace:cab:deca:deed::/64'
var virtualNetworkName = '${vmssName}vnet'
var subnetName = '${vmssName}subnet'
var natPoolName = '${vmssName}natpool'
var bePoolName = '${vmssName}bepool'
var bePoolv6Name = '${vmssName}bepoolv6'
var natStartPort = 50000
var natEndPort = 50120
var natBackendPort = 3389
var nicName = '${vmssName}nic'
var ipConfigName = '${vmssName}ipconfig'
var ipConfigNameV6 = '${vmssName}ipconfig-v6'
var imageReference = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2019-Datacenter'
  version: 'latest'
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-07-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    dhcpOptions: {
      dnsServers: [
        'cafe:43::'
        'cafe:45::'
      ]
    }
    addressSpace: {
      addressPrefixes: [
        vnetv4AddressRange
        vnetv6AddressRange
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefixes: [
            subnetv4AddressRange
            subnetv6AddressRange
          ]
        }
      }
    ]
  }
}

resource PIPv4 'Microsoft.Network/publicIPAddresses@2019-07-01' = {
  name: 'PIPv4'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}

resource PIPv6 'Microsoft.Network/publicIPAddresses@2019-07-01' = {
  name: 'PIPv6'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv6'
  }
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2019-07-01' = {
  name: 'loadBalancer'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LBFE'
        properties: {
          publicIPAddress: {
            id: PIPv4.id
          }
        }
      }
      {
        name: 'LBFE-v6'
        properties: {
          publicIPAddress: {
            id: PIPv6.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
      {
        name: bePoolv6Name
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'loadBalancer', 'LBFE')
          }
          protocol: 'tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
  }
  dependsOn: [
    PIPv4
    PIPv6
  ]
}

resource VmssNsg 'Microsoft.Network/networkSecurityGroups@2019-02-01' = {
  name: 'VmssNsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-HTTP-in'
        properties: {
          description: 'Allow HTTP'
          protocol: 'TCP'
          sourcePortRange: '80'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1001
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-all-out'
        properties: {
          description: 'Allow out All'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1002
          direction: 'Outbound'
        }
      }
      {
        name: 'allow-RDP-in'
        properties: {
          description: 'Allow RDP'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1003
          direction: 'Inbound'
        }
      }
      {
        name: 'allow-MyIpv6App-out'
        properties: {
          description: 'Allow My IPv6 App'
          protocol: 'Tcp'
          sourcePortRange: '33819-33829'
          destinationPortRange: '5000-6000'
          sourceAddressPrefix: 'ace:cab:deca:deed::/64'
          destinationAddressPrefixes: [
            'cab:cab:aaaa:bbbb::/64'
            'cab:cab:1111:2222::/64'
          ]
          access: 'Allow'
          priority: 1004
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vmssName_resource 'Microsoft.Compute/virtualMachineScaleSets@2019-07-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  properties: {
    overprovision: 'false'
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
        adminPassword: adminPassword
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              networkSecurityGroup: {
                id: VmssNsg.id
              }
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    primary: true
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
                    }
                    privateIPAddressVersion: 'IPv4'
                    publicipaddressconfiguration: {
                      name: 'pub1'
                      properties: {
                        idleTimeoutInMinutes: 15
                      }
                    }
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', 'loadBalancer', natPoolName)
                      }
                    ]
                  }
                }
                {
                  name: ipConfigNameV6
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
                    }
                    privateIPAddressVersion: 'IPv6'
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', bePoolv6Name)
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
    loadBalancer
    virtualNetworkName_resource
  ]
}