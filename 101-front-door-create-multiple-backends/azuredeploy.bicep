param frontDoorName string {
  metadata: {
    description: 'The name of the frontdoor resource.'
  }
}
param backendPools1 object {
  metadata: {
    description: 'Details of the backend pool 1 for the Azure Front Door'
  }
}
param backendPools2 object {
  metadata: {
    description: 'Details of the backend pool 2 for the Azure Front Door'
  }
}

var frontdoorLocation = 'global'

resource frontDoorName_resource 'Microsoft.Network/frontDoors@2019-04-01' = {
  name: frontDoorName
  location: frontdoorLocation
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
            'Https'
          ]
          patternsToMatch: [
            '/*'
            '/site1/*'
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
      {
        name: 'routingRule2'
        properties: {
          frontendEndpoints: [
            {
              id: resourceId('Microsoft.Network/frontDoors/frontendEndpoints', frontDoorName, 'frontendEndpoint1')
            }
          ]
          acceptedProtocols: [
            'Https'
          ]
          patternsToMatch: [
            '/site2/*'
          ]
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            forwardingProtocol: 'MatchRequest'
            backendPool: {
              id: resourceId('Microsoft.Network/frontDoors/backendPools', frontDoorName, 'backendPool2')
            }
          }
          enabledState: 'Enabled'
        }
      }
    ]
    healthProbeSettings: [
      {
        name: 'healthProbeSettings1'
        properties: {
          path: '/'
          protocol: 'Http'
          intervalInSeconds: 120
        }
      }
      {
        name: 'healthProbeSettings2'
        properties: {
          path: '/'
          protocol: 'Https'
          intervalInSeconds: 60
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
      {
        name: 'loadBalancingSettings2'
        properties: {
          sampleSize: 2
          successfulSamplesRequired: 1
        }
      }
    ]
    backendPools: [
      {
        name: backendPools1.name
        properties: {
          copy: [
            {
              name: 'backends'
              count: length(backendPools1.backends)
              input: {
                address: backendPools1.backends[copyIndex('backends')].address
                httpPort: backendPools1.backends[copyIndex('backends')].httpPort
                httpsPort: backendPools1.backends[copyIndex('backends')].httpsPort
                weight: backendPools1.backends[copyIndex('backends')].weight
                priority: backendPools1.backends[copyIndex('backends')].priority
                enabledState: backendPools1.backends[copyIndex('backends')].enabledState
              }
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
      {
        name: backendPools2.name
        properties: {
          copy: [
            {
              name: 'backends'
              count: length(backendPools2.backends)
              input: {
                address: backendPools2.backends[copyIndex('backends')].address
                httpPort: backendPools2.backends[copyIndex('backends')].httpPort
                httpsPort: backendPools2.backends[copyIndex('backends')].httpsPort
                weight: backendPools2.backends[copyIndex('backends')].weight
                priority: backendPools2.backends[copyIndex('backends')].priority
                enabledState: backendPools2.backends[copyIndex('backends')].enabledState
              }
            }
          ]
          loadBalancingSettings: {
            id: resourceId('Microsoft.Network/frontDoors/loadBalancingSettings', frontDoorName, 'loadBalancingSettings2')
          }
          healthProbeSettings: {
            id: resourceId('Microsoft.Network/frontDoors/healthProbeSettings', frontDoorName, 'healthProbeSettings2')
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