@description('vm name')
param vmname string

@description('OS type (windows, linux)')
param ostype string = 'windows'

@description('url of the application module to install on all nodes')
param moduleName string = ''

@description('resources location')
param location string

@description('base URL of deployment resources (template,subtemplates,scripts)')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.')
@secure()
param artifactsLocationSasToken string = ''

var cfgModuleuri = concat(uri(artifactsLocation, 'scripts/cfgMirror.ps1'), artifactsLocationSasToken)
var properties = {
  windows: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.9'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        cfgModuleuri
      ]
    }
    protectedSettings: {
      commandToExecute: 'powershell -ExecutionPolicy Unrestricted -File  .\\cfgMirror.ps1 -safekitcmd C:/safekit/safekit -safekitmod C:/safekit/modules -MName "${moduleName}"'
    }
  }
  linux: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      skipDos2Unix: false
      timestamp: 1
      fileUris: [
        cfgModuleuri
      ]
    }
    protectedSettings: {
      commandToExecute: 'pwsh ./cfgMirror.ps1 -safekitcmd /opt/safekit/safekit -safekitmod /opt/safekit/modules -MName "${moduleName}"'
    }
  }
}

resource vmname_safekit 'Microsoft.Compute/virtualMachines/extensions@2018-06-01' = {
  name: '${vmname}/safekit'
  location: location
  properties: properties[ostype]
}