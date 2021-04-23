@description('Admin username for the AD VMs')
param adminUsername string

@description('Admin password for the AD VMs')
@secure()
param adminPassword string

@description('Domain name for the AD Controller')
param domainName string

@description('PublicIp DNS prefix for the AD Controller')
param dnsPrefix string

@description('Location for all resources')
param location string = resourceGroup().location

module createADController '?' /*TODO: replace with correct path to https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/modules/active-directory-new-domain/0.9/azuredeploy.json*/ = {
  name: 'createADController'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    domainName: domainName
    dnsPrefix: dnsPrefix
    location: location
  }
}

output output object = reference('createADController').outputs