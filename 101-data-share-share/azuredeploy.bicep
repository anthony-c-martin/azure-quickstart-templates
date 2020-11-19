param account_name string {
  metadata: {
    description: 'Name for your data share account'
  }
  default: 'provider_account'
}
param location string {
  allowed: [
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
  ]
  metadata: {
    description: 'Location for your data share'
  }
  default: resourceGroup().location
}
param share_name string {
  metadata: {
    description: 'Name for your data share'
  }
  default: 'share'
}

resource account_name_resource 'Microsoft.DataShare/accounts@2019-11-01' = {
  name: account_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}

resource account_name_share_name 'Microsoft.DataShare/accounts/shares@2019-11-01' = {
  name: '${account_name}/${share_name}'
  properties: {
    shareKind: 'CopyBased'
  }
  dependsOn: [
    account_name_resource
  ]
}