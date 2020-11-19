param size string {
  allowed: [
    'Standard_Small'
    'Standard_Medium'
    'Standard_Large'
  ]
  metadata: {
    description: 'Application Gateway size/SKU'
  }
  default: 'Standard_Medium'
}
param capacity int {
  metadata: {
    description: 'Application Gateway instance number'
  }
  default: 2
}
param cookieBasedAffinity string {
  allowed: [
    'Enabled'
    'Disabled'
  ]
  metadata: {
    description: 'If cookie-based affinity is enabled the requests from the same client are hitting the same Web server'
  }
  default: 'Disabled'
}
param adminUsername string {
  minLength: 1
  metadata: {
    description: 'User name for the backend Web servers'
  }
}
param adminPassword string {
  metadata: {
    description: 'Password for the backend Web servers'
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
var publicIPAddressName_var = 'testAppGWIP'
var virtualNetworkName_var = 'virtualNetwork1'
var subnetName = 'appGatewaySubnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPRef = publicIPAddressName.id
var applicationGatewayID = applicationGatewayName.id
var backendDnsPrefix = 'backend-'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/28'
var webServerTemplateLocation = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/ubuntu-apache-test-page/'
var webServerTemplateName = 'azuredeploy.json'
var server1TestPage = '<h1 style="color:red;font-size:300%;">This is Server 1</h1>'
var server2TestPage = '<h1 style="color:blue;font-size:300%;">This is Server 2</h1>'
var serverTestPageInfo = '<p>Send next request. If Cookie-based affinity is enabled, clear the cookies to change the backend server.</p><p><strong>Request headers:</strong> <br /><?php $hs = apache_request_headers();foreach($hs as $h => $value){echo "$h: $value <br />\n";}?></p>'

module webServer1 '?' /*TODO: replace with correct path to [concat(variables('webServerTemplateLocation'), '/', variables('webServerTemplateName'))]*/ = {
  name: 'webServer1'
  params: {
    adminUsername: adminUsername
    authenticationType: 'password'
    adminPasswordOrKey: adminPassword
    dnsNameForPublicIP: '${backendDnsPrefix}${uniqueString(reference('Microsoft.Network/publicIPAddresses/${publicIPAddressName_var}').resourceGuid)}-1'
    testPageBody: concat(server1TestPage, serverTestPageInfo)
    testPage: 'index.php'
    testPageTitle: 'Server 1'
    installPHP: true
  }
  dependsOn: [
    publicIPAddressName
  ]
}

module webServer2 '?' /*TODO: replace with correct path to [concat(variables('webServerTemplateLocation'), '/', variables('webServerTemplateName'))]*/ = {
  name: 'webServer2'
  params: {
    adminUsername: adminUsername
    authenticationType: 'password'
    adminPasswordOrKey: adminPassword
    dnsNameForPublicIP: '${backendDnsPrefix}${uniqueString(reference('Microsoft.Network/publicIPAddresses/${publicIPAddressName_var}').resourceGuid)}-2'
    testPageBody: concat(server2TestPage, serverTestPageInfo)
    testPage: 'index.php'
    testPageTitle: 'Server 2'
    installPHP: true
  }
  dependsOn: [
    publicIPAddressName
  ]
}

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
      name: size
      tier: 'Standard'
      capacity: capacity
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
              ipAddress: reference('webServer1').outputs.fqdn.value
            }
            {
              ipAddress: reference('webServer2').outputs.fqdn.value
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
          cookieBasedAffinity: cookieBasedAffinity
          requestTimeout: 30
          requestRoutingRules: [
            {
              id: '${applicationGatewayID}/requestRoutingRules/rule1'
            }
          ]
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
          protocol: 'Http'
          sslCertificate: null
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
  }
}