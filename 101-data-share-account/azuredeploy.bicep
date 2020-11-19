param account_name string
param location string = resourceGroup().location

resource account_name_res 'Microsoft.DataShare/accounts@2019-11-01' = {
  name: account_name
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {}
}