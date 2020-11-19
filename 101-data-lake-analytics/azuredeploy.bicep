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

resource adlStoreName_resource 'Microsoft.DataLakeStore/accounts@2016-11-01' = {
  name: adlStoreName
  location: location
  properties: {}
}

resource adlAnalyticsName_resource 'Microsoft.DataLakeAnalytics/accounts@2016-11-01' = {
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
  dependsOn: [
    adlStoreName_resource
  ]
}

output adlAnalyticsAccount object = adlAnalyticsName_resource.properties
output adlStoreAccount object = adlStoreName_resource.properties