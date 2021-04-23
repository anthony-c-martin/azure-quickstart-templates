@allowed([
  'WAF_Medium'
  'WAF_Large'
])
@description('application gateway size')
param applicationGatewaySize string = 'WAF_Medium'

@minValue(2)
@maxValue(10)
@description('Number of instances')
param capacity int = 2

@description('WAF Enabled')
param wafEnabled bool = true

@allowed([
  'Detection'
  'Prevention'
])
@description('WAF Mode')
param wafMode string = 'Detection'

@allowed([
  'OWASP'
])
@description('WAF Rule Set Type')
param wafRuleSetType string = 'OWASP'

@allowed([
  '2.2.9'
  '3.0'
])
@description('WAF Rule Set Version')
param wafRuleSetVersion string = '3.0'
param applicationGatewayName string
param publicIPRef string
param frontendPorts array
param gatewayIPConfigurations array
param backendAddressPools array
param backendHttpSettingsCollection array
param httpListeners array
param requestRoutingRules array
param probes array
param omsWorkspaceResourceId string
param location string = resourceGroup().location

resource applicationGatewayName_resource 'Microsoft.Network/applicationGateways@2018-06-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: applicationGatewaySize
      tier: 'WAF'
      capacity: capacity
    }
    gatewayIPConfigurations: gatewayIPConfigurations
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
    frontendPorts: frontendPorts
    backendAddressPools: backendAddressPools
    backendHttpSettingsCollection: backendHttpSettingsCollection
    httpListeners: httpListeners
    requestRoutingRules: requestRoutingRules
    webApplicationFirewallConfiguration: {
      enabled: wafEnabled
      firewallMode: wafMode
      ruleSetType: wafRuleSetType
      ruleSetVersion: wafRuleSetVersion
      disabledRuleGroups: []
    }
    probes: probes
    sslPolicy: {
      disabledSslProtocols: [
        'TLSv1_0'
        'TLSv1_1'
      ]
    }
  }
}

resource applicationGatewayName_Microsoft_Insights_service 'Microsoft.Network/applicationGateways/providers/diagnosticSettings@2017-05-01-preview' = {
  name: '${applicationGatewayName}/Microsoft.Insights/service'
  properties: {
    workspaceId: omsWorkspaceResourceId
    logs: [
      {
        category: 'ApplicationGatewayAccessLog'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: true
        }
      }
      {
        category: 'ApplicationGatewayPerformanceLog'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: false
        }
      }
      {
        category: 'ApplicationGatewayFirewallLog'
        enabled: true
        retentionPolicy: {
          days: 90
          enabled: false
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    applicationGatewayName_resource
  ]
}