param accountName string {
  metadata: {
    description: 'The name of the Data Lake Store account to create.'
  }
}
param location string {
  metadata: {
    description: 'The location in which to create the Data Lake Store account.'
  }
  default: resourceGroup().location
}

resource accountName_resource 'Microsoft.DataLakeStore/accounts@2016-11-01' = {
  name: accountName
  location: location
  properties: {
    newTier: 'Consumption'
    encryptionState: 'Enabled'
    encryptionConfig: {
      type: 'ServiceManaged'
    }
  }
}