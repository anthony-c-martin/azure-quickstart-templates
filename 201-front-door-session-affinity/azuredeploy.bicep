@description('The name of the frontdoor resource.')
param frontDoorName string

@description('The hostname of the backend. Must be an IP address or FQDN.')
param backendAddress string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Whether to allow session affinity on this host. Valid options are \'Enabled\' or \'Disabled\'.')
param sessionAffinityEnabledState string

@description('The TTL to use in seconds for session affinity, if applicable.')
param sessionAffinityTtlSeconds int

var frontdoorref = frontDoorName_resource.id
var frontdoorLocation = 'global'

resource frontDoorName_resource 'Microsoft.Network/frontDoors@2018-08-01' = {
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
              id: '${frontdoorref}/frontendEndpoints/frontendEndpoint1'
            }
          ]
          acceptedProtocols: [
            'Http'
          ]
          patternsToMatch: [
            '/*'
          ]
          forwardingProtocol: 'MatchRequest'
          backendPool: {
            id: '${frontdoorref}/backendPools/backendPool1'
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
            id: '${frontdoorref}/loadBalancingSettings/loadBalancingSettings1'
          }
          healthProbeSettings: {
            id: '${frontdoorref}/healthProbeSettings/healthProbeSettings1'
          }
        }
      }
    ]
    frontendEndpoints: [
      {
        name: 'frontendEndpoint1'
        properties: {
          hostName: '${frontDoorName}.azurefd.net'
          sessionAffinityEnabledState: sessionAffinityEnabledState
          sessionAffinityTtlSeconds: sessionAffinityTtlSeconds
        }
      }
    ]
    enabledState: 'Enabled'
  }
}