@description('Display name of Computer Vision API account')
param accountName string = 'computervision'

@allowed([
  'F0'
  'S1'
])
@description('SKU for Computer Vision API')
param SKU string = 'F0'

@description('Location for all resources.')
param location string = resourceGroup().location

resource accountName_resource 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: accountName
  location: location
  kind: 'ComputerVision'
  sku: {
    name: SKU
  }
  properties: {}
}