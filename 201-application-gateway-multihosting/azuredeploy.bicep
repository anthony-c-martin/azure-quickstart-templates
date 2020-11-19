param vnetAddressPrefix string {
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
param hostName1 string {
  metadata: {
    description: 'HostName for listener 1'
  }
}
param hostName2 string {
  metadata: {
    description: 'HostName for listener 2'
  }
}
param certData1 string {
  metadata: {
    description: 'Base-64 encoded form of the .pfx file'
  }
  secure: true
}
param certPassword1 string {
  metadata: {
    description: 'Password for .pfx certificate'
  }
  secure: true
}
param certData2 string {
  metadata: {
    description: 'Base-64 encoded form of the .pfx file'
  }
  secure: true
}
param certPassword2 string {
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

var applicationGatewayName = 'applicationGateway1'
var publicIPAddressName = 'publicIp1'
var virtualNetworkName = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
var publicIPRef = publicIPAddressName_resource.id
var applicationGatewayID = applicationGatewayName_resource.id

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2015-06-15' = {
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

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2017-06-01' = {
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
        name: 'appGatewaySslCert1'
        properties: {
          data: certData1
          password: certPassword1
        }
      }
      {
        name: 'appGatewaySslCert2'
        properties: {
          data: certData2
          password: certPassword2
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
          PublicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: 443
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
          CookieBasedAffinity: 'Disabled'
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener1'
        properties: {
          FrontendIPConfiguration: {
            Id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          FrontendPort: {
            Id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort'
          }
          Protocol: 'Https'
          SslCertificate: {
            Id: '${applicationGatewayID}/sslCertificates/appGatewaySslCert1'
          }
          HostName: hostName1
          RequireServerNameIndication: 'true'
        }
      }
      {
        name: 'appGatewayHttpListener2'
        properties: {
          FrontendIPConfiguration: {
            Id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          FrontendPort: {
            Id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort'
          }
          Protocol: 'Https'
          SslCertificate: {
            Id: '${applicationGatewayID}/sslCertificates/appGatewaySslCert2'
          }
          HostName: hostName2
          RequireServerNameIndication: 'true'
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpListener1'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool1'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
          }
        }
      }
      {
        Name: 'rule2'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/appGatewayHttpListener2'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/appGatewayBackendPool2'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/appGatewayBackendHttpSettings'
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