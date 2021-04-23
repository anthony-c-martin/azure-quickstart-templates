@description('The name of new Azure VNet where you can deploy Azure Sql Managed Instances and the resources that use them')
param virtualNetworkName string = 'MyNewVNet'

@description('VNet IP address range (VNet prefix)')
param virtualNetworkAddressPrefix string = '10.0.0.0/16'

@description('The name of default subnet for VNet (used to deploy VMs, web, and other client apps - no Managed Instances). You can delete this subnet later if you don\'t need it.')
param defaultSubnetName string = 'Default'

@description('Default subnet address range (subnet prefix)')
param defaultSubnetPrefix string = '10.0.0.0/24'

@description('The name of the subnet dedicated to Azure SQL Managed Instances')
param managedInstanceSubnetName string = 'ManagedInstances'

@description('IP Address range in the subnet dedicated to Azure SQL Managed Instances')
param managedInstanceSubnetPrefix string = '10.0.1.0/24'

@description('Name of network security group dedicated to managed instance subnet')
param nsgForManagedInstanceSubnet string = 'nsgManagedInstance'

@description('The name of the existing or new route table that enables access to Azure SQL Managed Instance Management Service that controls the instance, manages backups and other maintenance operations')
param routeTableForManagedInstanceSubnet string = 'rtManagedInstance'

@description('Azure data center location where all resources will be deployed')
param location string = resourceGroup().location

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2019-04-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: defaultSubnetName
        properties: {
          addressPrefix: defaultSubnetPrefix
        }
      }
      {
        name: managedInstanceSubnetName
        properties: {
          addressPrefix: managedInstanceSubnetPrefix
          networkSecurityGroup: {
            id: nsgForManagedInstanceSubnet_resource.id
          }
          routeTable: {
            id: routeTableForManagedInstanceSubnet_resource.id
          }
          delegations: [
            {
              name: 'miDelegation'
              properties: {
                serviceName: 'Microsoft.Sql/managedInstances'
              }
            }
          ]
        }
      }
    ]
  }
}

resource nsgForManagedInstanceSubnet_resource 'Microsoft.Network/networkSecurityGroups@2019-06-01' = {
  name: nsgForManagedInstanceSubnet
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow_tds_inbound'
        properties: {
          description: 'Allow access to data'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_redirect_inbound'
        properties: {
          description: 'Allow inbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1100
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_geodr_inbound'
        properties: {
          description: 'Allow inbound geodr traffic inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5022'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 1200
          direction: 'Inbound'
        }
      }
      {
        name: 'deny_all_inbound'
        properties: {
          description: 'Deny all other inbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'allow_linkedserver_outbound'
        properties: {
          description: 'Allow outbound linkedserver traffic inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1000
          direction: 'Outbound'
        }
      }
      {
        name: 'allow_redirect_outbound'
        properties: {
          description: 'Allow outbound redirect traffic to Managed Instance inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '11000-11999'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1100
          direction: 'Outbound'
        }
      }
      {
        name: 'allow_geodr_outbound'
        properties: {
          description: 'Allow outbound geodr traffic inside the virtual network'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '5022'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 1200
          direction: 'Outbound'
        }
      }
      {
        name: 'deny_all_outbound'
        properties: {
          description: 'Deny all other outbound traffic'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource routeTableForManagedInstanceSubnet_resource 'Microsoft.Network/routeTables@2019-04-01' = {
  name: routeTableForManagedInstanceSubnet
  location: location
  properties: {
    disableBgpRoutePropagation: false
  }
}