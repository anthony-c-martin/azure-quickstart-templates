param apiManagementServiceName string {
  metadata: {
    description: 'Name of the API Management service.'
  }
  default: 'apiservice${uniqueString(resourceGroup().id)}'
}
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
param location string {
  metadata: {
    description: 'Location of the primary region of API Management service.'
  }
  default: resourceGroup().location
}
param additionalLocations array {
  metadata: {
    description: 'Additional Locations to setup the ApiManagement gateway.'
  }
  default: [
    'East US'
    'South Central US'
  ]
}
param disableGatewayInAdditionalLocation bool {
  metadata: {
    description: 'Ability to enable/disable Gateway proxy in any region including primary region.'
  }
  default: false
}
param minApiVersionToAllowOnControlPlane string {
  allowed: [
    '2019-01-01'
    '2019-12-01'
    '2020-06-01-preview'
  ]
  metadata: {
    description: 'Minimum Api-Version to allow on all clients to Control Plane to prevent users with read-only permissions from accessing service secrets.'
  }
  default: '2019-12-01'
}

resource apiManagementServiceName_res 'Microsoft.ApiManagement/service@2019-12-01' = {
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
    copy: [
      {
        name: 'additionalLocations'
        count: length(additionalLocations)
        input: {
          location: additionalLocations[copyIndex('additionalLocations')]
          sku: {
            name: sku
            capacity: skuCount
          }
          disableGateway: disableGatewayInAdditionalLocation
        }
      }
    ]
  }
}