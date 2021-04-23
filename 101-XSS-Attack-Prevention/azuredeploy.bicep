@description('this will be the location for artifacts')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-XSS-Attack-Prevention/'

@description('this will be the sas key to access artifacts')
@secure()
param artifactsLocationSasToken string = ''

@allowed([
  'East US'
  'West Europe'
  'Southeast Asia'
  'Australia Southeast'
])
@description('your resources will be created in this location')
param location string

@allowed([
  'Free'
  'Standalone'
  'PerNode'
])
@description('this will be you SKU for OMS')
param omsSku string = 'PerNode'

@allowed([
  'dynamic'
  'static'
])
@description('this will be the type of public IP address used for the application gateway name')
param pipAddressType string = 'dynamic'

@description('this will be the admin user for sql server')
param sqlAdministratorName string

@description('this wiil be th password for the admin user for sql server')
@secure()
param sqlServerPassword string

@description('this user will get the alert emails')
param emailToSendAlertsTo string = 'dummy@contoso.com'

var omsWorkspaceName = 'xss-attack-oms-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var omsSolutions = [
  'Security'
  'AzureActivity'
  'AzureWebAppsAnalytics'
  'AzureSQLAnalytics'
  'AzureAppGatewayAnalytics'
]
var tags = {
  scenario: 'XSS-Attack-Prevention'
}
var vNetName = 'xss-appgw-vnet'
var vNetAddressSpace = '10.1.0.0/16'
var subnets = [
  {
    name: 'appgw-subnet'
    properties: {
      addressPrefix: '10.1.0.0/24'
    }
  }
]
var applicationGateways = [
  {
    name: 'appgw-detection'
    wafMode: 'Detection'
  }
  {
    name: 'appgw-prevention'
    wafMode: 'Prevention'
  }
]
var databases = [
  {
    name: 'contosoclinic'
    edition: 'Standard'
  }
]
var webAppName = 'xss-attack-webapp-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var httpProbeName = 'aseProbeHTTP'
var httpsProbeName = 'aseProbeHTTPS'
var aspName = 'xss-attack-asp-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var diagStorageAccName = 'xssattackstg${substring(uniqueString(resourceGroup().id), 0, 5)}'
var appServiceConnectionType = 'SQLAzure'
var sqlServerName = 'xssattackserver${substring(uniqueString(resourceGroup().id), 0, 5)}'
var omsTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.loganalytics/workspaces.json'), artifactsLocationSasToken)
var vnetTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/virtualnetworks.json'), artifactsLocationSasToken)
var pipTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/publicipaddress.json'), artifactsLocationSasToken)
var appgwTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.network/applicationgateway.json'), artifactsLocationSasToken)
var storageTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.storage/storageaccounts.json'), artifactsLocationSasToken)
var aspTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.web/serverfarms.json'), artifactsLocationSasToken)
var webappConnectionStringTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.web/sites.config.connectionstrings.json'), artifactsLocationSasToken)
var webappTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.web/sites.json'), artifactsLocationSasToken)
var webappMsDeployTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.web/sites.extensions.msdeploy.json'), artifactsLocationSasToken)
var webPackageUri = concat(uri(artifactsLocation, 'artifacts/ContosoClinic.zip'), artifactsLocationSasToken)
var sqlServerTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.sql/servers.v12.0.json'), artifactsLocationSasToken)
var sqlDatabaseTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.sql/servers.databases.json'), artifactsLocationSasToken)
var sqlAuditingTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.sql/servers.auditingsettings.json'), artifactsLocationSasToken)
var sqlSecurityTemplateUri = concat(uri(artifactsLocation, 'nested/microsoft.sql/servers.securityalertpolicies.json'), artifactsLocationSasToken)

module deploy_xss_attack_oms_resource 'nested/microsoft.loganalytics/workspaces.bicep' = {
  name: 'deploy-xss-attack-oms-resource'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsSolutionsName: omsSolutions
    sku: omsSku
    location: location
    tags: tags
  }
}

module vnetName_resource 'nested/microsoft.network/virtualnetworks.bicep' = {
  name: '${vNetName}-resource'
  params: {
    vnetName: vNetName
    addressPrefix: vNetAddressSpace
    subnets: subnets
    location: location
    tags: tags
  }
}

module applicationGateways_name_pip_resource 'nested/microsoft.network/publicipaddress.bicep' = [for i in range(0, 2): {
  name: '${applicationGateways[i].name}-pip-resource'
  params: {
    publicIPAddressName: '${applicationGateways[i].name}-pip'
    publicIPAddressType: pipAddressType
    dnsNameForPublicIP: '${applicationGateways[i].name}-${uniqueString(resourceGroup().id, 'pip')}-pip'
    location: location
    tags: tags
  }
}]

module deploy_applicationGateways_name_applicationgateway_resource 'nested/microsoft.network/applicationgateway.bicep' = [for i in range(0, 2): {
  name: 'deploy-${applicationGateways[i].name}-applicationgateway-resource'
  params: {
    applicationGatewayName: applicationGateways[i].name
    location: location
    publicIPRef: reference('${applicationGateways[i].name}-pip-resource').outputs.publicIPRef.value
    frontendPorts: [
      {
        name: 'appGatewayFrontendPort'
        properties: {
          Port: 80
        }
      }
    ]
    gatewayIPConfigurations: [
      {
        name: 'appGatewayIpConfig'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vNetName, subnets[0].name)
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'appGatewayBackendPool'
        properties: {
          BackendAddresses: [
            {
              fqdn: reference('${webAppName}-resource').outputs.endpoint.value
            }
          ]
        }
      }
    ]
    backendHttpSettingsCollection: [
      {
        name: 'appGatewayBackendHttpSettings'
        properties: {
          Port: 80
          Protocol: 'Http'
          CookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: 'true'
          Probe: {
            id: resourceId('Microsoft.Network/applicationGateways/probes', applicationGateways[i].name, httpProbeName)
          }
        }
      }
    ]
    httpListeners: [
      {
        name: 'appGatewayHttpListener'
        properties: {
          FrontendIPConfiguration: {
            Id: resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', applicationGateways[i].name, 'appGatewayFrontendIP')
          }
          FrontendPort: {
            Id: resourceId('Microsoft.Network/applicationGateways/frontendPorts', applicationGateways[i].name, 'appGatewayFrontendPort')
          }
          Protocol: 'Http'
          SslCertificate: null
        }
      }
    ]
    requestRoutingRules: [
      {
        Name: 'rule1'
        properties: {
          RuleType: 'Basic'
          httpListener: {
            id: resourceId('Microsoft.Network/applicationGateways/httpListeners', applicationGateways[i].name, 'appGatewayHttpListener')
          }
          backendAddressPool: {
            id: resourceId('Microsoft.Network/applicationGateways/backendAddressPools', applicationGateways[i].name, 'appGatewayBackendPool')
          }
          backendHttpSettings: {
            id: resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', applicationGateways[i].name, 'appGatewayBackendHttpSettings')
          }
        }
      }
    ]
    probes: [
      {
        name: httpProbeName
        properties: {
          protocol: 'Http'
          host: reference('${webAppName}-resource').outputs.endpoint.value
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 8
        }
      }
      {
        name: httpsProbeName
        properties: {
          protocol: 'Https'
          host: reference('${webAppName}-resource').outputs.endpoint.value
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 8
        }
      }
    ]
    wafMode: applicationGateways[i].wafMode
    omsWorkspaceResourceId: reference('deploy-xss-attack-oms-resource').outputs.workspaceId.value
  }
  dependsOn: [
    applicationGateways_name_pip_resource
    vnetName_resource
  ]
}]

module diagStorageAccName_resource 'nested/microsoft.storage/storageaccounts.bicep' = {
  name: '${diagStorageAccName}-resource'
  params: {
    storageAccountName: diagStorageAccName
    location: location
    tags: tags
  }
}

module aspName_resource 'nested/microsoft.web/serverfarms.bicep' = {
  name: '${aspName}-resource'
  params: {
    name: aspName
    location: location
    tags: tags
  }
}

module webAppName_resource 'nested/microsoft.web/sites.bicep' = {
  name: '${webAppName}-resource'
  params: {
    name: webAppName
    hostingPlanName: aspName
    location: location
    tags: tags
  }
  dependsOn: [
    aspName_resource
  ]
}

module webAppName_connectionStrings_resource 'nested/microsoft.web/sites.config.connectionstrings.bicep' = {
  name: '${webAppName}-connectionStrings-resource'
  params: {
    webAppName: webAppName
    location: location
    connectionType: appServiceConnectionType
    connectionString: reference('${databases[0].name}-database-resource').outputs.dbConnetcionString.value
  }
  dependsOn: [
    webAppName_resource
    databases_0_name_database_resource
  ]
}

module webAppName_msdeploy_resource 'nested/microsoft.web/sites.extensions.msdeploy.bicep' = {
  name: '${webAppName}-msdeploy-resource'
  params: {
    webAppName: webAppName
    location: location
    packageUri: webPackageUri
    tags: tags
  }
  dependsOn: [
    webAppName_connectionStrings_resource
  ]
}

module sqlServerName_resource 'nested/microsoft.sql/servers.v12.0.bicep' = {
  name: '${sqlServerName}-resource'
  params: {
    sqlServerName: sqlServerName
    location: location
    administratorLogin: sqlAdministratorName
    administratorLoginPassword: sqlServerPassword
    tags: tags
  }
}

module sqlServerName_auditingSettings_resource 'nested/microsoft.sql/servers.auditingsettings.bicep' = {
  name: '${sqlServerName}-auditingSettings-resource'
  params: {
    sqlServerName: sqlServerName
    storageAccountName: diagStorageAccName
  }
  dependsOn: [
    sqlServerName_resource
    diagStorageAccName_resource
  ]
}

module sqlServerName_securityAlertPolicies_resource 'nested/microsoft.sql/servers.securityalertpolicies.bicep' = {
  name: '${sqlServerName}-securityAlertPolicies-resource'
  params: {
    sqlServerName: sqlServerName
    storageAccountName: diagStorageAccName
    sendAlertsTo: emailToSendAlertsTo
  }
  dependsOn: [
    sqlServerName_auditingSettings_resource
  ]
}

module databases_0_name_database_resource 'nested/microsoft.sql/servers.databases.bicep' = {
  name: '${databases[0].name}-database-resource'
  params: {
    sqlServerName: sqlServerName
    location: location
    databaseName: databases[0].name
    omsWorkspaceResourceId: reference('deploy-xss-attack-oms-resource').outputs.workspaceId.value
    tags: tags
    administratorLogin: sqlAdministratorName
    administratorLoginPassword: sqlServerPassword
    bacpacuri: 'https://templatebotstorage.blob.core.windows.net/bacpacs/contosoclinic.bacpac'
    edition: databases[0].edition
  }
  dependsOn: [
    sqlServerName_resource
  ]
}