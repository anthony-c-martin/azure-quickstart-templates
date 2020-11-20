param cognitiveServiceName string {
  metadata: {
    description: 'That name is the name of our application. It has to be unique.Type a name followed by your resource group name. (<name>-<resourceGroupName>)'
  }
  default: 'CognitiveService-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param sku string {
  allowed: [
    'S0'
  ]
  default: 'S0'
}

resource cognitiveServiceName_res 'Microsoft.CognitiveServices/accounts@2017-04-18' = {
  name: cognitiveServiceName
  location: location
  sku: {
    name: sku
  }
  kind: 'CognitiveServices'
  properties: {
    statisticsEnabled: false
  }
}