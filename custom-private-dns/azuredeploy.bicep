@description('The private DNS suffix and zone name.')
param dnsZoneName string = 'private.local'

@description('The name of the Administrator of the new VM and Domain')
param adminUsername string = 'adAdministrator'

@description('The password for the Administrator account of the new VM and Domain')
@secure()
param adminPassword string

@description('The DNS name for the public IP address used by the Load Balancer infront of the DNS servers')
param serverPublicDnsName string

@description('The location of resources, such as templates and scripts, that this script depends on')
param assetLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/custom-private-dns'

@description('Location for all resources.')
param location string = resourceGroup().location

var adTemplate = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/active-directory-new-domain-ha-2-dc/azuredeploy.json'
var virtualNetworkName = 'adVNet'
var subnetName = 'default'
var adPDCVMName = 'adPDC'
var adBDCVMName = 'adBDC'
var subnetId = '${resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)}/subnets/${subnetName}'
var serverTemplateFolder = 'nested/server'
var serverTemplateFile = 'setupserver.json'
var vmTemplate = '${assetLocation}/nested/genericvm.json'
var winClientTemplateFolder = 'nested/windows-client'
var linClientTemplateFolder = 'nested/linux-client'
var winClientTemplateFile = 'setupwinclient.json'
var linClientTemplateFile = 'setuplinuxclient.json'
var bdcRDPPort = 13389
var pdcRDPPort = 3389
var artifactsLocationSasToken = ''

module adDeployment '?' /*TODO: replace with correct path to [variables('adTemplate')]*/ = {
  name: 'adDeployment'
  params: {
    domainName: dnsZoneName
    adminUsername: adminUsername
    adminPassword: adminPassword
    dnsPrefix: serverPublicDnsName
    pdcRDPPort: pdcRDPPort
    bdcRDPPort: bdcRDPPort
    '_artifactsLocation': 'parameters(\'assetLocation\')'
    '_artifactsLocationSasToken': artifactsLocationSasToken
    location: location
  }
}

module setupServer 'nested/server/setupserver.bicep' = {
  name: 'setupServer'
  params: {
    vmList: '${adPDCVMName},${adBDCVMName}'
    dnsZone: dnsZoneName
    vnetName: virtualNetworkName
    relativeDownloadFolder: './'
    assetLocation: '${assetLocation}/${serverTemplateFolder}'
  }
  dependsOn: [
    adDeployment
  ]
}

module setupWindowsClient 'nested/genericvm.bicep' = {
  name: 'setupWindowsClient'
  params: {
    vmName: 'WindowsClient'
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: subnetId
    imagePublisher: 'MicrosoftWindowsServer'
    imageOffer: 'WindowsServer'
    imageSKU: '2012-R2-Datacenter'
  }
  dependsOn: [
    setupServer
  ]
}

module WindowsExtension 'nested/windows-client/setupwinclient.bicep' = {
  name: 'WindowsExtension'
  params: {
    vmList: 'WindowsClient'
    dnsZone: dnsZoneName
    relativeDownloadFolder: './'
    assetLocation: '${assetLocation}/${winClientTemplateFolder}'
  }
  dependsOn: [
    setupWindowsClient
  ]
}

module setupLinuxClient 'nested/genericvm.bicep' = {
  name: 'setupLinuxClient'
  params: {
    vmName: 'LinuxClient'
    adminUsername: adminUsername
    adminPassword: adminPassword
    subnetId: subnetId
    imagePublisher: 'Canonical'
    imageOffer: 'UbuntuServer'
    imageSKU: '14.04.5-LTS'
  }
  dependsOn: [
    setupServer
  ]
}

module LinuxExtension 'nested/linux-client/setuplinuxclient.bicep' = {
  name: 'LinuxExtension'
  params: {
    vmList: 'LinuxClient'
    dnsZone: dnsZoneName
    assetLocation: '${assetLocation}/${linClientTemplateFolder}'
  }
  dependsOn: [
    setupLinuxClient
  ]
}