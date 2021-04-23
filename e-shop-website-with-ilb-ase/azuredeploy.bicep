@description('Name of the App Service Environment.')
param existingASEName string

@description('Location of the App Service Environment.')
param existingASELocation string

@description('DNS Suffix used for the ILB ASE')
param existingASEDNSSuffix string

@description('Root domain name used to access web apps on internet.')
param dnsSuffix string

@description('Administrator login name of the Azure SQL Server.')
param sqlServerAdministratorLogin string

@description('Administrator login password of the Azure SQL Server.')
@secure()
param sqlServerAdministratorLoginPassword string

@description('Directory ID of the Azure Active Directory used by the Admin App.')
param azureAdTenantId string

@description('Application ID of the Admin App Registration.')
param azureAdClientId string

@description('description')
param appInsightsLocation string

var location = existingASELocation
var vnetName = '${existingASEName}-vnet'
var aseSubnetName = '${existingASEName}-subnet'
var aseSubnetAddressPrefix = '192.168.251.64/26'
var agSubnetName = 'app-gateway-subnet'
var aspName_var = '${existingASEName}-asp'
var webAppName_var = '${existingASEName}-web'
var contentAppName_var = '${existingASEName}-content'
var apiAppName_var = '${existingASEName}-api'
var adminAppName_var = '${existingASEName}-admin'
var appInsightsName_var = '${existingASEName}-app-insights'
var sqlServerName_var = '${existingASEName}-sql-server'
var storageAccountName_var = '${existingASEName}-${''}'
var redisCacheName_var = '${existingASEName}-cache'
var redisCacheSubnetName = 'redis-cache-subnet'
var redisCacheSubnetAddressPrefix = '192.168.251.0/26'
var redisCacheStaticIP = '192.168.251.62'
var appGatewayName_var = '${existingASEName}-waf'
var appGatewayPublicIPName_var = '${existingASEName}-waf-ip'
var appGatewayPublicIPDnsPrefix = '${existingASEName}-waf'
var cdnName_var = '${existingASEName}-cdn'
var cdnWebAppEndpointName = '${existingASEName}-cdn-web'
var cdnStorageEndpointName = '${existingASEName}-cdn-storage'
var webAppExternalHostName = '${webAppName_var}.${dnsSuffix}'
var webAppInternalHostName = '${webAppName_var}.${existingASEDNSSuffix}'
var apiAppInternalHostName = '${apiAppName_var}.${existingASEDNSSuffix}'
var contentAppExternalHostName = '${contentAppName_var}.${dnsSuffix}'
var contentAppInternalHostName = '${contentAppName_var}.${existingASEDNSSuffix}'
var adminAppExternalHostName = '${adminAppName_var}.${dnsSuffix}'
var adminAppInternalHostName = '${adminAppName_var}.${existingASEDNSSuffix}'
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

resource appInsightsName 'microsoft.insights/components@2020-02-02-preview' = {
  name: appInsightsName_var
  location: appInsightsLocation
  properties: {
    ApplicationId: appInsightsName_var
    Request_Source: 'IbizaWebAppExtensionCreate'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
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

resource redisCacheName 'Microsoft.Cache/Redis@2019-07-01' = {
  name: redisCacheName_var
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
}

resource aspName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: aspName_var
  location: location
  kind: 'app'
  properties: {
    name: aspName_var
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

resource contentAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: contentAppName_var
  location: location
  properties: {
    name: contentAppName_var
    serverFarmId: aspName.id
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
}

resource contentAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  parent: contentAppName
  name: 'web'
  properties: {
    repoUrl: sourceCodeRepositoryURL
    branch: 'master'
    isManualIntegration: true
  }
}

resource apiAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: apiAppName_var
  location: location
  properties: {
    name: apiAppName_var
    serverFarmId: aspName.id
    hostingEnvironment: existingASEName
    siteConfig: {
      alwaysOn: true
      appSettings: [
        {
          name: 'ApplicationInsights:InstrumentationKey'
          value: reference(appInsightsName.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'project'
          value: 'src/API/API.csproj'
        }
      ]
      connectionStrings: [
        {
          name: 'SalesConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName_var}.database.windows.net,1433;Initial Catalog=Sales;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
      ]
    }
  }
}

resource apiAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  parent: apiAppName
  name: 'web'
  properties: {
    repoUrl: sourceCodeRepositoryURL
    branch: 'master'
    isManualIntegration: true
  }
}

resource adminAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: adminAppName_var
  location: location
  properties: {
    name: adminAppName_var
    serverFarmId: aspName.id
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
          value: reference(appInsightsName.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'project'
          value: 'src/Admin/Admin.csproj'
        }
      ]
    }
  }
}

resource adminAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  parent: adminAppName
  name: 'web'
  properties: {
    repoUrl: sourceCodeRepositoryURL
    branch: 'master'
    isManualIntegration: true
  }
  dependsOn: [
    apiAppName_web
  ]
}

resource webAppName 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppName_var
  location: location
  properties: {
    name: webAppName_var
    serverFarmId: aspName.id
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
          value: reference(appInsightsName.id, '2020-02-02-preview').InstrumentationKey
        }
        {
          name: 'project'
          value: 'src/Web/Web.csproj'
        }
      ]
      connectionStrings: [
        {
          name: 'CatalogConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName_var}.database.windows.net,1433;Initial Catalog=Catalog;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'SalesConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName_var}.database.windows.net,1433;Initial Catalog=Sales;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'IdentityConnection'
          type: 'SQLAzure'
          connectionString: 'Server=tcp:${sqlServerName_var}.database.windows.net,1433;Initial Catalog=Identity;Persist Security Info=False;User ID=${sqlServerAdministratorLogin};Password=${sqlServerAdministratorLoginPassword};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;'
        }
        {
          name: 'StorageConnection'
          type: 'Custom'
          connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listkeys(storageAccountName.id, '2019-06-01').keys[0].value};'
        }
        {
          name: 'RedisConnection'
          type: 'Custom'
          connectionString: '${redisCacheName_var}.redis.cache.windows.net:6380,password=${listKeys(redisCacheName.id, '2016-04-01').primaryKey},ssl=True,abortConnect=False'
        }
      ]
    }
  }
}

resource webAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  parent: webAppName
  name: 'web'
  properties: {
    repoUrl: sourceCodeRepositoryURL
    branch: 'master'
    isManualIntegration: true
  }
  dependsOn: [
    adminAppName_web
  ]
}

resource sqlServerName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  location: location
  name: sqlServerName_var
  properties: {
    administratorLogin: sqlServerAdministratorLogin
    administratorLoginPassword: sqlServerAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlServerName_Catalog 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: sqlServerName
  location: location
  name: 'Catalog'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    zoneRedundant: false
  }
}

resource sqlServerName_Sales 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: sqlServerName
  location: location
  name: 'Sales'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    zoneRedundant: false
  }
}

resource sqlServerName_Identity 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: sqlServerName
  location: location
  name: 'Identity'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    edition: 'Basic'
    zoneRedundant: false
  }
}

resource sqlServerName_allow_access_from_aseSubnetName 'Microsoft.Sql/servers/virtualNetworkRules@2020-02-02-preview' = {
  parent: sqlServerName
  name: 'allow-access-from-${aseSubnetName}'
  properties: {
    virtualNetworkSubnetId: resourceId('Microsoft.Network/virtualNetworks/subnets/', vnetName, aseSubnetName)
  }
}

resource appGatewayName 'Microsoft.Network/applicationGateways@2020-05-01' = {
  name: appGatewayName_var
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
          publicIPAddress: {
            id: appGatewayPublicIPName.id
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
        name: 'webAppBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: webAppInternalHostName
            }
          ]
        }
      }
      {
        name: 'contentAppBackendPool'
        properties: {
          backendAddresses: [
            {
              fqdn: contentAppInternalHostName
            }
          ]
        }
      }
      {
        name: 'adminAppBackendPool'
        properties: {
          backendAddresses: [
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
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName_var, 'webAppProbe')
          }
        }
      }
      {
        name: 'contentAppBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName_var, 'contentAppProbe')
          }
        }
      }
      {
        name: 'adminAppBackendHttpSettings'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', appGatewayName_var, 'adminAppProbe')
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'webAppHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName_var, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName_var, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostName: webAppExternalHostName
        }
      }
      {
        name: 'contentAppHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName_var, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName_var, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostName: contentAppExternalHostName
        }
      }
      {
        name: 'adminAppHttpListener'
        properties: {
          frontendIPConfiguration: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', appGatewayName_var, 'appGatewayFrontendIP')
          }
          frontendPort: {
            id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', appGatewayName_var, 'appGatewayFrontendPort')
          }
          protocol: 'Http'
          hostName: adminAppExternalHostName
        }
      }
    ]
    requestRoutingRules: [
      {
        name: 'webAppRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName_var, 'webAppHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName_var, 'webAppBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName_var, 'webAppBackendHttpSettings')
          }
        }
      }
      {
        name: 'contentAppRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName_var, 'contentAppHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName_var, 'contentAppBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName_var, 'contentAppBackendHttpSettings')
          }
        }
      }
      {
        name: 'adminAppRule'
        properties: {
          ruleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', appGatewayName_var, 'adminAppHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', appGatewayName_var, 'adminAppBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', appGatewayName_var, 'adminAppBackendHttpSettings')
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
}

resource appGatewayPublicIPName 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: appGatewayPublicIPName_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    dnsSettings: {
      domainNameLabel: appGatewayPublicIPDnsPrefix
    }
  }
}

resource cdnName 'microsoft.cdn/profiles@2020-04-15' = {
  name: cdnName_var
  location: location
  sku: {
    name: 'Standard_Verizon'
  }
}

resource cdnName_cdnWebAppEndpointName 'microsoft.cdn/profiles/endpoints@2020-04-15' = {
  parent: cdnName
  name: '${cdnWebAppEndpointName}'
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
}

resource cdnName_cdnStorageEndpointName 'microsoft.cdn/profiles/endpoints@2020-04-15' = {
  parent: cdnName
  name: '${cdnStorageEndpointName}'
  location: location
  properties: {
    isHttpAllowed: true
    isHttpsAllowed: true
    origins: [
      {
        name: 'Storage'
        properties: {
          hostName: replace(replace(reference(storageAccountName.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
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
    originHostHeader: replace(replace(reference(storageAccountName.id, '2019-06-01').primaryEndpoints.blob, 'https://', ''), '/', '')
  }
}

output webAppURL string = 'http://${webAppExternalHostName}'
output adminAppURL string = 'http://${adminAppExternalHostName}'
output adminAppRedirectURL string = 'http://${adminAppExternalHostName}/signin-oidc'
output appGatewayPublicIPFqdn string = reference(appGatewayPublicIPName.id, '2018-04-01').dnsSettings.fqdn