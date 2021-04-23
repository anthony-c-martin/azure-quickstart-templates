@description('Location for the Azure resources.')
param location string = resourceGroup().location

@description('Specifies the Virtual Network configuration.')
param virtualNetwork object = {
  name: 'FrontDoorApimSampleVnet'
  addressPrefixes: [
    '10.0.0.0/16'
  ]
  subnets: [
    {
      name: 'ApiManagementSubnet'
      addressPrefix: '10.0.0.0/24'
      nsg: 'FrontDoorApimSampleNsg'
    }
  ]
}

@description('Name of the Log Analytics workspace')
param workspaceName string

@allowed([
  'PerGB2018'
  'Free'
  'Standalone'
  'PerNode'
  'Standard'
  'Premium'
])
@description('Pricing tier: PerGB2018 or legacy tiers (Free, Standalone, PerNode, Standard or Premium) which are not available to all customers.')
param workspaceSku string = 'Standalone'

@description('The name of your Application Insights resource used by API Management.')
param appInsightsName string

@description('The name of your API Management service.')
param apimServiceName string

@description('The email address of the owner of the service')
param apimPublisherEmail string = 'admin@contoso.com'

@description('The name of the publisher.')
param apimPublisherName string = 'Contoso'

@allowed([
  'Developer'
  'Premium'
])
@description('The pricing tier of this API Management service. Only Developer and Premium are supported when deploying into a shared VNET.')
param apimSku string = 'Developer'

@description('Number of deployed units of the SKU.')
param apimCapacity int = 1

@minLength(5)
@maxLength(64)
@description('Name of the Azure Front Door which is globally unique. Min length: 5. Max length: 64')
param frontDoorName string

@allowed([
  'Enabled'
  'Disabled'
])
@description('Whether to enforce certificate name check on HTTPS requests to all backend pools. No effect on non-HTTPS requests. - Enabled or Disabled')
param frontDoorEnforceCertificateNameCheck string = 'Disabled'

@description('This parameter contains the name and properties of the frontend endpoint.')
param frontDoorFrontendEndpoint object = {
  name: 'MainFrontendEndpoint'
  sessionAffinityEnabledState: 'Disabled'
  sessionAffinityTtlSeconds: 0
}

@description('This parameter contains the name and properties of the Application Gateway Backend Pool')
param frontDoorBackendPool object = {
  name: 'ApimBackendPool'
  loadBalancerName: 'ApimLoadBalancer'
}

@description('This parameter contains the name and properties of the routing rule.')
param frontDoorRoutingRule object = {
  name: 'ApimRoutingRule'
  acceptedProtocols: [
    'Http'
    'Https'
  ]
  patternsToMatch: [
    '/*'
  ]
  customForwardingPath: '/'
  forwardingProtocol: 'MatchRequest'
  cacheConfiguration: {
    queryParameterStripDirective: 'StripNone'
    dynamicCompression: 'Enabled'
  }
}

@description('This parameter contains the name and properties of the health probe settings.')
param frontDoorHealthProbeSettings object = {
  name: 'ApimHealthProbeSettings'
  intervalInSeconds: 30
  path: '/status-0123456789abcdef'
  protocol: 'Https'
}

@description('Specifies whether to deploy a global WAF policy in Front Door.')
param deployWaf bool = true

@description('The name of the WAF policy')
param wafPolicyName string = 'FrontDoorApimSampleWaf'

@allowed([
  'Detection'
  'Prevention'
])
@description('Describes if it is in detection mode or prevention mode at policy level.')
param wafMode string = 'Prevention'

@description('Specifies whether to allow traffic to API Management public endpoints only from Front Door.')
param allowTrafficOnlyFromFrontDoor bool = false

var nsgId = virtualNetwork_subnets_0_nsg.id
var vnetId = virtualNetwork_name.id
var apimId = apimServiceName_resource.id
var appInsightsId = appInsightsName_resource.id
var apimSubnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, virtualNetwork.subnets[0].name)
var workspaceId = workspaceName_resource.id
var loggerId = apimServiceName_appInsightsName.id
var frontDoorId = frontDoorName_resource.id
var frontDoorBackendPoolId = resourceId('Microsoft.Network/frontdoors/backendPools', frontDoorName, frontDoorBackendPool.name)
var frontDoorHealthProbeSettingsId = resourceId('Microsoft.Network/frontdoors/healthProbeSettings', frontDoorName, frontDoorHealthProbeSettings.name)
var frontDoorLoadBalancerId = resourceId('Microsoft.Network/frontdoors/loadBalancingSettings', frontDoorName, frontDoorBackendPool.loadBalancerName)
var frontDoorFrontedEndpointId = resourceId('Microsoft.Network/frontdoors/frontendEndpoints', frontDoorName, frontDoorFrontendEndpoint.name)
var wafPolicyId = wafPolicyName_resource.id
var mockApiId = apimServiceName_mockApi.id
var postmanEchoApiId = apimServiceName_postmanEchoApi.id
var customProductId = apimServiceName_custom.id
var testMethodId = apimServiceName_mockApi_test.id
var frontDoorSuffix = ((toLower(environment().name) == 'azureusgovernment') ? 'azurefd.us' : environment().suffixes.azureFrontDoorEndpointSuffix)
var frontDoorHostName = '${toLower(frontDoorName)}.${frontDoorSuffix}'

resource workspaceName_resource 'Microsoft.OperationalInsights/workspaces@2020-03-01-preview' = {
  name: workspaceName
  location: location
  properties: {
    sku: {
      name: workspaceSku
    }
  }
}

resource virtualNetwork_subnets_0_nsg 'Microsoft.Network/networkSecurityGroups@2019-09-01' = {
  name: virtualNetwork.subnets[0].nsg
  location: location
  properties: {
    securityRules: [
      {
        name: 'ClientCommunicationToAPIManagementInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: (allowTrafficOnlyFromFrontDoor ? 'AzureFrontDoor.Backend' : 'Internet')
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'SecureClientCommunicationToAPIManagementInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: (allowTrafficOnlyFromFrontDoor ? 'AzureFrontDoor.Backend' : 'Internet')
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'ManagementEndpointForAzurePortalAndPowershellInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '3443'
          sourceAddressPrefix: 'ApiManagement'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'DependencyOnRedisCacheInbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6381-6383'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'AzureInfrastructureLoadBalancer'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 180
          direction: 'Inbound'
        }
      }
      {
        name: 'DependencyOnAzureSQLOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '1433'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Sql'
          access: 'Allow'
          priority: 140
          direction: 'Outbound'
        }
      }
      {
        name: 'DependencyForLogToEventHubPolicyOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '5671'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'EventHub'
          access: 'Allow'
          priority: 150
          direction: 'Outbound'
        }
      }
      {
        name: 'DependencyOnRedisCacheOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '6381-6383'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 160
          direction: 'Outbound'
        }
      }
      {
        name: 'DependencyOnAzureFileShareForGitOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 170
          direction: 'Outbound'
        }
      }
      {
        name: 'PublishDiagnosticLogsAndMetricsOutbound'
        properties: {
          description: 'APIM Logs and Metrics for consumption by admins and your IT team are all part of the management plane'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureMonitor'
          access: 'Allow'
          priority: 185
          direction: 'Outbound'
          destinationPortRanges: [
            '443'
            '12000'
            '1886'
          ]
        }
      }
      {
        name: 'ConnectToSmtpRelayForSendingEmailsOutbound'
        properties: {
          description: 'APIM features the ability to generate email traffic as part of the data plane and the management plane'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 190
          direction: 'Outbound'
          destinationPortRanges: [
            '25'
            '587'
            '25028'
          ]
        }
      }
      {
        name: 'AuthenticateToAzureActiveDirectoryOutbound'
        properties: {
          description: 'Connect to Azure Active Directory for Developer Portal Authentication or for Oauth2 flow during any Proxy Authentication'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureActiveDirectory'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'DependencyOnAzureStorageOutbound'
        properties: {
          description: 'APIM service dependency on Azure Blob and Azure Table Storage'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'Storage'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'PublishMonitoringLogsOutbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 300
          direction: 'Outbound'
        }
      }
    ]
  }
}

resource virtualNetwork_name 'Microsoft.Network/virtualNetworks@2020-03-01' = {
  name: virtualNetwork.name
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: virtualNetwork.addressPrefixes
    }
    subnets: [for j in range(0, length(virtualNetwork.subnets)): {
      name: virtualNetwork.subnets[j].name
      properties: {
        addressPrefix: virtualNetwork.subnets[j].addressPrefix
        networkSecurityGroup: {
          id: resourceId('Microsoft.Network/networkSecurityGroups', virtualNetwork.subnets[j].nsg)
        }
      }
    }]
  }
  dependsOn: [
    nsgId
  ]
}

resource appInsightsName_resource 'Microsoft.Insights/components@2018-05-01-preview' = {
  name: appInsightsName
  location: location
  kind: 'web'
  tags: {
    name: appInsightsName
    resource: apimServiceName
    service: 'Application Insights'
  }
  properties: {
    Application_Type: 'web'
    Request_Source: 'rest'
  }
}

resource apimServiceName_appInsightsName 'Microsoft.ApiManagement/service/loggers@2019-12-01' = {
  parent: apimServiceName_resource
  name: '${appInsightsName}'
  properties: {
    loggerType: 'applicationInsights'
    description: 'Logger resources to APIM'
    credentials: {
      instrumentationKey: reference(appInsightsId, '2015-05-01').InstrumentationKey
    }
  }
  dependsOn: [
    apimId
  ]
}

resource apimServiceName_resource 'Microsoft.ApiManagement/service@2019-12-01' = {
  name: apimServiceName
  location: location
  tags: {
    name: apimServiceName
    service: 'APIM'
  }
  sku: {
    name: apimSku
    capacity: apimCapacity
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publisherEmail: apimPublisherEmail
    publisherName: apimPublisherName
    virtualNetworkType: 'External'
    virtualNetworkConfiguration: {
      subnetResourceId: apimSubnetId
    }
  }
  dependsOn: [
    vnetId
  ]
}

resource apimServiceName_custom 'Microsoft.ApiManagement/service/products@2019-12-01' = {
  parent: apimServiceName_resource
  name: 'custom'
  properties: {
    displayName: 'Custom'
    description: 'Subscribers have completely unlimited access to the API. Administrator approval is required.'
    subscriptionRequired: true
    approvalRequired: false
    subscriptionsLimit: 1
    state: 'published'
  }
  dependsOn: [
    apimId
    mockApiId
    postmanEchoApiId
  ]
}

resource apimServiceName_custom_mockApi 'Microsoft.ApiManagement/service/products/apis@2019-12-01' = {
  parent: apimServiceName_custom
  name: 'mockApi'
  properties: {
    displayName: 'Mock API'
    apiRevision: '1'
    description: 'This is a Mock API.'
    subscriptionRequired: true
    path: 'mock'
    protocols: [
      'https'
      'http'
    ]
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
  dependsOn: [
    apimId
    mockApiId
    customProductId
  ]
}

resource apimServiceName_custom_postmanEchoApi 'Microsoft.ApiManagement/service/products/apis@2019-12-01' = {
  parent: apimServiceName_custom
  name: 'postmanEchoApi'
  properties: {
    displayName: 'Postman Echo API'
    apiRevision: '1'
    description: 'This is the Postman Echo API.'
    subscriptionRequired: true
    serviceUrl: 'https://postman-echo.com'
    path: 'postman-echo'
    protocols: [
      'https'
      'http'
    ]
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
  dependsOn: [
    apimId
    postmanEchoApiId
    customProductId
  ]
}

resource apimServiceName_mockApi 'Microsoft.ApiManagement/service/apis@2019-12-01' = {
  parent: apimServiceName_resource
  name: 'mockApi'
  properties: {
    displayName: 'Mock API'
    apiRevision: '1'
    description: 'This is a Mock API.'
    subscriptionRequired: true
    path: 'mock'
    protocols: [
      'https'
      'http'
    ]
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
  dependsOn: [
    apimId
  ]
}

resource apimServiceName_mockApi_test 'Microsoft.ApiManagement/service/apis/operations@2019-12-01' = {
  parent: apimServiceName_mockApi
  name: 'test'
  properties: {
    displayName: 'Test'
    method: 'GET'
    urlTemplate: '/test'
    description: 'This method always return 200.'
    responses: [
      {
        statusCode: 200
        description: 'The GET mock methods always returns a given response'
        representations: [
          {
            contentType: 'application/json'
            sample: '{"company": "Contoso", "api": "Mock API", "method": "GET", "operation": "test"}'
          }
        ]
      }
    ]
  }
  dependsOn: [
    apimId
    mockApiId
  ]
}

resource apimServiceName_mockApi_test_policy 'Microsoft.ApiManagement/service/apis/operations/policies@2019-12-01' = {
  parent: apimServiceName_mockApi_test
  name: 'policy'
  properties: {
    value: '<policies>\r\n    <inbound>\r\n        <base />\r\n        <mock-response status-code="200" content-type="application/json" />\r\n    </inbound>\r\n    <backend>\r\n        <base />\r\n    </backend>\r\n    <outbound>\r\n        <base />\r\n    </outbound>\r\n    <on-error>\r\n        <base />\r\n    </on-error>\r\n</policies>'
    format: 'xml'
  }
  dependsOn: [
    apimId
    mockApiId
    testMethodId
  ]
}

resource apimServiceName_mockApi_policy 'Microsoft.ApiManagement/service/apis/policies@2019-12-01' = {
  parent: apimServiceName_mockApi
  name: 'policy'
  properties: {
    format: 'xml'
    value: '<policies>\r\n\t<inbound>\r\n\t\t<base />\r\n\t\t<cors>\r\n\t\t\t<allowed-origins>\r\n\t\t\t\t<origin>*</origin>\r\n\t\t\t</allowed-origins>\r\n\t\t\t<allowed-methods>\r\n\t\t\t\t<method>GET</method>\r\n\t\t\t\t<method>POST</method>\r\n\t\t\t\t<method>PUT</method>\r\n\t\t\t\t<method>DELETE</method>\r\n\t\t\t\t<method>HEAD</method>\r\n\t\t\t\t<method>OPTIONS</method>\r\n\t\t\t\t<method>PATCH</method>\r\n\t\t\t\t<method>TRACE</method>\r\n\t\t\t</allowed-methods>\r\n\t\t\t<allowed-headers>\r\n\t\t\t\t<header>*</header>\r\n\t\t\t</allowed-headers>\r\n\t\t\t<expose-headers>\r\n\t\t\t\t<header>*</header>\r\n\t\t\t</expose-headers>\r\n\t\t</cors>\r\n\t</inbound>\r\n\t<backend>\r\n\t\t<base />\r\n\t</backend>\r\n\t<outbound>\r\n\t\t<base />\r\n\t</outbound>\r\n\t<on-error>\r\n\t\t<base />\r\n\t</on-error>\r\n</policies>'
  }
  dependsOn: [
    apimId
    mockApiId
  ]
}

resource apimServiceName_mockApi_applicationinsights 'Microsoft.ApiManagement/service/apis/diagnostics@2019-12-01' = {
  parent: apimServiceName_mockApi
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    loggerId: loggerId
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    enableHttpCorrelationHeaders: true
  }
  dependsOn: [
    apimId
    loggerId
    mockApiId
  ]
}

resource apimServiceName_postmanEchoApi 'Microsoft.ApiManagement/service/apis@2019-12-01' = {
  parent: apimServiceName_resource
  name: 'postmanEchoApi'
  properties: {
    displayName: 'Postman Echo API'
    apiRevision: '1'
    description: 'This is the Postman Echo API.'
    subscriptionRequired: true
    serviceUrl: 'https://postman-echo.com'
    path: 'postman-echo'
    protocols: [
      'https'
      'http'
    ]
    subscriptionKeyParameterNames: {
      header: 'Ocp-Apim-Subscription-Key'
      query: 'subscription-key'
    }
    isCurrent: true
  }
  dependsOn: [
    apimId
  ]
}

resource apimServiceName_postmanEchoApi_get 'Microsoft.ApiManagement/service/apis/operations@2019-12-01' = {
  parent: apimServiceName_postmanEchoApi
  name: 'get'
  properties: {
    displayName: 'GET Request'
    method: 'GET'
    urlTemplate: '/get'
    description: 'The HTTP GET request method is meant to retrieve data from a server. The data is identified by a unique URI (Uniform Resource Identifier). '
  }
  dependsOn: [
    apimId
    postmanEchoApiId
  ]
}

resource apimServiceName_postmanEchoApi_policy 'Microsoft.ApiManagement/service/apis/policies@2019-12-01' = {
  parent: apimServiceName_postmanEchoApi
  name: 'policy'
  properties: {
    format: 'xml'
    value: '<policies>\r\n\t<inbound>\r\n\t\t<base />\r\n\t\t<cors>\r\n\t\t\t<allowed-origins>\r\n\t\t\t\t<origin>*</origin>\r\n\t\t\t</allowed-origins>\r\n\t\t\t<allowed-methods>\r\n\t\t\t\t<method>GET</method>\r\n\t\t\t\t<method>POST</method>\r\n\t\t\t\t<method>PUT</method>\r\n\t\t\t\t<method>DELETE</method>\r\n\t\t\t\t<method>HEAD</method>\r\n\t\t\t\t<method>OPTIONS</method>\r\n\t\t\t\t<method>PATCH</method>\r\n\t\t\t\t<method>TRACE</method>\r\n\t\t\t</allowed-methods>\r\n\t\t\t<allowed-headers>\r\n\t\t\t\t<header>*</header>\r\n\t\t\t</allowed-headers>\r\n\t\t\t<expose-headers>\r\n\t\t\t\t<header>*</header>\r\n\t\t\t</expose-headers>\r\n\t\t</cors>\r\n\t</inbound>\r\n\t<backend>\r\n\t\t<base />\r\n\t</backend>\r\n\t<outbound>\r\n\t\t<base />\r\n\t</outbound>\r\n\t<on-error>\r\n\t\t<base />\r\n\t</on-error>\r\n</policies>'
  }
  dependsOn: [
    apimId
    postmanEchoApiId
  ]
}

resource apimServiceName_postmanEchoApi_applicationinsights 'Microsoft.ApiManagement/service/apis/diagnostics@2019-12-01' = {
  parent: apimServiceName_postmanEchoApi
  name: 'applicationinsights'
  properties: {
    alwaysLog: 'allErrors'
    loggerId: loggerId
    sampling: {
      samplingType: 'fixed'
      percentage: 100
    }
    enableHttpCorrelationHeaders: true
  }
  dependsOn: [
    apimId
    loggerId
    postmanEchoApiId
  ]
}

resource apimServiceName_Microsoft_Insights_service 'Microsoft.ApiManagement/service/providers/diagnosticsettings@2016-09-01' = {
  name: '${apimServiceName}/Microsoft.Insights/service'
  location: location
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'GatewayLogs'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'Gateway Requests'
        timeGrain: 'PT1M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Capacity'
        timeGrain: 'PT1M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'EventHub Events'
        timeGrain: 'PT1M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
      {
        category: 'Network Status'
        timeGrain: 'PT1M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    apimId
    workspaceId
  ]
}

resource wafPolicyName_resource 'Microsoft.Network/FrontDoorWebApplicationFirewallPolicies@2019-03-01' = if (deployWaf) {
  name: wafPolicyName
  location: 'global'
  properties: {
    policySettings: {
      mode: wafMode
      enabledState: 'Enabled'
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'DefaultRuleSet'
          ruleSetVersion: '1.0'
        }
      ]
    }
  }
}

resource frontDoorName_resource 'Microsoft.Network/frontdoors@2019-05-01' = {
  name: frontDoorName
  location: 'Global'
  properties: {
    backendPoolsSettings: {
      enforceCertificateNameCheck: frontDoorEnforceCertificateNameCheck
      sendRecvTimeoutSeconds: 120
    }
    enabledState: 'Enabled'
    resourceState: 'Enabled'
    backendPools: [
      {
        name: frontDoorBackendPool.name
        properties: {
          backends: [
            {
              address: apimServiceName_resource.properties.hostnameConfigurations[0].hostName
              httpPort: 80
              httpsPort: 443
              priority: 1
              weight: 100
              backendHostHeader: apimServiceName_resource.properties.hostnameConfigurations[0].hostName
            }
          ]
          healthProbeSettings: {
            id: frontDoorHealthProbeSettingsId
          }
          loadBalancingSettings: {
            id: frontDoorLoadBalancerId
          }
        }
      }
    ]
    healthProbeSettings: [
      {
        name: frontDoorHealthProbeSettings.name
        properties: {
          intervalInSeconds: frontDoorHealthProbeSettings.intervalInSeconds
          path: frontDoorHealthProbeSettings.path
          protocol: frontDoorHealthProbeSettings.protocol
        }
      }
    ]
    frontendEndpoints: [
      {
        name: frontDoorFrontendEndpoint.name
        properties: {
          hostName: frontDoorHostName
          sessionAffinityEnabledState: frontDoorFrontendEndpoint.sessionAffinityEnabledState
          sessionAffinityTtlSeconds: frontDoorFrontendEndpoint.sessionAffinityTtlSeconds
          resourceState: 'Enabled'
          webApplicationFirewallPolicyLink: {
            id: (deployWaf ? wafPolicyId : json('null'))
          }
        }
      }
    ]
    loadBalancingSettings: [
      {
        name: frontDoorBackendPool.loadBalancerName
        properties: {
          additionalLatencyMilliseconds: 0
          sampleSize: 4
          successfulSamplesRequired: 2
        }
      }
    ]
    routingRules: [
      {
        name: frontDoorRoutingRule.name
        properties: {
          frontendEndpoints: [
            {
              id: frontDoorFrontedEndpointId
            }
          ]
          acceptedProtocols: frontDoorRoutingRule.acceptedProtocols
          patternsToMatch: frontDoorRoutingRule.patternsToMatch
          routeConfiguration: {
            '@odata.type': '#Microsoft.Azure.FrontDoor.Models.FrontdoorForwardingConfiguration'
            customForwardingPath: '/'
            forwardingProtocol: frontDoorRoutingRule.forwardingProtocol
            backendPool: {
              id: frontDoorBackendPoolId
            }
            cacheConfiguration: frontDoorRoutingRule.cacheConfiguration
          }
        }
      }
    ]
    friendlyName: frontDoorName
  }
  dependsOn: [
    wafPolicyId
  ]
}

resource frontDoorName_Microsoft_Insights_service 'Microsoft.Network/frontdoors/providers/diagnosticsettings@2016-09-01' = {
  name: '${frontDoorName}/Microsoft.Insights/service'
  location: location
  properties: {
    workspaceId: workspaceId
    logs: [
      {
        category: 'FrontdoorAccessLog'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 0
        }
      }
      {
        category: 'FrontdoorWebApplicationFirewallLog'
        enabled: true
        retentionPolicy: {
          enabled: true
          days: 0
        }
      }
    ]
    metrics: [
      {
        category: 'AllMetrics'
        timeGrain: 'PT1M'
        enabled: true
        retentionPolicy: {
          enabled: false
          days: 0
        }
      }
    ]
  }
  dependsOn: [
    frontDoorId
    workspaceId
  ]
}

output apiManagement object = reference(apimServiceName_resource.id, '2019-12-01', 'Full')