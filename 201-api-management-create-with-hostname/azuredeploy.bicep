@minLength(1)
@description('The email address of the owner of the service')
param publisherEmail string

@minLength(1)
@description('The name of the owner of the service')
param publisherName string

@allowed([
  'Developer'
  'Standard'
  'Premium'
])
@description('The pricing tier of this API Management service')
param sku string = 'Premium'

@description('The instance size of this API Management service.')
param skuCount int = 1

@description('Proxy Custom hostname 1.')
param proxyCustomHostname1 string

@description('Base-64 encoded SSL .pfx Certificate for proxy custom hostname.')
@secure()
param proxyCustomHostnameBase64EncodedPfxCertificate1 string

@description('Proxy SSL certificate password.')
@secure()
param proxySSLCertificatePassword1 string

@description('Proxy Custom hostname.')
param proxyCustomHostname2 string

@description('Base-64 encoded SSL .pfx Certificate for proxy custom hostname.')
@secure()
param proxyCustomHostnameBase64EncodedPfxCertificate2 string

@description('Proxy SSL certificate password.')
@secure()
param proxySSLCertificatePassword2 string

@description('Portal Custom hostname.')
param portalCustomHostname string

@description('Base-64 encoded SSL .pfx Certificate for portal custom hostname.')
@secure()
param portalCustomHostnameBase64EncodedPfxCertificate string

@description('Portal SSL certificate password.')
@secure()
param portalSSLCertificatePassword string

@description('Location for all resources.')
param location string = resourceGroup().location

var apiManagementServiceName_var = 'apiservice${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName 'Microsoft.ApiManagement/service@2017-03-01' = {
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
        hostName: proxyCustomHostname1
        encodedCertificate: proxyCustomHostnameBase64EncodedPfxCertificate1
        certificatePassword: proxySSLCertificatePassword1
        negotiateClientCertificate: false
      }
      {
        type: 'Proxy'
        hostName: proxyCustomHostname2
        encodedCertificate: proxyCustomHostnameBase64EncodedPfxCertificate2
        certificatePassword: proxySSLCertificatePassword2
        negotiateClientCertificate: false
      }
      {
        type: 'Portal'
        hostName: portalCustomHostname
        encodedCertificate: portalCustomHostnameBase64EncodedPfxCertificate
        certificatePassword: portalSSLCertificatePassword
        negotiateClientCertificate: false
      }
    ]
  }
}