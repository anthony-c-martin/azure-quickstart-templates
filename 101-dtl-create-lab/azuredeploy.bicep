@description('The name of the new lab instance to be created')
param newLabName string

@description('Location for all resources.')
param location string = resourceGroup().location

resource newLabName_resource 'Microsoft.DevTestLab/labs@2015-05-21-preview' = {
  name: newLabName
  location: location
}

output labId string = newLabName_resource.id