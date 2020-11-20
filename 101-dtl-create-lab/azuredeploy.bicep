param newLabName string {
  metadata: {
    description: 'The name of the new lab instance to be created'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource newLabName_res 'Microsoft.DevTestLab/labs@2015-05-21-preview' = {
  name: newLabName
  location: location
}

output labId string = newLabName_res.id