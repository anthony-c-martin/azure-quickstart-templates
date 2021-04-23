@description('Index to create multiple DCs. Index == 0 means it will be a new domain and a PDCE will be created')
param indx int = 0

@description('Computer Name, will be suffixed by the indx')
param computerName string = 'mbmr'

@description('The password to join the domain')
@secure()
param domainJoinPassword string

@description('The FQDN of the AD Domain created ')
param domainName string = 'fabrikam.com'

@description('Name of the vm, will be suffixed by the indx')
param vmNamePrefix string = 'srv-'

@description('The user to join the domain')
param domainJoinUsername string = 'zeAdmin'

@description('Location for all resources.')
param location string = resourceGroup().location

var vmName = concat(vmNamePrefix, computerName, indx)

resource vmName_extensions 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = {
  name: '${vmName}/extensions'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.0'
    settings: {
      Name: domainName
      OUPath: ''
      User: '${domainJoinUsername}@${domainName}'
      Restart: 'true'
      Options: 3
    }
    protectedSettings: {
      Password: domainJoinPassword
    }
  }
}