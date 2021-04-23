@description('Name for your data share account')
param account_name string = 'provider_account'

@allowed([
  'eastus'
  'eastus2'
  'southeastasia'
  'westcentralus'
  'westeurope'
  'westus2'
  'austriliaeast'
  'northeurope'
  'uksouth'
  'usgovvirginia'
  'usgovarizona'
])
@description('Location for your data share')
param location string = resourceGroup().location

@description('Name for your data share')
param share_name string = 'share'

resource account_name_resource 'Microsoft.DataShare/accounts@2019-11-01' = {
  name: account_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

resource account_name_share_name 'Microsoft.DataShare/accounts/shares@2019-11-01' = {
  parent: account_name_resource
  name: '${share_name}'
  properties: {
    shareKind: 'CopyBased'
  }
}