@minLength(1)
@description('List of virtual machines to be configured.  If using multiple VMs, make their names comma separate, e.g. VM01,VM02,VM03.')
param vmList string

@description('Name of the dnsZone to use as the suffix on the clients and to register records in')
param dnsZone string

@description('The location of resources such as templates and scripts that the script is dependent')
param assetLocation string

@description('Location for all resources.')
param location string = resourceGroup().location

var vmListArray = split(replace(vmList, ' ', ''), ',')

resource vmListArray_SetupDnsClient 'Microsoft.Compute/virtualMachines/extensions@2016-08-30' = [for item in vmListArray: {
  name: '${item}/SetupDnsClient'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${assetLocation}/setuplinuxclient.sh'
        '${assetLocation}/ddns-dhcphook'
      ]
      commandToExecute: 'sh setuplinuxclient.sh ${dnsZone}'
    }
  }
}]