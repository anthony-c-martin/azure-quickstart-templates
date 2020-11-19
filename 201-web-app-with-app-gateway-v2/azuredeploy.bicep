param webAppName string = 'myWebApp'
param virtualNetworkName string = 'myVirtualNetwork'
param appGatewaySubnetName string = 'myAppGatewaySubnet'
param appGatewayName string = 'myAppGateway'
param location string = resourceGroup().location

var location_variable = location
var virtualNetworkName_variable = '${virtualNetworkName}-${uniqueString(resourceGroup().id)}'
var virtualNetworkAddressPrefix = '10.0.0.0/20'
var virtualNetworkSubnetName = appGatewaySubnetName
var virtualNetworkSubnetPrefix = '10.0.0.0/24'
var virtualNetworkId = virtualNetworkName_resource.id
var virtualNetworkSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_variable, virtualNetworkSubnetName)
var publicIpAddressName = 'myAppGatewayPublicIp-${uniqueString(resourceGroup().id)}'
var publicIpAddressSku = 'Standard'
var publicIpAddressAllocationType = 'Static'
var publicIpAddressId = publicIpAddressName_resource.id
var webAppName_variable = '${webAppName}-${uniqueString(resourceGroup().id)}'
var webAppPlanName = '${webAppName}Plan-${uniqueString(resourceGroup().id)}'
var webAppPlanSku = 'S1'
var webAppPlanId = webAppPlanName_resource.id
var applicationGatewayName = '${appGatewayName}-${uniqueString(resourceGroup().id)}'
var applicationGatewaySkuSize = 'Standard_v2'
var applicationGatewayTier = 'Standard_v2'
var applicationGatewayAutoScaleMinCapacity = 2
var applicationGatewayAutoScaleMaxCapacity = 5
var appGwIpConfigName = 'appGatewayIpConfigName'
var appGwFrontendPortName = 'appGatewayFrontendPort_80'
var appGwFrontendPort = 80
var appGwFrontendPortId = resourceId('Microsoft.Network/applicationGateways/frontendPorts/', applicationGatewayName, appGwFrontendPortName)
var appGwFrontendIpConfigName = 'appGatewayPublicFrontendIpConfig'
var appGwFrontendIpConfigId = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations/', applicationGatewayName, appGwFrontendIpConfigName)
var appGwHttpSettingName = 'appGatewayHttpSetting_80'
var appGwHttpSettingId = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', applicationGatewayName, appGwHttpSettingName)
var appGwHttpSettingProbeName = 'appGatewayHttpSettingProbe_80'
var appGwBackendAddressPoolName = 'appGateway${webAppName_variable}BackendPool'
var appGwBackendAddressPoolId = resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', applicationGatewayName, appGwBackendAddressPoolName)
var appGwListenerName = 'appGatewayListener'
var appGwListenerId = resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGatewayName, appGwListenerName)
var appGwRoutingRuleName = 'appGatewayRoutingRule'

resource virtualNetworkName_resource 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName_variable
  location: location_variable
  properties: {
    addressSpace: {
      addressPrefixes: [
        virtualNetworkAddressPrefix
      ]
    }
    subnets: [
      {
        name: virtualNetworkSubnetName
        properties: {
          addressPrefix: virtualNetworkSubnetPrefix
          serviceEndpoints: [
            {
              service: 'Microsoft.Web'
              locations: [
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}

resource webAppPlanName_resource 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: webAppPlanName
  location: location_variable
  properties: {
    reserved: 'false'
  }
  sku: {
    name: webAppPlanSku
    capacity: 1
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName_variable
  location: location_variable
  properties: {
    serverFarmId: webAppPlanId
    reserved: 'false'
    siteConfig: {
      http20Enabled: 'true'
      minTlsVersion: '1.2'
      ipSecurityRestrictions: [
        {
          vnetSubnetResourceId: virtualNetworkSubnetId
          action: 'Allow'
          tag: 'Default'
          priority: 200
          name: 'appGatewaySubnet'
          description: 'Isolate traffic to subnet containing Azure Application Gateway'
        }
      ]
    }
    httpsOnly: 'false'
  }
  dependsOn: [
    webAppPlanId
    virtualNetworkId
  ]
}

resource publicIpAddressName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIpAddressName
  location: location_variable
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressAllocationType
    dnsSettings: {
      domainNameLabel: toLower(webAppName_variable)
    }
  }
}

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName
  location: location_variable
  properties: {
    sku: {
      name: applicationGatewaySkuSize
      tier: applicationGatewayTier
    }
    gatewayIPConfigurations: [
      {
        name: appGwIpConfigName
        properties: {
          subnet: {
            id: virtualNetworkSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: appGwFrontendIpConfigName
        properties: {
          PublicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFrontendPortName
        properties: {
          Port: appGwFrontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBackendAddressPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: reference(webAppName_variable).hostNames[0]
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appGwHttpSettingName
        properties: {
          Port: 80
          Protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 20
          pickHostNameFromBackendAddress: true
        }
      }
    ]
    httpListeners: [
      {
        name: appGwListenerName
        properties: {
          frontendIPConfiguration: {
            id: appGwFrontendIpConfigId
          }
          frontendPort: {
            id: appGwFrontendPortId
          }
          protocol: 'Http'
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: appGwRoutingRuleName
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: appGwListenerId
          }
          backendAddressPool: {
            id: appGwBackendAddressPoolId
          }
          backendHttpSettings: {
            id: appGwHttpSettingId
          }
        }
      }
    ]
    enableHttp2: true
    probes: [
      {
        name: appGwHttpSettingProbeName
        properties: {
          backendHttpSettings: [
            {
              id: appGwHttpSettingId
            }
          ]
          interval: 30
          minServers: 0
          path: '/'
          protocol: 'Http'
          timeout: 30
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: true
        }
      }
    ]
    autoscaleConfiguration: {
      minCapacity: applicationGatewayAutoScaleMinCapacity
      maxCapacity: applicationGatewayAutoScaleMaxCapacity
    }
  }
  dependsOn: [
    publicIpAddressId
    virtualNetworkId
  ]
}

output appGatewayUrl string = 'http://${reference(publicIpAddressName).dnsSettings.fqdn}/'
output webAppUrl string = 'http://${reference(webAppName_variable).hostNames[0]}/'