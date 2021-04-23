@description('Name of the Azure Relay namespace')
param nameSpace string

@description('Location for all resources.')
param location string = resourceGroup().location

resource nameSpace_resource 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: nameSpace
  location: location
  kind: 'Relay'
  properties: {}
}