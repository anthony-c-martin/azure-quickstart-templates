@minLength(1)
@description('List of virtual machines to be configured.  If using multiple VMs, make their names comma separate, e.g. VM01,VM02,VM03.')
param vmList string

@description('Name of the forward dnsZone to configure for updates')
param dnsZone string

@description('Name of the vnet for which to create the reverse DNS zone')
param vnetName string

@description('This is the relative location of the folder the script will be downloaded to by the plugin.  This is dictated by the plugin here: https://docs.microsoft.com/en-us/azure/virtual-machines/virtual-machines-windows-extensions-customscript')
param relativeDownloadFolder string

@description('The location of resources such as templates and scripts that the script is dependent')
param assetLocation string

@description('Location for all resources.')
param location string = resourceGroup().location

var vmListArray = split(replace(vmList, ' ', ''), ',')
var vnetID = resourceId('Microsoft.Network/virtualNetworks/', vnetName)

resource vmListArray_SetupDnsServer 'Microsoft.Compute/virtualMachines/extensions@2016-08-30' = [for item in vmListArray: {
  name: '${item}/SetupDnsServer'
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.8'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        '${assetLocation}/setupserver.ps1'
      ]
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File ${relativeDownloadFolder}/setupserver.ps1 ${dnsZone} ${reference(vnetID, '2016-12-01').addressSpace.addressPrefixes[0]}'
    }
  }
}]