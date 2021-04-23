@minLength(1)
@description('The email address of the owner of the service')
param publisherEmail string

@minLength(1)
@description('The name of the owner of the service')
param publisherName string

@allowed([
  'Developer'
  'Basic'
  'Standard'
  'Premium'
])
@description('The pricing tier of this API Management service')
param sku string = 'Developer'

@description('The instance size of this API Management service.')
param skuCount int = 1

@description('Proxy Custom hostname.')
param proxyCustomHostname string

@description('The base 64 encoded certificate issued to domain of the proxy custom hostname.')
param proxyCustomHostnameBase64EncodedPfxCertificate string

@description('Certificate Password.')
param proxySSLCertificatePassword string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var apiManagementServiceName_var = 'apiservice1${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName 'Microsoft.ApiManagement/service@2018-01-01' = {
  name: apiManagementServiceName_var
  location: location
  tags: {}
  sku: {
    name: sku
    capacity: skuCount
  }
  properties: {
    publisherEmail: publisherEmail
    publisherName: publisherName
    hostnameConfigurations: [
      {
        type: 'Proxy'
        hostName: proxyCustomHostname
        encodedCertificate: proxyCustomHostnameBase64EncodedPfxCertificate
        certificatePassword: proxySSLCertificatePassword
        negotiateClientCertificate: false
      }
    ]
  }
}