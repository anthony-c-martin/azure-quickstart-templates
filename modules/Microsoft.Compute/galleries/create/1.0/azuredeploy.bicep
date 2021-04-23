@minLength(1)
@maxLength(80)
@description('The name of the Shared Image Gallery. The allowed characters are alphabetic, numeric and periods. The maximum length is 80 characters.')
param galleryName string = 'shared.gallery.${replace(location, ' ', '')}'

@description('Location of the Shared Image Gallery.')
param location string = resourceGroup().location

@description('The description of this Shared Image Gallery resource. This property is updatable.')
param description string = 'Sample Description'

resource galleryName_resource 'Microsoft.Compute/galleries@2019-12-01' = {
  name: galleryName
  location: location
  properties: {
    description: description
  }
}

output galleryName string = galleryName
output location string = location