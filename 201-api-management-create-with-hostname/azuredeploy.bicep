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
  default: 'Premium'
}
param skuCount int {
  metadata: {
    description: 'The instance size of this API Management service.'
  }
  default: 1
}
param proxyCustomHostname1 string {
  metadata: {
    description: 'Proxy Custom hostname 1.'
  }
}
param proxyCustomHostnameBase64EncodedPfxCertificate1 string {
  metadata: {
    description: 'Base-64 encoded SSL .pfx Certificate for proxy custom hostname.'
  }
  secure: true
}
param proxySSLCertificatePassword1 string {
  metadata: {
    description: 'Proxy SSL certificate password.'
  }
  secure: true
}
param proxyCustomHostname2 string {
  metadata: {
    description: 'Proxy Custom hostname.'
  }
}
param proxyCustomHostnameBase64EncodedPfxCertificate2 string {
  metadata: {
    description: 'Base-64 encoded SSL .pfx Certificate for proxy custom hostname.'
  }
  secure: true
}
param proxySSLCertificatePassword2 string {
  metadata: {
    description: 'Proxy SSL certificate password.'
  }
  secure: true
}
param portalCustomHostname string {
  metadata: {
    description: 'Portal Custom hostname.'
  }
}
param portalCustomHostnameBase64EncodedPfxCertificate string {
  metadata: {
    description: 'Base-64 encoded SSL .pfx Certificate for portal custom hostname.'
  }
  secure: true
}
param portalSSLCertificatePassword string {
  metadata: {
    description: 'Portal SSL certificate password.'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

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