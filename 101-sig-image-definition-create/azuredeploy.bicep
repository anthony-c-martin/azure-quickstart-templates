param galleryName string {
  metadata: {
    description: 'Name of the Shared Image Gallery.'
  }
}
param galleryImageDefinitionName string {
  metadata: {
    description: 'Name of the Image Definition.'
  }
}
param location string {
  metadata: {
    description: 'Location of the Shared Image Gallery.'
  }
  default: resourceGroup().location
}

resource galleryName_galleryImageDefinitionName 'Microsoft.Compute/galleries/images@2019-12-01' = {
  name: '${galleryName}/${galleryImageDefinitionName}'
  location: location
  properties: {
    description: 'Sample Gallery Image Description'
    osType: 'Linux'
    osState: 'Generalized'
    endOfLifeDate: '2030-01-01'
    identifier: {
      publisher: 'myPublisher'
      offer: 'myOffer'
      sku: 'mySku'
    }
    recommended: {
      vCPUs: {
        min: '1'
        max: '64'
      }
      memory: {
        min: '2048'
        max: '307720'
      }
    }
  }
}