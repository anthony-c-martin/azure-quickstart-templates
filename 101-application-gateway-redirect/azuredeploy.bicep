param virtualNetworkName string {
  metadata: {
    description: 'virtual network name'
  }
}
param vnetAddressPrefix string {
  metadata: {
    description: 'virtual network address range'
  }
  default: '10.0.0.0/16'
}
param subnetName string {
  metadata: {
    description: 'Subnet Name'
  }
  default: 'subnet1'
}
param subnetPrefix string {
  metadata: {
    description: 'Subnet prefix'
  }
  default: '10.0.0.0/24'
}
param applicationGatewayName string {
  metadata: {
    description: 'application gateway name'
  }
  default: 'applicationGateway1'
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
    description: 'application gateway instance count'
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
param pathMatch1 string {
  metadata: {
    description: 'Path match string for Path Rule 1'
  }
}
param certData string {
  metadata: {
    description: 'Base-64 encoded form of the .pfx file'
  }
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

var publicIPAddressName = 'publicIp${applicationGatewayName}'

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
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

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          PublicIPAddress: {
            id: publicIPAddressName_resource.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendHttpPort1'
        properties: {
          Port: 80
        }
      }
      {
        name: 'appGatewayFrontendHttpsPort1'
        properties: {
          Port: 443
        }
      }
      {
        name: 'appGatewayFrontendHttpPort2'
        properties: {
          Port: 8080
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool1'
        properties: {
          BackendAddresses: [
            {
              IpAddress: backendIpAddress1
            }
          ]
        }
      }
      {
        name: 'appGatewayBackendPool2'
        properties: {
          BackendAddresses: [
            {
              IpAddress: backendIpAddress2
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener1'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendHttpPort1')
          }
          Protocol: 'Http'
        }
      }
      {
        name: 'appGatewayHttpsListener1'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendHttpsPort1')
          }
          Protocol: 'Https'
          SslCertificate: {
            id: resourceId('Microsoft.Network/applicationGateways/sslCertificates', applicationGatewayName, 'appGatewaySslCert')
          }
        }
      }
      {
        name: 'appGatewayHttpListener2'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendHttpPort2')
          }
          Protocol: 'Http'
        }
      }
    ]
    redirectConfigurations: [
      {
        Name: 'redirectConfig1'
        properties: {
          redirectType: 'Temporary'
          targetListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpsListener1')
          }
        }
      }
      {
        Name: 'redirectConfig2'
        properties: {
          redirectType: 'Temporary'
          targetUrl: 'http://www.bing.com'
        }
      }
    ]
    urlPathMaps: [
      {
        name: 'urlPathMap1'
        properties: {
          defaultRedirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'redirectConfig2')
          }
          pathRules: [
            {
              name: 'pathRule1'
              properties: {
                paths: [
                  pathMatch1
                ]
                redirectConfiguration: {
                  id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'redirectConfig1')
                }
              }
            }
          ]
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener1')
          }
          redirectConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', applicationGatewayName, 'redirectConfig1')
          }
        }
      }
      {
        Name: 'rule2'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGatewayName, 'appGatewayHttpsListener1')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', applicationGatewayName, 'appGatewayBackendPool1')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
      {
        Name: 'rule3'
        properties: {
          RuleType: 'PathBasedRouting'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGatewayName, 'appGatewayHttpListener2')
          }
          urlPathMap: {
            id: resourceId('Microsoft.Network/applicationGateways/urlPathMaps/', applicationGatewayName, 'urlPathMap1')
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPAddressName_resource
  ]
}