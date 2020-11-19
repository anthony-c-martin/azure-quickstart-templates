param accountName string {
  metadata: {
    description: 'Display name of Text Translation API account'
  }
  default: 'TextTranslation'
}
param SKU string {
  allowed: [
    'F0'
    'S1'
    'S2'
    'S3'
    'S4'
  ]
  metadata: {
    description: 'SKU for Text Translation API'
  }
  default: 'F0'
}

resource accountName_resource 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: accountName
  location: 'global'
  kind: 'TextTranslation'
  sku: {
    name: SKU
  }
  properties: {}
}