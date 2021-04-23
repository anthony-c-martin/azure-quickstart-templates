@description('Name of the Shared Image Gallery.')
param galleryName string

@description('Location of the Shared Image Gallery.')
param location string = resourceGroup().location

resource galleryName_resource 'Microsoft.Compute/galleries@2019-12-01' = {
  name: galleryName
  location: location
  properties: {
    description: 'My Private Gallery'
  }
}