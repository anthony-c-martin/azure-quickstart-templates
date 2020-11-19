param location string {
  metadata: {
    description: 'The Azure location to deploy all resources'
  }
  default: resourceGroup().location
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
  default: 'Standard_DS2_V2'
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
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'SAS token to access artifacts location, if required'
  }
  secure: true
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
var VMName = 'Server'
var nicName = 'NIC'
var nicSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, virtualNetworkSubnetName)
var provisionConfigurationURL = uri(artifactsLocation, 'nested/provisionConfiguration.json${artifactsLocationSasToken}')
var provisionNetworkURL = uri(artifactsLocation, 'nested/provisionNetwork.json${artifactsLocationSasToken}')
var provisionServerUrl = uri(artifactsLocation, 'nested/provisionServer.json${artifactsLocationSasToken}')
var provisionDNSUrl = uri(artifactsLocation, 'nested/provisionDNS.json${artifactsLocationSasToken}')

module provisionConfiguration '<failed to parse [variables(\'provisionConfigurationURL\')]>' = {
  name: 'provisionConfiguration'
  params: {
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    automationAccountName: automationAccountName
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: domainName
    location: location
    compileName: compileName
  }
}

module provisionNetwork '<failed to parse [variables(\'provisionNetworkURL\')]>' = {
  name: 'provisionNetwork'
  params: {
    location: location
    virtualNetworkName: virtualNetworkName
    virtualNetworkAddressRange: virtualNetworkAddressRange
    virtualNetworkSubnets: virtualNetworkSubnets
    nicName: nicName
    nicIPAddress: nicIPAddress
    nicSubnetRef: nicSubnetRef
    publicIPAddressName: publicIPAddressName
    publicIPAddressType: publicIPAddressType
  }
}

module provisionServer '<failed to parse [variables(\'provisionServerUrl\')]>' = {
  name: 'provisionServer'
  params: {
    location: location
    VMName: VMName
    VMSize: VMSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    NicName: nicName
    automationAccountName: automationAccountName
  }
  dependsOn: [
    provisionNetwork
    provisionConfiguration
  ]
}

module provisionDNS '<failed to parse [variables(\'provisionDNSUrl\')]>' = {
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