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

resource public_ip_address_name 'Microsoft.Network/publicIpAddresses@2020-05-01' = {
  name: public_ip_address_name_var
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource vnet_name_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = if (vnet_new_or_existing == 'new') {
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
        }
      }
    ]
  }
}

resource vnet_name_bastion_subnet_name 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = if (vnet_new_or_existing == 'existing') {
  parent: vnet_name_resource
  name: '${bastion_subnet_name}'
  location: location
  properties: {
    addressPrefix: bastion_subnet_ip_prefix
  }
}

resource bastion_host_name_resource 'Microsoft.Network/bastionHosts@2020-05-01' = {
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