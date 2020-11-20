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

var applicationGatewayName_var = 'applicationGateway1'
var publicIPAddressName_var = 'publicIp1'
var virtualNetworkName_var = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPRef = publicIPAddressName.id
var applicationGatewayID = applicationGatewayName.id

resource publicIPAddressName 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: publicIPAddressName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2015-06-15' = {
  name: virtualNetworkName_var
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
        name: 'appGatewayBackendPool1'
        properties: {
          backendAddresses: [
            {
              ipAddress: backendIpAddress1
            }
          ]
        }
      }
      {
        name: 'appGatewayBackendPool2'
        properties: {
          backendAddresses: [
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
        name: 'appGatewayHttpListener1'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGatewayID}/sslCertificates/appGatewaySslCert1'
          }
          hostName: hostName1
          requireServerNameIndication: 'true'
        }
      }
      {
        name: 'appGatewayHttpListener2'
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/appGatewayFrontendIP'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/appGatewayFrontendPort'
          }
          protocol: 'Https'
          sslCertificate: {
            id: '${applicationGatewayID}/sslCertificates/appGatewaySslCert2'
          }
          hostName: hostName2
          requireServerNameIndication: 'true'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'rule1'
        properties: {
          ruleType: 'Basic'
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
        name: 'rule2'
        properties: {
          ruleType: 'Basic'
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
    virtualNetworkName
  ]
}