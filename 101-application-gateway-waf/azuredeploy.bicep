param location string {
  metadata: {
    description: 'Specifies the location for all resources that is created by this template.'
  }
  default: resourceGroup().location
}
param vNetAddressPrefix string {
  metadata: {
    description: 'Specifies the address prefix for the Virtual Network.'
  }
  default: '10.0.0.0/16'
}
param vNetSubnetPrefix string {
  metadata: {
    description: 'Specifies the subnet prefix'
  }
  default: '10.0.0.0/28'
}
param applicationGatewaySize string {
  allowed: [
    'WAF_v2'
  ]
  metadata: {
    description: 'Specifies the application gateway SKU name.'
  }
  default: 'WAF_v2'
}
param applicationGatewayCapacity int {
  allowed: [
    1
    2
    3
    4
    5
    6
    7
    8
    9
    10
  ]
  metadata: {
    description: 'Specifies the number of the application gateway instances.'
  }
  default: 2
}
param backendIpAddress1 string {
  metadata: {
    description: 'IP Address for Backend Server 1'
  }
  default: '10.0.1.10'
}
param backendIpAddress2 string {
  metadata: {
    description: 'IP Address for Backend Server 2'
  }
  default: '10.0.1.11'
}
param wafEnabled bool {
  metadata: {
    description: 'WAF Enabled'
  }
  default: true
}
param wafMode string {
  allowed: [
    'Detection'
    'Prevention'
  ]
  metadata: {
    description: 'WAF Mode'
  }
  default: 'Detection'
}
param wafRuleSetType string {
  allowed: [
    'OWASP'
  ]
  metadata: {
    description: 'WAF Rule Set Type'
  }
  default: 'OWASP'
}
param wafRuleSetVersion string {
  allowed: [
    '2.2.9'
    '3.0'
  ]
  metadata: {
    description: 'WAF Rule Set Version'
  }
  default: '3.0'
}

var applicationGatewayName = 'applicationGateway1'
var publicIPAddressName = 'publicIp1'
var virtualNetworkName = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName, subnetName)
var publicIPRef = publicIPAddressName_resource.id

resource publicIPAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vNetAddressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: vNetSubnetPrefix
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
      name: applicationGatewaySize
      tier: 'WAF_v2'
      capacity: applicationGatewayCapacity
    }
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
          Port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          BackendAddresses: [
            {
              IpAddress: backendIpAddress1
            }
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
        name: 'appGatewayHttpListener'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGatewayName, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGatewayName, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGatewayName, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGatewayName, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: wafEnabled
      firewallMode: wafMode
      ruleSetType: wafRuleSetType
      ruleSetVersion: wafRuleSetVersion
    }
  }
  dependsOn: [
    virtualNetworkName_resource
    publicIPAddressName_resource
  ]
}