@description('The name of your CosmosDB account')
param name string = uniqueString('cosmosdb', resourceGroup().id)

@description('Location for your CosmosDB account')
param location string = resourceGroup().location

@description('CosmosDB account tier')
param tier string = 'Standard'

@description('Enable or disable Advanced Threat Protection.')
param advancedThreatProtectionEnabled bool = true

resource name_resource 'Microsoft.DocumentDB/databaseAccounts@2016-03-31' = {
  name: name
  location: location
  properties: {
    locations: [
      {
        locationName: location
      }
    ]
    databaseAccountOfferType: tier
  }
}

resource name_Microsoft_Security_current 'Microsoft.DocumentDB/databaseAccounts/providers/advancedThreatProtectionSettings@2019-01-01' = if (advancedThreatProtectionEnabled) {
  name: '${name}/Microsoft.Security/current'
  properties: {
    isEnabled: true
  }
  dependsOn: [
    name_resource
  ]
}

output cosmosDbAccountName string = name