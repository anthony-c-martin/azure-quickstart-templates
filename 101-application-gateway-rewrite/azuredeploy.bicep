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
  metadata: {
    description: 'Sku Name'
  }
  default: 'standard_v2'
}
param backendIpAddress1 string {
  metadata: {
    description: 'IP Address for Backend Server 1'
  }
  default: '10.0.1.10'
}
param applicationGatewayName string {
  metadata: {
    description: 'Application Gateway Name'
  }
  default: '${resourceGroup().name}-appgw'
}
param publicIPAddressName string {
  metadata: {
    description: 'Public IP Address Name'
  }
  default: 'PublicIp'
}
param location string {
  metadata: {
    description: 'The Location For the resources'
  }
  default: resourceGroup().location
}

var virtualNetworkName_var = '${resourceGroup().name}-vnet'

resource publicIPAddressName_res 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'appgw-vm-${uniqueString(resourceGroup().id)}'
    }
  }
}

resource virtualNetworkName 'Microsoft.Network/virtualNetworks@2020-05-01' = {
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
        name: 'subnet1'
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

resource applicationGatewayName_res 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: skuName
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, 'subnet1')
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          publicIPAddress: {
            id: publicIPAddressName_res.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'HttpPort'
        properties: {
          port: 80
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
          pickHostNameFromBackendAddress: true
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGatewayName, 'HttpCustomProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'HttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'HttpPort')
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'HttpRule1'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'HttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
          rewriteRuleSet: {
            id: resourceId('Microsoft.Network/applicationGateways/rewriteRuleSets', applicationGatewayName, 'rewriteRuleSet1')
          }
        }
      }
    ]
    rewriteRuleSets: [
      {
        name: 'RewriteRuleSet1'
        properties: {
          rewriteRules: [
            {
              name: 'RWRule1'
              actionSet: {
                requestHeaderConfigurations: [
                  {
                    headerName: 'Accept-Charset'
                    headerValue: 'utf-8'
                  }
                ]
                responseHeaderConfigurations: [
                  {
                    headerName: 'Content-Type'
                    headerValue: 'text/html; charset=utf-8'
                  }
                ]
              }
            }
          ]
        }
        type: 'Microsoft.Network/applicationGateways/rewriteRuleSets'
      }
    ]
    probes: [
      {
        name: 'HttpCustomProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
          minServers: 0
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
        type: 'Microsoft.Network/applicationGateways/probes'
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}