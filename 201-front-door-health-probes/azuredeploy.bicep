param frontDoorName string {
  metadata: {
    description: 'The name of the frontdoor resource.'
  }
}
param backendAddress string {
  metadata: {
    description: 'The hostname of the backend. Must be an IP address or FQDN.'
  }
}
param healthProbeName string {
  metadata: {
    description: 'Name of the Health probe settings associated with this Front Door instance.'
  }
}
param healthProbePath string {
  metadata: {
    description: 'The path to use for the health probe. Default is /'
  }
}
param healthProbeProtocol string {
  allowed: [
    'Http'
    'Https'
  ]
  metadata: {
    description: 'Protocol scheme to use for this probe. Must be Http or Https.'
  }
}
param healthProbeIntervalInSeconds int {
  metadata: {
    description: 'The number of seconds between health probes.'
  }
}

var frontdoorLocation = 'global'

resource frontDoorName_resource 'Microsoft.Network/frontDoors@2019-04-01' = {
  name: frontDoorName
  location: frontdoorLocation
  tags: {}
  properties: {
    routingRules: [
      {
        name: 'routingRule1'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, 'frontendEndpoint1')
            }
          ]
          acceptedProtocols: [
            'Http'
          ]
          patternsToMatch: [
            '/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'MatchRequest'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', frontDoorName, 'backendPool1')
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
    healthProbeSettings: [
      {
        name: healthProbeName
        properties: {
          path: healthProbePath
          protocol: healthProbeProtocol
          intervalInSeconds: healthProbeIntervalInSeconds
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: 'loadBalancingSettings1'
        properties: {
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    backendPools: [
      {
        name: 'backendPool1'
        properties: {
          backends: [
            {
              address: backendAddress
              httpPort: 80
              httpsPort: 443
              weight: 50
              priority: 1
              enabledState: 'Enabled'
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, 'loadBalancingSettings1')
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, 'healthProbeSettings1')
          }
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'frontendEndpoint1'
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
          sessionAffinityEnabledState: 'Disabled'
        }
      }
    ]
    enabledState: 'Enabled'
  }
}