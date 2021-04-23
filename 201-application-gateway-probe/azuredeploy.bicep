@description('Address prefix for the Virtual Network')
param addressPrefix string = '10.0.0.0/16'

@description('Subnet prefix')
param subnetPrefix string = '10.0.0.0/28'

@allowed([
  'Standard_Small'
  'Standard_Medium'
  'Standard_Large'
])
@description('application gateway size')
param applicationGatewaySize string = 'Standard_Medium'

@allowed([
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
])
@description('Number of instances')
param capacity int = 2

@description('Backend 1')
param backend1 string

@description('Probe Enabled')
param probeEnabled bool = true

@description('Status codes for which the backend is healthy.')
param healthyStatusCodes string

@allowed([
  'http'
  'https'
])
@description('Probe protocol to use.')
param probeProtocol string = 'http'

@description('Host header to send to the backend.')
param probeHost string

@description('Path invoked on the backend.')
param probePath string

@description('Interval between probes in seconds.')
param probeIntervalInSeconds int

@description('Timeout of a probe request in seconds.')
param probeTimeoutInSeconds int

@description('Maximum number of probe attempts until a backend is marked unhealthy.')
param probeUnhealthyThreshold int

@description('If set to true the host will be taken from the BackendHttpSettings or the backend address if BackendHttpSettings does not specify a custom host header.')
param probePickHostNameFromBackendHttpSettings bool

@description('Minimum number of servers that are kept in healthy state regardless of probe results.')
param probeMinServersAvailable int

@description('Location for all resources.')
param location string = resourceGroup().location

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
      name: applicationGatewaySize
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
              ipAddress: backend1
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
          probeEnabled: probeEnabled
          probe: {
            id: '${applicationGatewayID}/probes/Probe1'
          }
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
    probes: [
      {
        name: 'Probe1'
        properties: {
          protocol: probeProtocol
          path: probePath
          host: probeHost
          interval: probeIntervalInSeconds
          timeout: probeTimeoutInSeconds
          unhealthyThreshold: probeUnhealthyThreshold
          minServers: probeMinServersAvailable
          match: {
            statusCodes: [
              healthyStatusCodes
            ]
          }
          pickHostNameFromBackendHttpSettings: probePickHostNameFromBackendHttpSettings
        }
      }
    ]
  }
  dependsOn: [
    virtualNetworkName
  ]
}