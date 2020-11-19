param configStoreName string {
  metadata: {
    description: 'Specifies the name of the app configuration store.'
  }
}
param location string {
  metadata: {
    description: 'Specifies the Azure location where the app configuration store should be created.'
  }
  default: resourceGroup().location
}
param skuName string {
  metadata: {
    description: 'Specifies the SKU of the app configuration store.'
  }
  default: 'standard'
}

resource configStoreName_resource 'Microsoft.AppConfiguration/configurationStores@2019-10-01' = {
  name: configStoreName
  location: location
  sku: {
    name: skuName
  }
}