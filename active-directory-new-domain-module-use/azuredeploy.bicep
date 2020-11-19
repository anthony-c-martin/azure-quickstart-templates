param adminUsername string {
  metadata: {
    description: 'Admin username for the AD VMs'
  }
}
param adminPassword string {
  metadata: {
    description: 'Admin password for the AD VMs'
  }
  secure: true
}
param domainName string {
  metadata: {
    description: 'Domain name for the AD Controller'
  }
}
param dnsPrefix string {
  metadata: {
    description: 'PublicIp DNS prefix for the AD Controller'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources'
  }
  default: resourceGroup().location
}

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