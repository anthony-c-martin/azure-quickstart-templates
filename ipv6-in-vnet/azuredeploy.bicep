@description('The name of the administrator of the new VM. Exclusion list: \'admin\',\'administrator\'')
param adminUsername string

@description('The password for the administrator account of the new VM')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('description')
param vmSize string = 'Standard_A1_v2'

var vnetv4AddressRange = '10.0.0.0/16'
var vnetv6AddressRange = 'ace:cab:deca::/48'
var subnetv4AddressRange = '10.0.0.0/24'
var subnetv6AddressRange = 'ace:cab:deca:deed::/64'
var subnetName = 'DualStackSubnet'
var newStorageAccountName_var = 'st${uniqueString(resourceGroup().id)}'
var availabilitySetName_var = 'myavset'
var subnet_id = resourceId('Microsoft.Network/virtualNetworks/subnets', 'VNET', subnetName)
var numberOfInstances = 2
var vmName_var = 'DsVM'
var publicipName_var = 'RDPpublicIp'
var imagePublisher = 'MicrosoftWindowsServer'
var imageOffer = 'WindowsServer'
var imageSku = '2019-Datacenter'

resource publicipName 'Microsoft.Network/publicIPAddresses@2020-05-01' = [for i in range(0, numberOfInstances): {
  name: concat(publicipName_var, i)
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}]

resource lbpublicip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: 'lbpublicip'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource lbpublicip_v6 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: 'lbpublicip-v6'
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv6'
  }
}

resource availabilitySetName 'Microsoft.Compute/availabilitySets@2020-06-01' = {
  name: availabilitySetName_var
  location: location
  properties: {
    platformFaultDomainCount: '2'
    platformUpdateDomainCount: '5'
  }
  sku: {
    name: 'Aligned'
  }
}

resource newStorageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: newStorageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource loadBalancer 'Microsoft.Network/loadBalancers@2020-05-01' = {
  name: 'loadBalancer'
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LBFE'
        properties: {
          publicIPAddress: {
            id: lbpublicip.id
          }
        }
      }
      {
        name: 'LBFE-v6'
        properties: {
          publicIPAddress: {
            id: lbpublicip_v6.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'LBBAP'
      }
      {
        name: 'LBBAP-v6'
      }
    ]
    loadBalancingRules: [
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'loadBalancer', 'LBFE')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
          idleTimeoutInMinutes: 15
        }
        name: 'lbrule'
      }
      {
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/loadBalancers/frontendIpConfigurations', 'loadBalancer', 'LBFE-v6')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP-v6')
          }
          protocol: 'Tcp'
          frontendPort: 80
          backendPort: 80
        }
        name: 'lbrule-v6'
      }
    ]
  }
}

resource VNET 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: 'VNET'
  location: location
  properties: {
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

resource dsNsg 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: 'dsNsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-HTTP-in'
        properties: {
          description: 'Allow HTTP'
          protocol: 'Tcp'
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

resource v6routeTable 'Microsoft.Network/routeTables@2020-05-01' = {
  name: 'v6routeTable'
  location: location
  properties: {
    routes: [
      {
        name: 'v6route'
        properties: {
          addressPrefix: 'cab:cab::/96'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: 'ace:cab:deca:f00d::1'
        }
      }
    ]
  }
}

resource vmName 'Microsoft.Network/networkInterfaces@2020-05-01' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    networkSecurityGroup: {
      id: dsNsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig-v4'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          primary: true
          publicIPAddress: {
            id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicipName_var, i))
          }
          subnet: {
            id: subnet_id
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP')
            }
          ]
        }
      }
      {
        name: 'ipconfig-v6'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv6'
          subnet: {
            id: subnet_id
          }
          loadBalancerBackendAddressPools: [
            {
              id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', 'loadBalancer', 'LBBAP-v6')
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    VNET
    dsNsg
    loadBalancer
    publicipName
  ]
}]

resource Microsoft_Compute_virtualMachines_vmName 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, numberOfInstances): {
  name: concat(vmName_var, i)
  location: location
  properties: {
    availabilitySet: {
      id: availabilitySetName.id
    }
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: concat(vmName_var, i)
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: imagePublisher
        offer: imageOffer
        sku: imageSku
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(vmName_var, i))
        }
      ]
    }
  }
  dependsOn: [
    newStorageAccountName
    availabilitySetName
    vmName
  ]
}]