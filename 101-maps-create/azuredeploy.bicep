@description('The name for your Azure Maps account. This value must be globally unique.')
param accountName string = uniqueString(resourceGroup().id)

@allowed([
  'S0'
  'S1'
])
@description('The pricing tier for the account. Use S0 for small-scale development. Use S1 for large-scale applications.')
param pricingTier string = 'S0'

resource accountName_resource 'Microsoft.Maps/accounts@2020-02-01-preview' = {
  name: accountName
  location: 'global'
  tags: {}
  sku: {
    name: pricingTier
  }
}