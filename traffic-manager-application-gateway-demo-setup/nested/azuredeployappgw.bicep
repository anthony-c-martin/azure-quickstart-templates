@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
])
@description('Application Gateway size/SKU')
param size string = 'Standard_Medium'

@description('Application Gateway instance number')
param capacity int = 2

@allowed([
  'Enabled'
  'Disabled'
])
@description('If cookie-based affinity is enabled the requests from the same client are hitting the same Web server')
param cookieBasedAffinity string = 'Disabled'

@minLength(1)
@description('User name for the backend Web servers')
param adminUsername string

@description('Password for the backend Web servers')
@secure()
param adminPassword string

@allowed([
  'East Asia'
  'Southeast Asia'
  'Central US'
  'East US'
  'East US 2'
  'West US'
  'North Central US'
  'South Central US'
  'North Europe'
  'West Europe'
  'Japan West'
  'Japan East'
  'Brazil South'
  'Australia East'
  'Australia Southeast'
  'South India'
  'Central India'
  'West India'
  'Canada Central'
  'Canada East'
])
@description('Location of resources')
param location string

@minLength(1)
@description('Name for Application Gateway')
param appGwName string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string

var applicationGatewayName_var = appGwName
var publicIPAddressName_var = '${appGwName}IP'
var virtualNetworkName_var = '${appGwName}VNet'
var subnetName = '${appGwName}Subnet'
var subnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName_var, subnetName)
var publicIPRef = publicIPAddressName.id
var applicationGatewayID = applicationGatewayName.id
var backendDnsPrefix = '${appGwName}-backend-'
var wsDeploymentName = '${appGwName}ws'
var appGatewayIPConfigName = '${appGwName}-ipconfig'
var appGatewayrequestRoutingRuleName = '${appGwName}-rule1'
var appGatewayHttpListenerName = '${appGwName}-listener'
var appGatewayBackendHttpSettingsName = '${appGwName}-httpsettings'
var appGatewayBackendPoolName = '${appGwName}-backendpool'
var appGatewayFrontendPortName = '${appGwName}-port'
var appGatewayFrontendIPConfigName = '${appGwName}-ipconfig'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/28'
var nestedTemplatesFolder = 'nested'
var webServerTemplateName = 'azuredeploywebserver.json'
var serverTestPage = [
  '<h1 style="color:red;font-size:300%;">This is Server 1, Location: ${location}</h1>'
  '<h1 style="color:blue;font-size:300%;">This is Server 2, Location: ${location}</h1>'
]
var serverTestPageInfo = '<p>Send next request. If Cookie-based affinity is enabled, clear the cookies to change the backend server.</p><p><strong>Request headers:</strong> <br /><?php $hs = apache_request_headers();foreach($hs as $h => $value){echo "$h: $value <br />\n";}?></p>'

module wsDeploymentName_1 'nested/azuredeploywebserver.bicep' = [for i in range(0, 2): {
  name: concat(wsDeploymentName, (i + 1))
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    dnsNameForPublicIP: '${backendDnsPrefix}${uniqueString(reference('Microsoft.Network/publicIPAddresses/${publicIPAddressName_var}').resourceGuid)}-${(i + 1)}'
    testPageBody: concat(serverTestPage[i], serverTestPageInfo)
    testPage: 'index.php'
    testPageTitle: 'Server ${(i + 1)}'
    installPHP: true
    location: location
  }
  dependsOn: [
    publicIPAddressName
  ]
}]

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
        name: appGatewayIPConfigName
        properties: {
          subnet: {
            id: subnetRef
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appGatewayFrontendIPConfigName
        properties: {
          publicIPAddress: {
            id: publicIPRef
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGatewayFrontendPortName
        properties: {
          port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGatewayBackendPoolName
        properties: {
          backendAddresses: [
            {
              ipAddress: reference('${wsDeploymentName}1').outputs.fqdn.value
            }
            {
              ipAddress: reference('${wsDeploymentName}2').outputs.fqdn.value
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appGatewayBackendHttpSettingsName
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: cookieBasedAffinity
          requestTimeout: 30
          requestRoutingRules: [
            {
              id: '${applicationGatewayID}/requestRoutingRules/${appGatewayrequestRoutingRuleName}'
            }
          ]
        }
      }
    ]
    httpListeners: [
      {
        name: appGatewayHttpListenerName
        properties: {
          frontendIPConfiguration: {
            id: '${applicationGatewayID}/frontendIPConfigurations/${appGatewayFrontendIPConfigName}'
          }
          frontendPort: {
            id: '${applicationGatewayID}/frontendPorts/${appGatewayFrontendPortName}'
          }
          protocol: 'Http'
          sslCertificate: null
        }
      }
    ]
    requestRoutingRules: [
      {
        name: appGatewayrequestRoutingRuleName
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: '${applicationGatewayID}/httpListeners/${appGatewayHttpListenerName}'
          }
          backendAddressPool: {
            id: '${applicationGatewayID}/backendAddressPools/${appGatewayBackendPoolName}'
          }
          backendHttpSettings: {
            id: '${applicationGatewayID}/backendHttpSettingsCollection/${appGatewayBackendHttpSettingsName}'
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName

    wsDeploymentName_1
  ]
}

output ipId string = publicIPAddressName.id