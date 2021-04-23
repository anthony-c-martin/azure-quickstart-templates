@description('Admin username for the backend servers')
param adminUsername string

@description('Password for the admin account on the backend servers')
@secure()
param adminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Size of the virtual machine.')
param vmSize string = 'Standard_B2ms'

var virtualMachines_myVM_name = 'myVM'
var virtualNetworks_myVNet_name_var = 'myVNet'
var net_interface = 'net-int'
var ipconfig_name = 'ipconfig'
var ipprefix_name_var = 'public_ip_prefix'
var ipprefix_size = 31
var publicIPAddress = 'public_ip'
var nsg_name = 'vm-nsg'
var firewall_name_var = 'FW-01'
var vnet_prefix = '10.0.0.0/16'
var fw_subnet_prefix = '10.0.0.0/24'
var backend_subnet_prefix = '10.0.1.0/24'
var azureFirewallSubnetId = virtualNetworks_myVNet_name_AzureFirewallSubnet.id
var azureFirewallSubnetJSON = json('{{"id": "${azureFirewallSubnetId}"}}')
var azureFirewallIpConfigurations = [for i in range(0, 2): {
  name: 'IpConf${(i + 1)}'
  properties: {
    subnet: (((i + 1) == 1) ? azureFirewallSubnetJSON : json('null'))
    publicIPAddress: {
      id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddress, (i + 1)))
    }
  }
}]

resource nsg_name_1 'Microsoft.Network/networkSecurityGroups@2020-06-01' = [for i in range(0, 2): {
  name: concat(nsg_name, (i + 1))
  location: location
  properties: {
    securityRules: [
      {
        name: 'RDP'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3389'
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

resource ipprefix_name 'Microsoft.Network/publicIPPrefixes@2020-06-01' = {
  name: ipprefix_name_var
  location: location
  properties: {
    prefixLength: ipprefix_size
    publicIPAddressVersion: 'IPv4'
  }
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
}

resource publicIPAddress_1 'Microsoft.Network/publicIPAddresses@2020-06-01' = [for i in range(0, 2): {
  name: concat(publicIPAddress, (i + 1))
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    publicIPPrefix: {
      id: ipprefix_name.id
    }
    idleTimeoutInMinutes: 4
  }
  dependsOn: [
    ipprefix_name
  ]
}]

resource virtualNetworks_myVNet_name 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworks_myVNet_name_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_prefix
      ]
    }
    subnets: [
      {
        name: 'myBackendSubnet'
        properties: {
          addressPrefix: backend_subnet_prefix
          routeTable: {
            id: rt_01.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource virtualNetworks_myVNet_name_AzureFirewallSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-06-01' = {
  parent: virtualNetworks_myVNet_name
  name: 'AzureFirewallSubnet'
  properties: {
    addressPrefix: fw_subnet_prefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
  }
}

resource virtualMachines_myVM_name_1 'Microsoft.Compute/virtualMachines@2020-06-01' = [for i in range(0, 2): {
  name: concat(virtualMachines_myVM_name, (i + 1))
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        osType: 'Windows'
        createOption: 'FromImage'
        caching: 'ReadWrite'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        diskSizeGB: 127
      }
    }
    osProfile: {
      computerName: concat(virtualMachines_myVM_name, (i + 1))
      adminUsername: adminUsername
      adminPassword: adminPassword
      windowsConfiguration: {
        provisionVMAgent: true
        enableAutomaticUpdates: true
      }
      allowExtensionOperations: true
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', concat(net_interface, (i + 1)))
        }
      ]
    }
  }
  dependsOn: [
    resourceId('Microsoft.Network/networkInterfaces', concat(net_interface, (i + 1)))
  ]
}]

resource net_interface_1 'Microsoft.Network/networkInterfaces@2020-06-01' = [for i in range(0, 2): {
  name: concat(net_interface, (i + 1))
  location: location
  properties: {
    ipConfigurations: [
      {
        name: concat(ipconfig_name, (i + 1))
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworks_myVNet_name_var, 'myBackendSubnet')
          }
          primary: true
        }
      }
    ]
    enableAcceleratedNetworking: false
    enableIPForwarding: false
    networkSecurityGroup: {
      id: resourceId('Microsoft.Network/networkSecurityGroups', concat(nsg_name, (i + 1)))
    }
  }
  dependsOn: [
    virtualNetworks_myVNet_name
    resourceId('Microsoft.Network/networkSecurityGroups', concat(nsg_name, (i + 1)))
  ]
}]

resource firewall_name 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: firewall_name_var
  location: location
  properties: {
    sku: {
      name: 'AZFW_VNet'
      tier: 'Standard'
    }
    threatIntelMode: 'Alert'
    ipConfigurations: azureFirewallIpConfigurations
    applicationRuleCollections: [
      {
        name: 'web'
        properties: {
          priority: 100
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'wan-address'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                'getmywanip.com'
              ]
              sourceAddresses: [
                '*'
              ]
            }
            {
              name: 'google'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              targetFqdns: [
                'www.google.com'
              ]
              sourceAddresses: [
                '10.0.1.0/24'
              ]
            }
            {
              name: 'wupdate'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 80
                }
                {
                  protocolType: 'Https'
                  port: 443
                }
              ]
              fqdnTags: [
                'WindowsUpdate'
              ]
              sourceAddresses: [
                '*'
              ]
            }
          ]
        }
      }
    ]
    natRuleCollections: [
      {
        name: 'Coll-01'
        properties: {
          priority: 100
          action: {
            type: 'Dnat'
          }
          rules: [
            {
              name: 'rdp-01'
              protocols: [
                'TCP'
              ]
              translatedAddress: '10.0.1.4'
              translatedPort: '3389'
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                reference(resourceId('Microsoft.Network/publicIPAddresses/', concat(publicIPAddress, 1))).ipAddress
              ]
              destinationPorts: [
                '3389'
              ]
            }
            {
              name: 'rdp-02'
              protocols: [
                'TCP'
              ]
              translatedAddress: '10.0.1.5'
              translatedPort: '3389'
              sourceAddresses: [
                '*'
              ]
              destinationAddresses: [
                reference(resourceId('Microsoft.Network/publicIPAddresses/', concat(publicIPAddress, 2))).ipAddress
              ]
              destinationPorts: [
                '3389'
              ]
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddress, 1))
    resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPAddress, 2))
  ]
}

resource rt_01 'Microsoft.Network/routeTables@2020-06-01' = {
  name: 'rt-01'
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'fw'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: '10.0.0.4'
        }
      }
    ]
  }
}