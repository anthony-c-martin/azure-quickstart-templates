param publisherEmail string {
  minLength: 1
  metadata: {
    description: 'The email address of the owner of the service'
  }
}
param publisherName string {
  minLength: 1
  metadata: {
    description: 'The name of the owner of the service'
  }
}
param sku string {
  allowed: [
    'Developer'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier of this API Management service'
  }
  default: 'Developer'
}
param skuCount string {
  allowed: [
    '1'
    '2'
  ]
  metadata: {
    description: 'The instance size of this API Management service.'
  }
  default: '1'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var apiManagementServiceName_var = 'apiservice${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName 'Microsoft.ApiManagement/service@2019-12-01' = {
  name: apiManagementServiceName_var
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
  }
}