param accountName string {
  metadata: {
    description: 'The name for your Azure Maps account. This value must be globally unique.'
  }
  default: uniqueString(resourceGroup().id)
}
param pricingTier string {
  allowed: [
    'S0'
    'S1'
  ]
  metadata: {
    description: 'The pricing tier for the account. Use S0 for small-scale development. Use S1 for large-scale applications.'
  }
  default: 'S0'
}

resource accountName_res 'Microsoft.Maps/accounts@2020-02-01-preview' = {
  name: accountName
  location: 'global'
  tags: {}
  sku: {
    name: pricingTier
  }
}