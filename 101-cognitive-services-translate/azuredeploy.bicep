@description('Display name of Text Translation API account')
param accountName string = 'TextTranslation'

@allowed([
  'F0'
  'S1'
  'S2'
  'S3'
  'S4'
])
@description('SKU for Text Translation API')
param SKU string = 'F0'

resource accountName_resource 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: accountName
  location: 'global'
  kind: 'TextTranslation'
  sku: {
    name: SKU
  }
  properties: {}
}