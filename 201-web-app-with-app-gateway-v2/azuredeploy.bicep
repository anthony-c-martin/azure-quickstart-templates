param webAppName string = 'myWebApp'
param virtualNetworkName string = 'myVirtualNetwork'
param appGatewaySubnetName string = 'myAppGatewaySubnet'
param appGatewayName string = 'myAppGateway'
param location string = resourceGroup().location

var location_var = location
var virtualNetworkName_var = '${virtualNetworkName}-${uniqueString(resourceGroup().id)}'
var virtualNetworkAddressPrefix = '10.0.0.0/20'
var virtualNetworkSubnetName = appGatewaySubnetName
var virtualNetworkSubnetPrefix = '10.0.0.0/24'
var virtualNetworkId = virtualNetworkName_res.id
var virtualNetworkSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets/', virtualNetworkName_var, virtualNetworkSubnetName)
var publicIpAddressName_var = 'myAppGatewayPublicIp-${uniqueString(resourceGroup().id)}'
var publicIpAddressSku = 'Standard'
var publicIpAddressAllocationType = 'Static'
var publicIpAddressId = publicIpAddressName.id
var webAppName_var = '${webAppName}-${uniqueString(resourceGroup().id)}'
var webAppPlanName_var = '${webAppName}Plan-${uniqueString(resourceGroup().id)}'
var webAppPlanSku = 'S1'
var webAppPlanId = webAppPlanName.id
var applicationGatewayName_var = '${appGatewayName}-${uniqueString(resourceGroup().id)}'
var applicationGatewaySkuSize = 'Standard_v2'
var applicationGatewayTier = 'Standard_v2'
var applicationGatewayAutoScaleMinCapacity = 2
var applicationGatewayAutoScaleMaxCapacity = 5
var appGwIpConfigName = 'appGatewayIpConfigName'
var appGwFrontendPortName = 'appGatewayFrontendPort_80'
var appGwFrontendPort = 80
var appGwFrontendPortId = resourceId('Microsoft.Network/applicationGateways/frontendPorts/', applicationGatewayName_var, appGwFrontendPortName)
var appGwFrontendIpConfigName = 'appGatewayPublicFrontendIpConfig'
var appGwFrontendIpConfigId = resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations/', applicationGatewayName_var, appGwFrontendIpConfigName)
var appGwHttpSettingName = 'appGatewayHttpSetting_80'
var appGwHttpSettingId = resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection/', applicationGatewayName_var, appGwHttpSettingName)
var appGwHttpSettingProbeName = 'appGatewayHttpSettingProbe_80'
var appGwBackendAddressPoolName = 'appGateway${webAppName_var}BackendPool'
var appGwBackendAddressPoolId = resourceId('Microsoft.Network/applicationGateways/backendAddressPools/', applicationGatewayName_var, appGwBackendAddressPoolName)
var appGwListenerName = 'appGatewayListener'
var appGwListenerId = resourceId('Microsoft.Network/applicationGateways/httpListeners/', applicationGatewayName_var, appGwListenerName)
var appGwRoutingRuleName = 'appGatewayRoutingRule'

resource virtualNetworkName_res 'Microsoft.Network/virtualNetworks@2020-05-01' = {
  name: virtualNetworkName_var
  location: location_var
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

resource webAppPlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: webAppPlanName_var
  location: location_var
  properties: {
    reserved: 'false'
  }
  sku: {
    name: webAppPlanSku
    capacity: 1
  }
}

resource webAppName_res 'Microsoft.Web/sites@2020-06-01' = {
  name: webAppName_var
  location: location_var
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

resource publicIpAddressName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: publicIpAddressName_var
  location: location_var
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressAllocationType
    dnsSettings: {
      domainNameLabel: toLower(webAppName_var)
    }
  }
}

resource applicationGatewayName 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: applicationGatewayName_var
  location: location_var
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
          publicIPAddress: {
            id: publicIpAddressId
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: appGwFrontendPortName
        properties: {
          port: appGwFrontendPort
        }
      }
    ]
    backendAddressPools: [
      {
        name: appGwBackendAddressPoolName
        properties: {
          backendAddresses: [
            {
              fqdn: reference(webAppName_var).hostNames[0]
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: appGwHttpSettingName
        properties: {
          port: 80
          protocol: 'Http'
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
        name: appGwRoutingRuleName
        properties: {
          ruleType: 'Basic'
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

output appGatewayUrl string = 'http://${reference(publicIpAddressName_var).dnsSettings.fqdn}/'
output webAppUrl string = 'http://${reference(webAppName_var).hostNames[0]}/'