param nameSpace string {
  metadata: {
    description: 'Name of the Azure Relay namespace'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource nameSpace_res 'Microsoft.Relay/Namespaces@2017-04-01' = {
  name: nameSpace
  location: location
  kind: 'Relay'
  properties: {}
}