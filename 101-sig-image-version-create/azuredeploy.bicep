@description('Resource ID of the source managed image.')
param sourceManagedImageResourceId string

@description('Name of the Shared Image Gallery.')
param galleryName string

@description('Name of the Image Definition.')
param galleryImageDefinitionName string

@description('Name of the Image Version - should follow <MajorVersion>.<MinorVersion>.<Patch>.')
param galleryImageVersionName string

resource galleryName_galleryImageDefinitionName_galleryImageVersionName 'Microsoft.Compute/galleries/images/versions@2018-06-01' = {
  name: '${galleryName}/${galleryImageDefinitionName}/${galleryImageVersionName}'
  location: resourceGroup().location
  properties: {
    publishingProfile: {
      replicaCount: 1
      targetRegions: [
        {
          name: 'canadacentral'
        }
        {
          name: 'eastus'
        }
        {
          name: 'eastus2'
        }
        {
          name: 'northcentralus'
        }
        {
          name: 'northeurope'
          regionalReplicaCount: 2
        }
        {
          name: 'southcentralus'
        }
        {
          name: 'westcentralus'
        }
        {
          name: 'westus'
        }
        {
          name: 'westus2'
        }
      ]
      source: {
        managedImage: {
          id: sourceManagedImageResourceId
        }
      }
      excludeFromLatest: 'false'
      endOfLifeDate: '2020-05-01'
    }
  }
}