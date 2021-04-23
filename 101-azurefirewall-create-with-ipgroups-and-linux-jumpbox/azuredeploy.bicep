@description('virtual network name')
param virtualNetworkName string = 'vnet${uniqueString(resourceGroup().id)}'
param ipgroups_name1 string = 'ipgroup1${uniqueString(resourceGroup().id)}'
param ipgroups_name2 string = 'ipgroup2${uniqueString(resourceGroup().id)}'

@description('Username for the Virtual Machine.')
param adminUsername string

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Zone numbers e.g. 1,2,3.')
param vmSize string = 'Standard_DS1_v2'

@minValue(1)
@maxValue(100)
@description('Number of public IP addresses for the Azure Firewall')
param numberOfFirewallPublicIPAddresses int = 1

@allowed([
  'sshPublicKey'
  'password'
])
@description('Type of authentication to use on the Virtual Machine. SSH key is recommended.')
param authenticationType string = 'sshPublicKey'

@description('SSH Key or password for the Virtual Machine. SSH key is recommended.')
@secure()
param adminPasswordOrKey string

var vnetAddressPrefix = '10.0.0.0/16'
var serversSubnetPrefix = '10.0.2.0/24'
var azureFirewallSubnetPrefix = '10.0.1.0/24'
var jumpboxSubnetPrefix = '10.0.0.0/24'
var nextHopIP = '10.0.1.4'
var azureFirewallSubnetName = 'AzureFirewallSubnet'
var jumpBoxSubnetName = 'JumpboxSubnet'
var serversSubnetName = 'ServersSubnet'
var jumpBoxPublicIPAddressName_var = 'JumpHostPublicIP'
var jumpBoxNsgName_var = 'JumpHostNSG'
var jumpBoxNicName_var = 'JumpHostNic'
var jumpBoxSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, jumpBoxSubnetName)
var serverNicName_var = 'ServerNic'
var serverSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, serversSubnetName)
var storageAccountName_var = '${uniqueString(resourceGroup().id)}sajumpbox'
var azfwRouteTableName_var = 'AzfwRouteTable'
var firewallName_var = 'firewall1'
var publicIPNamePrefix = 'publicIP'
var azureFirewallSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, azureFirewallSubnetName)
var azureFirewallSubnetJSON = json('{{"id": "${azureFirewallSubnetId}"}}')
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
var networkSecurityGroupName_var = '${serversSubnetName}-nsg'
var azureFirewallIpConfigurations = [for i in range(0, numberOfFirewallPublicIPAddresses): {
  name: 'IpConf${i}'
  properties: {
    subnet: ((i == 0) ? azureFirewallSubnetJSON : json('null'))
    publicIPAddress: {
      id: resourceId('Microsoft.Network/publicIPAddresses', concat(publicIPNamePrefix, (i + 1)))
    }
  }
}]

resource ipgroups_name1_resource 'Microsoft.Network/ipGroups@2020-06-01' = {
  name: ipgroups_name1
  location: location
  properties: {
    ipAddresses: [
      '13.73.64.64/26'
      '13.73.208.128/25'
      '52.126.194.0/23'
    ]
  }
}

resource ipgroups_name2_resource 'Microsoft.Network/ipGroups@2020-06-01' = {
  name: ipgroups_name2
  location: location
  properties: {
    ipAddresses: [
      '12.0.0.0/24'
      '13.9.0.0/24'
    ]
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {}
}

resource azfwRouteTableName 'Microsoft.Network/routeTables@2020-06-01' = {
  name: azfwRouteTableName_var
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'AzfwDefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: nextHopIP
        }
      }
    ]
  }
}

resource networkSecurityGroupName 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: networkSecurityGroupName_var
  location: location
  properties: {}
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-06-01' = {
  name: virtualNetworkName
  location: location
  tags: {
    displayName: virtualNetworkName
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: jumpBoxSubnetName
        properties: {
          addressPrefix: jumpboxSubnetPrefix
        }
      }
      {
        name: azureFirewallSubnetName
        properties: {
          addressPrefix: azureFirewallSubnetPrefix
        }
      }
      {
        name: serversSubnetName
        properties: {
          addressPrefix: serversSubnetPrefix
          routeTable: {
            id: azfwRouteTableName.id
          }
          networkSecurityGroup: {
            id: networkSecurityGroupName.id
          }
        }
      }
    ]
  }
}

resource publicIPNamePrefix_1 'Microsoft.Network/publicIPAddresses@2020-06-01' = [for i in range(0, numberOfFirewallPublicIPAddresses): {
  name: concat(publicIPNamePrefix, (i + 1))
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    publicIPAddressVersion: 'IPv4'
  }
}]

resource jumpBoxPublicIPAddressName 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: jumpBoxPublicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource jumpBoxNsgName 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: jumpBoxNsgName_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'myNetworkSecurityGroupRuleSSH'
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
    ]
  }
}

resource JumpBoxNicName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: jumpBoxNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: jumpBoxPublicIPAddressName.id
          }
          subnet: {
            id: jumpBoxSubnetId
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: jumpBoxNsgName.id
    }
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource ServerNicName 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: serverNicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: serverSubnetId
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
  ]
}

resource JumpBox 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'JumpBox'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'JumpBox'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: JumpBoxNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

resource Server 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: 'Server'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: 'Server'
      adminUsername: adminUsername
      adminPassword: adminPasswordOrKey
      linuxConfiguration: ((authenticationType == 'password') ? json('null') : linuxConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: ServerNicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

resource firewallName 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: firewallName_var
  location: location
  properties: {
    ipConfigurations: azureFirewallIpConfigurations
    applicationRuleCollections: [
      {
        name: 'appRc1'
        properties: {
          priority: 101
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'someAppRule'
              protocols: [
                {
                  protocolType: 'Http'
                  port: 8080
                }
              ]
              targetFqdns: [
                '*bing.com'
              ]
              sourceIpGroups: [
                ipgroups_name1_resource.id
              ]
            }
            {
              name: 'someOtherAppRule'
              protocols: [
                {
                  protocolType: 'Mssql'
                  port: 1433
                }
              ]
              targetFqdns: [
                'sql1${environment().suffixes.sqlServerHostname}'
              ]
              sourceIpGroups: [
                ipgroups_name1_resource.id
                ipgroups_name2_resource.id
              ]
            }
          ]
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'netRc1'
        properties: {
          priority: 200
          action: {
            type: 'Allow'
          }
          rules: [
            {
              name: 'networkRule'
              description: 'desc1'
              protocols: [
                'UDP'
                'TCP'
                'ICMP'
              ]
              sourceAddresses: [
                '10.0.0.0'
                '111.1.0.0/23'
              ]
              sourceIpGroups: [
                ipgroups_name1_resource.id
              ]
              destinationIpGroups: [
                ipgroups_name2_resource.id
              ]
              destinationPorts: [
                '90'
              ]
            }
          ]
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPNamePrefix_1
  ]
}