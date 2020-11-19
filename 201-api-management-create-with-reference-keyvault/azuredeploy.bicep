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
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'The pricing tier of this API Management service'
  }
  default: 'Developer'
}
param skuCount int {
  metadata: {
    description: 'The instance size of this API Management service.'
  }
  default: 1
}
param proxyCustomHostname string {
  metadata: {
    description: 'Proxy Custom hostname.'
  }
}
param proxyCustomHostnameBase64EncodedPfxCertificate string {
  metadata: {
    description: 'The base 64 encoded certificate issued to domain of the proxy custom hostname.'
  }
}
param proxySSLCertificatePassword string {
  metadata: {
    description: 'Certificate Password.'
  }
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var apiManagementServiceName = 'apiservice1${uniqueString(resourceGroup().id)}'

resource apiManagementServiceName_resource 'Microsoft.ApiManagement/service@2018-01-01' = {
  name: apiManagementServiceName
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