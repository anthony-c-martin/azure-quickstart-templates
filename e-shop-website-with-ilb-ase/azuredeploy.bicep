param existingASEName string {
  metadata: {
    description: 'Name of the App Service Environment.'
  }
}
param existingASELocation string {
  metadata: {
    description: 'Location of the App Service Environment.'
  }
}
param existingASEDNSSuffix string {
  metadata: {
    description: 'DNS Suffix used for the ILB ASE'
  }
}
param dnsSuffix string {
  metadata: {
    description: 'Root domain name used to access web apps on internet.'
  }
}
param sqlServerAdministratorLogin string {
  metadata: {
    description: 'Administrator login name of the Azure SQL Server.'
  }
}
param sqlServerAdministratorLoginPassword string {
  metadata: {
    description: 'Administrator login password of the Azure SQL Server.'
  }
  secure: true
}
param azureAdTenantId string {
  metadata: {
    description: 'Directory ID of the Azure Active Directory used by the Admin App.'
  }
}
param azureAdClientId string {
  metadata: {
    description: 'Application ID of the Admin App Registration.'
  }
}
param appInsightsLocation string {
  metadata: {
    description: 'description'
  }
}

var location = existingASELocation
var vnetName = '${existingASEName}-vnet'
var aseSubnetName = '${existingASEName}-subnet'
var aseSubnetAddressPrefix = '192.168.251.64/26'
var agSubnetName = 'app-gateway-subnet'
var aspName = '${existingASEName}-asp'
var webAppName = '${existingASEName}-web'
var contentAppName = '${existingASEName}-content'
var apiAppName = '${existingASEName}-api'
var adminAppName = '${existingASEName}-admin'
var appInsightsName = '${existingASEName}-app-insights'
var sqlServerName = '${existingASEName}-sql-server'
var storageAccountName = '${existingASEName}-${''}'
var redisCacheName = '${existingASEName}-cache'
var redisCacheSubnetName = 'redis-cache-subnet'
var redisCacheSubnetAddressPrefix = '192.168.251.0/26'
var redisCacheStaticIP = '192.168.251.62'
var appGatewayName = '${existingASEName}-waf'
var appGatewayPublicIPName = '${existingASEName}-waf-ip'
var appGatewayPublicIPDnsPrefix = '${existingASEName}-waf'
var cdnName = '${existingASEName}-cdn'
var cdnWebAppEndpointName = '${existingASEName}-cdn-web'
var cdnStorageEndpointName = '${existingASEName}-cdn-storage'
var webAppExternalHostName = '${webAppName}.${dnsSuffix}'
var webAppInternalHostName = '${webAppName}.${existingASEDNSSuffix}'
var apiAppInternalHostName = '${apiAppName}.${existingASEDNSSuffix}'
var contentAppExternalHostName = '${contentAppName}.${dnsSuffix}'
var contentAppInternalHostName = '${contentAppName}.${existingASEDNSSuffix}'
var adminAppExternalHostName = '${adminAppName}.${dnsSuffix}'
var adminAppInternalHostName = '${adminAppName}.${existingASEDNSSuffix}'
var sourceCodeRepositoryURL = 'https://github.com/OGCanviz/e-shop-website-with-ilb-ase'

resource vnetName_redisCacheSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${vnetName}/${redisCacheSubnetName}'
  properties: {
    addressPrefix: redisCacheSubnetAddressPrefix
  }
}

resource vnetName_agSubnetName 'Microsoft.Network/virtualNetworks/subnets@2020-05-01' = {
  name: '${vnetName}/${agSubnetName}'
  properties: {
    addressPrefix: aseSubnetAddressPrefix
  }
  dependsOn: [
    vnetName_redisCacheSubnetName
  ]
}

resource appInsightsName_resource 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsightsName
  location: appInsightsLocation
  properties: {
    ApplicationId: appInsightsName
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: false
    accessTier: 'Hot'
    encryption: {
      services: {
        blob: {
          enabled: true
        }
        file: {
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }
}

resource redisCacheName_resource 'Microsoft.Cache/Redis@2019-07-01' = {
  name: redisCacheName
  location: location
  properties: {
    sku: {
      name: 'Premium'
      family: 'P'
      capacity: 1
    }
    subnetId: vnetName_redisCacheSubnetName.id
    staticIP: redisCacheStaticIP
    enableNonSslPort: true
  }
  dependsOn: [
    vnetName_redisCacheSubnetName
  ]
}

resource aspName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: aspName
  location: location
  kind: 'app'
  properties: {
    name: aspName
    workerSize: '0'
    workerSizeId: '0'
    numberOfWorkers: '1'
    reserved: false
    hostingEnvironment: existingASEName
  }
  sku: {
    tier: 'Isolated'
    name: 'I1'
  }
}

resource contentAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: contentAppName
  location: location
  properties: {
    name: contentAppName
    serverFarmId: aspName_resource.id
    hostingEnvironment: existingASEName
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'project'
          value: 'src/Web/wwwroot'
        }
      ]
    }
  }
  dependsOn: [
    aspName_resource
  ]
}

resource contentAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  name: '${contentAppName}/web'
  properties: {
    RepoUrl: sourceCodeRepositoryURL
    branch: 'master'
    IsManualIntegration: true
  }
  dependsOn: [
    contentAppName_resource
  ]
}

resource apiAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: apiAppName
  location: location
  properties: {
    name: apiAppName
    serverFarmId: aspName_resource.id
    hostingEnvironment: existingASEName
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(appInsightsName_resource.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'project'
          value: 'src/API/API.csproj'
        }
      ]
      connectionstrings: [
        {
          name: 'SalesConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=Sales;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
    }
  }
  dependsOn: [
    aspName_resource
    appInsightsName_resource
  ]
}

resource apiAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  name: '${apiAppName}/web'
  properties: {
    RepoUrl: sourceCodeRepositoryURL
    branch: 'master'
    IsManualIntegration: true
  }
  dependsOn: [
    apiAppName_resource
  ]
}

resource adminAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: adminAppName
  location: location
  properties: {
    name: adminAppName
    serverFarmId: aspName_resource.id
    hostingEnvironment: existingASEName
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'AzureAd:Domain'
          value: ''
        }
        {
          name: 'AzureAd:TenantId'
          value: azureAdTenantId
        }
        {
          name: 'AzureAd:ClientId'
          value: azureAdClientId
        }
        {
          name: 'ODataServiceBaseUrl'
          value: 'http://${apiAppInternalHostName}'
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(appInsightsName_resource.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'project'
          value: 'src/Admin/Admin.csproj'
        }
      ]
    }
  }
  dependsOn: [
    aspName_resource
    appInsightsName_resource
  ]
}

resource adminAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  name: '${adminAppName}/web'
  properties: {
    RepoUrl: sourceCodeRepositoryURL
    branch: 'master'
    IsManualIntegration: true
  }
  dependsOn: [
    adminAppName_resource
    apiAppName_web
  ]
}

resource webAppName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppName
  location: location
  properties: {
    name: webAppName
    serverFarmId: aspName_resource.id
    hostingEnvironment: existingASEName
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'ODataServiceBaseUrl'
          value: 'http://${apiAppInternalHostName}'
        }
        {
          name: 'cdn:url'
          value: 'http://${reference(cdnName_cdnWebAppEndpointName.id, '2017-10-12').hostName}'
        }
        {
          name: 'CatalogBaseUrl'
          value: 'https://${cdnStorageEndpointName}.azureedge.net'
        }
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(appInsightsName_resource.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'project'
          value: 'src/Web/Web.csproj'
        }
      ]
      connectionstrings: [
        {
          name: 'CatalogConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=Catalog;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'SalesConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=Sales;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'IdentityConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName}.database.windows.net,1433;Initial Catalog=Identity;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'StorageConnection'
          type: 'Custom'
          connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};AccountKey=${listkeys(storageAccountName_resource.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'RedisConnection'
          type: 'Custom'
          connectionString: '${redisCacheName}.redis.cache.windows.net:6380,password=${listKeys(redisCacheName_resource.id, '2016-04-01').primaryKey},ssl=True,abortConnect=False'
        }
      ]
    }
  }
  dependsOn: [
    aspName_resource
    appInsightsName_resource
    storageAccountName_resource
    redisCacheName_resource
  ]
}

resource webAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  name: '${webAppName}/web'
  properties: {
    RepoUrl: sourceCodeRepositoryURL
    branch: 'master'
    IsManualIntegration: true
  }
  dependsOn: [
    webAppName_resource
    adminAppName_web
  ]
}

resource sqlServerName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  location: location
  name: sqlServerName
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlServerName_Catalog 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  location: location
  name: '${sqlServerName}/Catalog'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    zoneRedundant: false
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_Sales 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  location: location
  name: '${sqlServerName}/Sales'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    zoneRedundant: false
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_Identity 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  location: location
  name: '${sqlServerName}/Identity'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    zoneRedundant: false
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource sqlServerName_allow_access_from_aseSubnetName 'Microsoft.Sql/servers/virtualNetworkRules@2020-02-02-preview' = {
  name: '${sqlServerName}/allow-access-from-${aseSubnetName}'
  properties: {
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, aseSubnetName)
  }
  dependsOn: [
    sqlServerName_resource
  ]
}

resource appGatewayName_resource 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: appGatewayName
  location: location
  properties: {
    sku: {
      name: 'WAF_Medium'
      tier: 'WAF'
      capacity: '1'
    }
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: vnetName_agSubnetName.id
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'appGatewayFrontendIP'
        properties: {
          PublicIPAddress: {
            id: appGatewayPublicIPName_resource.id
          }
        }
      }
    ]
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: 80
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'webAppBackendPool'
        properties: {
          BackendAddresses: [
            {
              fqdn: webAppInternalHostName
            }
          ]
        }
      }
      {
        name: 'contentAppBackendPool'
        properties: {
          BackendAddresses: [
            {
              fqdn: contentAppInternalHostName
            }
          ]
        }
      }
      {
        name: 'adminAppBackendPool'
        properties: {
          BackendAddresses: [
            {
              fqdn: adminAppInternalHostName
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'webAppBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
          PickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'webAppProbe')
          }
        }
      }
      {
        name: 'contentAppBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
          PickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'contentAppProbe')
          }
        }
      }
      {
        name: 'adminAppBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
          PickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName, 'adminAppProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'webAppHttpListener'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
          HostName: webAppExternalHostName
        }
      }
      {
        name: 'contentAppHttpListener'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
          HostName: contentAppExternalHostName
        }
      }
      {
        name: 'adminAppHttpListener'
        properties: {
          FrontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
          HostName: adminAppExternalHostName
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'webAppRule'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'webAppHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'webAppBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'webAppBackendHttpSettings')
          }
        }
      }
      {
        Name: 'contentAppRule'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'contentAppHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'contentAppBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'contentAppBackendHttpSettings')
          }
        }
      }
      {
        Name: 'adminAppRule'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName, 'adminAppHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName, 'adminAppBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName, 'adminAppBackendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: 'webAppProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          host: webAppInternalHostName
          interval: 30
          timeout: 120
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
        }
      }
      {
        name: 'contentAppProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          host: contentAppInternalHostName
          interval: 30
          timeout: 120
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
        }
      }
      {
        name: 'adminAppProbe'
        properties: {
          protocol: 'Http'
          path: '/'
          host: adminAppInternalHostName
          interval: 30
          timeout: 120
          unhealthyThreshold: 3
          pickHostNameFromBackendHttpSettings: false
        }
      }
    ]
    webApplicationFirewallConfiguration: {
      enabled: true
      firewallMode: 'Prevention'
      ruleSetType: 'OWASP'
      ruleSetVersion: '3.0'
      disabledRuleGroups: [
        {
          ruleGroupName: 'REQUEST-920-PROTOCOL-ENFORCEMENT'
          rules: [
            920350
          ]
        }
        {
          ruleGroupName: 'REQUEST-931-APPLICATION-ATTACK-RFI'
          rules: [
            931130
          ]
        }
        {
          ruleGroupName: 'REQUEST-942-APPLICATION-ATTACK-SQLI'
          rules: [
            942130
            942440
          ]
        }
      ]
    }
  }
  dependsOn: [
    vnetName_agSubnetName
    appGatewayPublicIPName_resource
  ]
}

resource appGatewayPublicIPName_resource 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: appGatewayPublicIPName
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: appGatewayPublicIPDnsPrefix
    }
  }
}

resource cdnName_resource 'microsoft.cdn/profiles@2020-04-15' = {
  name: cdnName
  location: location
  sku: {
    name: 'standard_verizon'
  }
}

resource cdnName_cdnWebAppEndpointName 'microsoft.cdn/profiles/endpoints@2020-04-15' = {
  name: '${cdnName}/${cdnWebAppEndpointName}'
  location: location
  properties: {
    isHttpAllowed: true
    isHttpsAllowed: false
    origins: [
      {
        name: 'contentApp'
        properties: {
          hostName: contentAppExternalHostName
        }
      }
    ]
    isCompressionEnabled: true
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'text/javascript'
      'application/x-javascript'
      'application/javascript'
      'application/json'
      'application/xml'
    ]
    optimizationType: 'GeneralWebDelivery'
    originHostHeader: contentAppExternalHostName
  }
  dependsOn: [
    cdnName_resource
  ]
}

resource cdnName_cdnStorageEndpointName 'microsoft.cdn/profiles/endpoints@2020-04-15' = {
  name: '${cdnName}/${cdnStorageEndpointName}'
  location: location
  properties: {
    isHttpAllowed: true
    isHttpsAllowed: true
    origins: [
      {
        name: 'Storage'
        properties: {
          hostName: replace(replace(reference(storageAccountName_resource.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
        }
      }
    ]
    isCompressionEnabled: true
    contentTypesToCompress: [
      'text/plain'
      'text/html'
      'text/css'
      'text/javascript'
      'application/x-javascript'
      'application/javascript'
      'application/json'
      'application/xml'
    ]
    optimizationType: 'GeneralWebDelivery'
    originHostHeader: replace(replace(reference(storageAccountName_resource.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
  }
  dependsOn: [
    cdnName_resource
    storageAccountName_resource
  ]
}

output webAppURL string = 'http://${webAppExternalHostName}'
output adminAppURL string = 'http://${adminAppExternalHostName}'
output adminAppRedirectURL string = 'http://${adminAppExternalHostName}/signin-oidc'
output appGatewayPublicIPFqdn string = reference(appGatewayPublicIPName_resource.id, '2018-04-01').dnsSettings.fqdn