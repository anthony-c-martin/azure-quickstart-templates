@description('The name of the administrator account to create')
param adminUsername string

@description('The password for the Administrator account')
@secure()
param adminPassword string

@description('The FQDN of the Active Directory Domain to be created')
param domainName string

@description('The size of the VMs to create')
param vmSize string = 'Standard_D4_v3'

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/tfs-dual-server/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

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

module Network '?' /*TODO: replace with correct path to [variables('nestedTemplates').networkTemplate]*/ = {
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

module DomainController '?' /*TODO: replace with correct path to [variables('nestedTemplates').domainControllerTemplate]*/ = {
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

module UpdateDNS '?' /*TODO: replace with correct path to [variables('nestedTemplates').networkTemplate]*/ = {
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

module SQLServer '?' /*TODO: replace with correct path to [variables('nestedTemplates').sqlServerTemplate]*/ = {
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

module TfsServer '?' /*TODO: replace with correct path to [variables('nestedTemplates').tfsServerTemplate]*/ = {
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