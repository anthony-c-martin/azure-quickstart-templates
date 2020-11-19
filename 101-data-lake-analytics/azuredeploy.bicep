param adlAnalyticsName string {
  metadata: {
    description: 'The name of the Data Lake Analytics account to create.'
  }
}
param adlStoreName string {
  metadata: {
    description: 'The name of the Data Lake Store account to create.'
  }
}
param location string {
  metadata: {
    description: 'The location in which the resources will be created.'
  }
  default: resourceGroup().location
}

resource adlStoreName_res 'Microsoft.DataLakeStore/accounts@2016-11-01' = {
  name: adlStoreName
  location: location
  properties: {}
}

resource adlAnalyticsName_res 'Microsoft.DataLakeAnalytics/accounts@2016-11-01' = {
  name: adlAnalyticsName
  location: location
  properties: {
    defaultDataLakeStoreAccount: adlStoreName
    dataLakeStoreAccounts: [
      {
        name: adlStoreName
      }
    ]
  }
}

output adlAnalyticsAccount object = adlAnalyticsName_res.properties
output adlStoreAccount object = adlStoreName_res.properties