@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/glassfish-on-suse/'

@description('Naming prefix applied to the deployed VM resources')
param vmPrefix string

@minValue(1)
@maxValue(10)
@description('Number of VMs')
param numberOfInstances int

@minValue(3)
@allowed([
  3
  4
])
@description('Release number for the GlassFish package to be deployed')
param glassfishVersion int

@allowed([
  '3.1.1'
  '3.1.2'
  '3.1.2.2'
  '3.2'
  '4.0'
  '4.1'
])
@description('Version of GlassFish to deploy')
param glassfishRelease string

@description('GlassFish admin user password')
@secure()
param glassfishAdminPassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var location_var = location
var deploymentScriptFolder = 'scripts/'
var deploymentScriptFileName = 'deployGlassFish.sh'
var deploymentScriptUrl = concat(artifactsLocation, deploymentScriptFolder, deploymentScriptFileName)

resource vmPrefix_deployGlassFish 'Microsoft.Compute/virtualMachines/extensions@2015-06-15' = [for i in range(0, numberOfInstances): {
  name: '${vmPrefix}${i}/deployGlassFish'
  location: location_var
  tags: {
    displayName: 'deployGlassFish'
  }
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.0'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        deploymentScriptUrl
      ]
      commandToExecute: 'sudo bash ${deploymentScriptFileName} ${glassfishVersion} ${glassfishRelease} ${glassfishAdminPassword}'
    }
  }
}]