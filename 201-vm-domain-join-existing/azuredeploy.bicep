@minLength(1)
@description('List of virtual machines to be domain joined, if using multiple VMs, make their names comma separate. E.g. VM01, VM02, VM03.')
param vmList string

@description('Location name of the virtual machine')
param location string = resourceGroup().location

@description('Domain NetBiosName plus User name of a domain user with sufficient rights to perfom domain join operation. E.g. domain\\username')
param domainJoinUserName string

@description('Domain user password')
@secure()
param domainJoinUserPassword string

@description('Domain FQDN where the virtual machine will be joined')
param domainFQDN string

@description('Specifies an organizational unit (OU) for the domain account. Enter the full distinguished name of the OU in quotation marks. Example: "OU=testOU; DC=domain; DC=Domain; DC=com"')
param ouPath string = ''

var domainJoinOptions = 3
var vmListArray = split(vmList, ',')

resource vmListArray_joindomain 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for item in vmListArray: {
  name: '${trim(item)}/joindomain'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'JsonADDomainExtension'
    typeHandlerVersion: '1.3'
    autoUpgradeMinorVersion: true
    settings: {
      Name: domainFQDN
      User: domainJoinUserName
      Restart: 'true'
      Options: domainJoinOptions
      OUPath: ouPath
    }
    protectedSettings: {
      Password: domainJoinUserPassword
    }
  }
}]