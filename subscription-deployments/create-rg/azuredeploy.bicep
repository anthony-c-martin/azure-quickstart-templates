targetScope = 'subscription'
param rgName string {
  metadata: {
    description: 'Name of the resourceGroup to create'
  }
}
param rgLocation string {
  metadata: {
    description: 'Location for the resourceGroup'
  }
  default: deployment().location
}

resource rgName_res 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: rgName
  location: rgLocation
  tags: {
    Note: 'subscription level deployment'
  }
  properties: {}
}