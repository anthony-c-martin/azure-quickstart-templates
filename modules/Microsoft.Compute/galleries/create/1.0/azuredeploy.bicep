param galleryName string {
  minLength: 1
  maxLength: 80
  metadata: {
    description: 'The name of the Shared Image Gallery. The allowed characters are alphabetic, numeric and periods. The maximum length is 80 characters.'
  }
  default: 'shared.gallery.${replace(location, ' ', '')}'
}
param location string {
  metadata: {
    description: 'Location of the Shared Image Gallery.'
  }
  default: resourceGroup().location
}
param description string {
  metadata: {
    description: 'The description of this Shared Image Gallery resource. This property is updatable.'
  }
  default: 'Sample Description'
}

resource galleryName_resource 'Microsoft.Compute/galleries@2019-12-01' = {
  name: galleryName
  location: location
  properties: {
    description: description
  }
}

output galleryName_output string = galleryName
output location_output string = location