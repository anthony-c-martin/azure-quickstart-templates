@allowed([
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
])
@description('The Azure location to deploy all resources')
param location string

@description('Naming convention for the vm scale set')
param vmssName string = 'srv'

@description('The number of vms to  provision initially in the scale set')
param instanceCount int = 2

@description('The address range of the new virtual network ')
param virtualNetworkAddressRange string = '10.0.0.0/16'

@description('The address range of the subnet created in the new virtual network')
param virtualNetworkSubnet string = '10.0.0.0/24'

@description('The IP address of the new AD VM')
param nicIPAddress string = '10.0.0.4'

@description('The name of the Administrator of the new VM and Domain')
param adminUsername string

@description('The password for the Administrator account of the new VM and Domain')
@secure()
param adminPassword string

@description('The size of the VM Created')
param VMSize string = 'Standard_B2s'

@description('The full qualified domain name to be created')
param domainName string = 'contoso.local'

@description('Path to the nested templates used in this deployment')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-vmss-automation-dsc/'

@description('SAS token to access artifacts location, if required')
param artifactsLocationSasToken string = ''

@description('Unique value to identify compilation job')
param compileName string = guid(resourceGroup().id, deployment().name)

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