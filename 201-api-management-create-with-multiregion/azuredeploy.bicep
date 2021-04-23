@description('Name of the API Management service.')
param apiManagementServiceName string = 'apiservice${uniqueString(resourceGroup().id)}'

@minLength(1)
@description('The email address of the owner of the service')
param publisherEmail string

@minLength(1)
@description('The name of the owner of the service')
param publisherName string

@description('The pricing tier of this API Management service')
param sku string = 'Premium'

@description('The instance size of this API Management service.')
param skuCount int = 1

@description('Location of the primary region of API Management service.')
param location string = resourceGroup().location

@description('Additional Locations to setup the ApiManagement gateway.')
param additionalLocations array = [
  'East US'
  'South Central US'
]

@description('Ability to enable/disable Gateway proxy in any region including primary region.')
param disableGatewayInAdditionalLocation bool = false

@allowed([
  '2019-01-01'
  '2019-12-01'
  '2020-06-01-preview'
])
@description('Minimum Api-Version to allow on all clients to Control Plane to prevent users with read-only permissions from accessing service secrets.')
param minApiVersionToAllowOnControlPlane string = '2019-12-01'

resource apiManagementServiceName_resource 'Microsoft.ApiManagement/service@2019-12-01' = {
  name: apiManagementServiceName
  location: location
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    apiVersionConstraint: {
      minApiVersion: minApiVersionToAllowOnControlPlane
    }
    customProperties: {
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_GCM_SHA256': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA256': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA256': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_256_CBC_SHA': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TLS_RSA_WITH_AES_128_CBC_SHA': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Ciphers.TripleDes168': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls10': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Tls11': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Protocols.Ssl30': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls10': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Tls11': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Security.Backend.Protocols.Ssl30': false
      'Microsoft.WindowsAzure.ApiManagement.Gateway.Protocols.Server.Http2': false
    }
    additionalLocations: [for item in additionalLocations: {
      location: item
      sku: {
        name: sku
        capacity: skuCount
      }
      disableGateway: disableGatewayInAdditionalLocation
    }]
  }
}