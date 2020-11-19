param location string {
  allowed: [
    'japaneast'
    'eastus2'
    'westeurope'
    'southeastasia'
    'southcentralus'
    'australiaeast'
    'koreacentral'
    'westus2'
    'brazilsouth'
    'uksouth'
    'westcentralus'
    'northeurope'
    'canadacentral'
    'australiasoutheast'
    'centralindia'
    'francecentral'
  ]
  metadata: {
    description: 'The Azure location to deploy all resources'
  }
}
param vmssName string {
  metadata: {
    description: 'Naming convention for the vm scale set'
  }
  default: 'srv'
}
param instanceCount int {
  metadata: {
    description: 'The number of vms to  provision initially in the scale set'
  }
  default: '2'
}
param virtualNetworkAddressRange string {
  metadata: {
    description: 'The address range of the new virtual network '
  }
  default: '10.0.0.0/16'
}
param virtualNetworkSubnet string {
  metadata: {
    description: 'The address range of the subnet created in the new virtual network'
  }
  default: '10.0.0.0/24'
}
param nicIPAddress string {
  metadata: {
    description: 'The IP address of the new AD VM'
  }
  default: '10.0.0.4'
}
param adminUsername string {
  metadata: {
    description: 'The name of the Administrator of the new VM and Domain'
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the Administrator account of the new VM and Domain'
  }
  secure: true
}
param VMSize string {
  metadata: {
    description: 'The size of the VM Created'
  }
  default: 'Standard_B2s'
}
param domainName string {
  metadata: {
    description: 'The full qualified domain name to be created'
  }
  default: 'contoso.local'
}
param artifactsLocation string {
  metadata: {
    description: 'Path to the nested templates used in this deployment'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-automation-dsc/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'SAS token to access artifacts location, if required'
  }
  default: ''
}
param compileName string {
  metadata: {
    description: 'Unique value to identify compilation job'
  }
  default: guid(resourceGroup().id, deployment().name)
}

var automationAccountName = 'DSC-${take(guid(resourceGroup().id), 5)}'
var publicIPAddressName = 'PIP'
var publicIPAddressType = 'Dynamic'
var virtualNetworkName = 'Network'
var virtualNetworkSubnetName = 'Subnet'
var virtualNetworkSubnets = [
  {
    name: virtualNetworkSubnetName
    properties: {
      addressPrefix: virtualNetworkSubnet
    }
  }
]
var loadBalancerName = 'LoadBalancer'
var nicName = 'NIC'
var nicSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)
var provisionConfigurationURL = uri(artifactsLocation, 'nested/provisionConfiguration.json${artifactsLocationSasToken}')
var provisionNetworkURL = uri(artifactsLocation, 'nested/provisionNetwork.json${artifactsLocationSasToken}')
var provisionServerUrl = uri(artifactsLocation, 'nested/provisionServer.json${artifactsLocationSasToken}')
var provisionDNSUrl = uri(artifactsLocation, 'nested/provisionDNS.json${artifactsLocationSasToken}')

module provisionConfiguration '?' /*TODO: replace with correct path to [variables('provisionConfigurationURL')]*/ = {
  name: 'provisionConfiguration'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    automationAccountName: automationAccountName
    location: location
    compileName: compileName
  }
}

module provisionNetwork '?' /*TODO: replace with correct path to [variables('provisionNetworkURL')]*/ = {
  name: 'provisionNetwork'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    virtualNetworkSubnets: virtualNetworkSubnets
    publicIPAddressName: publicIPAddressName
    publicIPAddressType: publicIPAddressType
    loadBalancerName: loadBalancerName
  }
}

module provisionServer '?' /*TODO: replace with correct path to [variables('provisionServerUrl')]*/ = {
  name: 'provisionServer'
  params: {
    location: location
    vmssName: vmssName
    instanceCount: instanceCount
    VMSize: VMSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    NicName: nicName
    virtualNetworkName: virtualNetworkName
    subnetName: virtualNetworkSubnetName
    loadBalancerName: loadBalancerName
    automationAccountName: automationAccountName
  }
  dependsOn: [
    provisionNetwork
    provisionConfiguration
  ]
}

module provisionDNS '?' /*TODO: replace with correct path to [variables('provisionDNSUrl')]*/ = {
  name: 'provisionDNS'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    virtualNetworkSubnets: virtualNetworkSubnets
    dnsAddress: [
      nicIPAddress
    ]
  }
  dependsOn: [
    provisionServer
  ]
}