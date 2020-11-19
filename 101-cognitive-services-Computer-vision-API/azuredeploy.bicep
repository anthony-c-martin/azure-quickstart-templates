param accountName string {
  metadata: {
    description: 'Display name of Computer Vision API account'
  }
  default: 'computervision'
}
param SKU string {
  allowed: [
    'F0'
    'S1'
  ]
  metadata: {
    description: 'SKU for Computer Vision API'
  }
  default: 'F0'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource accountName_res 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: accountName
  location: location
  kind: 'ComputerVision'
  sku: {
    name: SKU
  }
  properties: {}
}