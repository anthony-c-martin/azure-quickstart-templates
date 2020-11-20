param addressPrefix string {
  metadata: {
    description: 'Address prefix for the Virtual Network'
  }
  default: '10.0.0.0/16'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/28'
}
param skuName string {
  allowed: [
    'Standard_Small'
    'Standard_Medium'
    'Standard_Large'
  ]
  metadata: {
    description: 'Sku Name'
  }
  default: 'Standard_Medium'
}
param capacity int {
  metadata: {
    description: 'Number of instances'
  }
  default: 2
}
param backendIpAddress1 string {
  metadata: {
    description: 'IP Address for Backend Server 1'
  }
}
param backendIpAddress2 string {
  metadata: {
    description: 'IP Address for Backend Server 2'
  }
}
param certData string {
  metadata: {
    description: 'Base-64 encoded form of the .pfx file'
  }
  secure: true
}
param certPassword string {
  metadata: {
    description: 'Password for .pfx certificate'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var applicationGatewayName_var = 'applicationGateway1'
var publicIPAddressName_var = 'publicIp1'
var virtualNetworkName_var = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPRef = publicIPAddressName.id
var applicationGatewayID = applicationGatewayName.id

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2017-06-01' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2017-06-01' = {
  name: virtualNetworkName_var
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource applicationGatewayName 'Microsoft.Network/applicationGateways@2017-06-01' = {
  name: applicationGatewayName_var
  location: location
  properties: {
    sku: {
      name: skuName
      tier: 'Standard'
      capacity: capacity
    }
    sslCertificates: [
      {
        name: 'appGatewaySslCert'
        properties: {
          data: certData
          password: certPassword
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          port: 443
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddress1
            }
            {
              ipAddress: backendIpAddress2
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGatewayID}/sslCertificates/appGatewaySslCert'
          }
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpListener'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
        }
      }
    ]
    sslPolicy: {
      policyType: 'Custom'
      minProtocolVersion: 'TLSv1_1'
      cipherSuites: [
        'TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384'
        'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA'
        'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA'
        'TLS_ECDHE_ECDSA_WITH_AES_128_CBC_SHA256'
        'TLS_ECDHE_ECDSA_WITH_AES_256_CBC_SHA384'
        'TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384'
        'TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256'
        'TLS_ECDHE_RSA_WITH_AES_128_CBC_SHA'
        'TLS_ECDHE_RSA_WITH_AES_256_CBC_SHA'
        'TLS_RSA_WITH_AES_256_GCM_SHA384'
        'TLS_RSA_WITH_AES_128_GCM_SHA256'
        'TLS_RSA_WITH_AES_256_CBC_SHA256'
        'TLS_RSA_WITH_AES_128_CBC_SHA256'
        'TLS_RSA_WITH_AES_256_CBC_SHA'
        'TLS_RSA_WITH_AES_128_CBC_SHA'
      ]
    }
  }
  dependsOn: [
    virtualNetworkName
  ]
}