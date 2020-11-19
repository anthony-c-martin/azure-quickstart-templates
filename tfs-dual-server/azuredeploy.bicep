param adminUsername string {
  metadata: {
    description: 'The name of the administrator account to create'
  }
}
param adminPassword string {
  metadata: {
    description: 'The password for the Administrator account'
  }
  secure: true
}
param domainName string {
  metadata: {
    description: 'The FQDN of the Active Directory Domain to be created'
  }
}
param vmSize string {
  metadata: {
    description: 'The size of the VMs to create'
  }
  default: 'Standard_D4_v3'
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/tfs-dual-server/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var vnetName = 'tfsStandardVNet'
var loadBalancerName = 'tfsStandardLoadBalancer'
var subnetName = 'tfsStandardSubnet'
var loadBalancerBackendName = 'LoadBalancerBackend'
var availabilitySetName = 'tfsStandardAvailabilitySet'
var dcIpAddress = '10.0.0.4'
var nestedTemplates = {
  networkTemplate: uri(artifactsLocation, 'nestedtemplates/virtualNetwork.json${artifactsLocationSasToken}')
  domainControllerTemplate: uri(artifactsLocation, 'nestedtemplates/domainController.json${artifactsLocationSasToken}')
  sqlServerTemplate: uri(artifactsLocation, 'nestedtemplates/sqlServer.json${artifactsLocationSasToken}')
  tfsServerTemplate: uri(artifactsLocation, 'nestedtemplates/tfs.json${artifactsLocationSasToken}')
}

module Network '<failed to parse [variables(\'nestedTemplates\').networkTemplate]>' = {
  name: 'Network'
  params: {
    vnetName: vnetName
    loadBalancerName: loadBalancerName
    subnetName: subnetName
    loadBalancerBackendName: loadBalancerBackendName
    availabilitySetName: availabilitySetName
    dnsServers: []
  }
}

module DomainController '<failed to parse [variables(\'nestedTemplates\').domainControllerTemplate]>' = {
  name: 'DomainController'
  params: {
    vmName: 'tfsDC'
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: domainName
    existingVnetName: vnetName
    existingSubnetName: subnetName
    existingAvailabilitySetName: availabilitySetName
    existingLoadBalancerName: loadBalancerName
    existingLoadBalancerBackendName: loadBalancerBackendName
    ipAddress: dcIpAddress
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    Network
  ]
}

module UpdateDNS '<failed to parse [variables(\'nestedTemplates\').networkTemplate]>' = {
  name: 'UpdateDNS'
  params: {
    vnetName: vnetName
    loadBalancerName: loadBalancerName
    subnetName: subnetName
    loadBalancerBackendName: loadBalancerBackendName
    availabilitySetName: availabilitySetName
    dnsServers: [
      dcIpAddress
    ]
  }
  dependsOn: [
    DomainController
  ]
}

module SQLServer '<failed to parse [variables(\'nestedTemplates\').sqlServerTemplate]>' = {
  name: 'SQLServer'
  params: {
    vmName: 'tfsSQL'
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: domainName
    existingVnetName: vnetName
    existingSubnetName: subnetName
    existingAvailabilitySetName: availabilitySetName
    existingLoadBalancerName: loadBalancerName
    existingLoadBalancerBackendName: loadBalancerBackendName
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    UpdateDNS
  ]
}

module TfsServer '<failed to parse [variables(\'nestedTemplates\').tfsServerTemplate]>' = {
  name: 'TfsServer'
  params: {
    vmName: 'tfsVM'
    vmSize: vmSize
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: domainName
    existingVnetName: vnetName
    existingSubnetName: subnetName
    existingAvailabilitySetName: availabilitySetName
    existingLoadBalancerName: loadBalancerName
    existingLoadBalancerBackendName: loadBalancerBackendName
    existingSqlInstance: 'tfsSQL.${domainName}'
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
  }
  dependsOn: [
    SQLServer
  ]
}