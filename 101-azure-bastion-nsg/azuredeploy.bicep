@description('Name of new or existing vnet to which Azure Bastion should be deployed')
param vnet_name string = 'vnet01'

@description('IP prefix for available addresses in vnet address space')
param vnet_ip_prefix string = '10.1.0.0/16'

@allowed([
  'new'
  'existing'
])
@description('Specify whether to provision new vnet or deploy to existing vnet')
param vnet_new_or_existing string = 'new'

@description('Bastion subnet IP prefix MUST be within vnet IP prefix address space')
param bastion_subnet_ip_prefix string = '10.1.1.0/27'

@description('Name of Azure Bastion resource')
param bastion_host_name string

@description('Azure region for Bastion and virtual network')
param location string = resourceGroup().location

var public_ip_address_name_var = '${bastion_host_name}-pip'
var bastion_subnet_name = 'AzureBastionSubnet'
var nsg_name_var = '${bastion_host_name}-nsg'

resource public_ip_address_name 'Microsoft.Network/publicIpAddresses@2020-07-01' = {
  name: public_ip_address_name_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nsg_name 'Microsoft.Network/networkSecurityGroups@2020-07-01' = {
  name: nsg_name_var
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHttpsInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManagerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'GatewayManager'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowLoadBalancerInBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationPortRange: '443'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowSshRdpOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRanges: [
            '22'
            '3389'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowAzureCloudCommunicationOutBound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationPortRange: '443'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionHostCommunicationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowGetSessionInformationOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRanges: [
            '80'
            '443'
          ]
          access: 'Allow'
          priority: 130
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutBound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 1000
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource vnet_name_resource 'Microsoft.Network/virtualNetworks@2020-07-01' = if (vnet_new_or_existing == 'new') {
  name: vnet_name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnet_ip_prefix
      ]
    }
    subnets: [
      {
        name: bastion_subnet_name
        properties: {
          addressPrefix: bastion_subnet_ip_prefix
          networkSecurityGroup: {
            id: nsg_name.id
          }
        }
      }
    ]
  }
}

resource vnet_name_bastion_subnet_name 'Microsoft.Network/virtualNetworks/subnets@2020-07-01' = if (vnet_new_or_existing == 'existing') {
  parent: vnet_name_resource
  name: '${bastion_subnet_name}'
  location: location
  properties: {
    addressPrefix: bastion_subnet_ip_prefix
    networkSecurityGroup: {
      id: nsg_name.id
    }
  }
}

resource bastion_host_name_resource 'Microsoft.Network/bastionHosts@2020-07-01' = {
  name: bastion_host_name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          subnet: {
            id: vnet_name_bastion_subnet_name.id
          }
          publicIPAddress: {
            id: public_ip_address_name.id
          }
        }
      }
    ]
  }
  dependsOn: [
    vnet_name_resource
  ]
}