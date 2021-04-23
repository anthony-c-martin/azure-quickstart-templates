@description('this will be the location for artifacts')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-SQL-Injection-Attack-Prevention/'

@description('this will be the sas key to access artifacts')
@secure()
param artifactsLocationSasToken string = ''

@description('your resources will be created in this location')
param location string = resourceGroup().location

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
@description('this will be the type of public IP address used for the VM name')
param pipAddressType string = 'dynamic'

@description('this will be the admin user for sql server')
param sqlAdministratorName string

@description('this will be the password for the admin user of sql server')
@secure()
param sqlServerPassword string

@description('this user will get the alert emails')
param emailToSendAlertsTo string = 'dummy@contoso.com'

@description('The uri to the Contoso Clinic BacPac - must be hosted in Azure Storage, use the defaultValue if deploying from QuickStarts.')
param bacpacUri string = ((environment().name == 'AzureUSGovernment') ? 'https://azbotstorageus.blob.core.usgovcloudapi.net/bacpacs/contosoclinic.bacpac' : 'https://azbotstorage.blob.core.windows.net/bacpacs/contosoclinic.bacpac')

@description('The sasToken needed to access the Contoso Clinic BacPac - use the defaultValue of \'?\' if the file is not secured')
@secure()
param bacpacUriSasToken string = '?'

var omsWorkspaceName = 'sql-injection-oms-${uniqueString(resourceGroup().id)}'
var omsSolutions = [
  'Security'
  'AzureActivity'
  'AzureWebAppsAnalytics'
  'AzureSQLAnalytics'
  'AzureAppGatewayAnalytics'
]
var tags = {
  scenario: 'SQL-Injection-Attack-Prevention'
}
var vNetName = 'sql-appgw-vnet'
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
var httpProbeName = 'aseProbeHTTP'
var httpsProbeName = 'aseProbeHTTPS'
var diagStorageAccName = 'sqlinjectionstg${substring(uniqueString(resourceGroup().id), 0, 5)}'
var webAppName = 'sql-injection-webapp-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var aspName = 'sql-injection-asp-${substring(uniqueString(resourceGroup().id), 0, 5)}'
var appServiceConnectionType = 'SQLAzure'
var sqlServerName = 'sqlinjectionserver${substring(uniqueString(resourceGroup().id), 0, 5)}'
var database = {
  name: 'contosoclinic'
  edition: 'Standard'
}
var omsTemplateUri = uri(artifactsLocation, 'nested/microsoft.loganalytics/workspaces.json${artifactsLocationSasToken}')
var vnetTemplateUri = uri(artifactsLocation, 'nested/microsoft.network/virtualnetworks.json${artifactsLocationSasToken}')
var pipTemplateUri = uri(artifactsLocation, 'nested/microsoft.network/publicipaddress.json${artifactsLocationSasToken}')
var appgwTemplateUri = uri(artifactsLocation, 'nested/microsoft.network/applicationgateways.json${artifactsLocationSasToken}')
var storageTemplateUri = uri(artifactsLocation, 'nested/microsoft.storage/storageaccounts.storage.json${artifactsLocationSasToken}')
var webappTemplateUri = uri(artifactsLocation, 'nested/microsoft.web/sites.json${artifactsLocationSasToken}')
var aspTemplateUri = uri(artifactsLocation, 'nested/microsoft.web/serverfarms.json${artifactsLocationSasToken}')
var webappConnectionStringTemplateUri = uri(artifactsLocation, 'nested/microsoft.web/sites.config.connectionstrings.json${artifactsLocationSasToken}')
var webappMsDeployTemplateUri = uri(artifactsLocation, 'nested/microsoft.web/sites.extensions.msdeploy.json${artifactsLocationSasToken}')
var webPackageUri = uri(artifactsLocation, 'artifacts/ContosoClinic.zip${artifactsLocationSasToken}')
var sqlServerTemplateUri = uri(artifactsLocation, 'nested/microsoft.sql/servers.v12.0.json${artifactsLocationSasToken}')
var sqlDatabaseTemplateUri = uri(artifactsLocation, 'nested/microsoft.sql/servers.databases.json${artifactsLocationSasToken}')
var sqlAuditingTemplateUri = uri(artifactsLocation, 'nested/microsoft.sql/servers.auditingsettings.json${artifactsLocationSasToken}')
var sqlSecurityTemplateUri = uri(artifactsLocation, 'nested/microsoft.sql/servers.securityalertpolicies.json${artifactsLocationSasToken}')

module deploy_sql_injection_attack_oms_resource '?' /*TODO: replace with correct path to [variables('omsTemplateUri')]*/ = {
  name: 'deploy-sql-injection-attack-oms-resource'
  params: {
    omsWorkspaceName: omsWorkspaceName
    omsSolutionsName: omsSolutions
    sku: omsSku
    location: location
    tags: tags
  }
}

module vnetName_resource '?' /*TODO: replace with correct path to [variables('vnetTemplateUri')]*/ = {
  name: '${vNetName}-resource'
  params: {
    vnetName: vNetName
    addressPrefix: vNetAddressSpace
    subnets: subnets
    location: location
    tags: tags
  }
}

module applicationGateways_name_pip_resource '?' /*TODO: replace with correct path to [variables('pipTemplateUri')]*/ = [for i in range(0, 2): {
  name: '${applicationGateways[i].name}-pip-resource'
  params: {
    publicIPAddressName: '${applicationGateways[i].name}-pip'
    publicIPAddressType: pipAddressType
    dnsNameForPublicIP: '${applicationGateways[i].name}-${uniqueString(resourceGroup().id, 'pip')}-pip'
    location: location
    tags: tags
  }
}]

module deploy_applicationGateways_name_applicationgateway '?' /*TODO: replace with correct path to [variables('appgwTemplateUri')]*/ = [for i in range(0, 2): {
  name: 'deploy-${applicationGateways[i].name}-applicationgateway'
  params: {
    applicationGatewayName: applicationGateways[i].name
    publicIPRef: reference(resourceId('Microsoft.Resources/deployments', '${applicationGateways[i].name}-pip-resource')).outputs.publicIPRef.value
    location: location
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
              fqdn: webAppName_resource.properties.outputs.endpoint.value
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
          host: webAppName_resource.properties.outputs.endpoint.value
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
          host: webAppName_resource.properties.outputs.endpoint.value
          path: '/'
          interval: 30
          timeout: 30
          unhealthyThreshold: 8
        }
      }
    ]
    wafMode: applicationGateways[i].wafMode
    omsWorkspaceResourceId: reference('deploy-sql-injection-attack-oms-resource').outputs.workspaceId.value
  }
  dependsOn: [
    applicationGateways_name_pip_resource
    vnetName_resource
  ]
}]

module diagStorageAccName_resource '?' /*TODO: replace with correct path to [variables('storageTemplateUri')]*/ = {
  name: '${diagStorageAccName}-resource'
  params: {
    storageAccountName: diagStorageAccName
    location: location
    tags: tags
  }
}

module aspName_resource '?' /*TODO: replace with correct path to [variables('aspTemplateUri')]*/ = {
  name: '${aspName}-resource'
  params: {
    name: aspName
    location: location
    tags: tags
  }
}

module webAppName_resource '?' /*TODO: replace with correct path to [variables('webappTemplateUri')]*/ = {
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

module webAppName_connectionStrings_resource '?' /*TODO: replace with correct path to [variables('webappConnectionStringTemplateUri')]*/ = {
  name: '${webAppName}-connectionStrings-resource'
  params: {
    webAppName: webAppName
    location: location
    connectionType: appServiceConnectionType
    connectionString: 'Data Source=tcp:${sqlServerName_resource.properties.outputs.fqdn.value},1433;Initial Catalog=${database.name};User Id=${sqlAdministratorName};Password=${sqlServerPassword};Connection Timeout=300;'
  }
  dependsOn: [
    webAppName_resource
    database_name_database_resource
  ]
}

module webAppName_msdeploy_resource '?' /*TODO: replace with correct path to [variables('webappMsDeployTemplateUri')]*/ = {
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

module sqlServerName_resource '?' /*TODO: replace with correct path to [variables('sqlServerTemplateUri')]*/ = {
  name: '${sqlServerName}-resource'
  params: {
    sqlServerName: sqlServerName
    location: location
    administratorLogin: sqlAdministratorName
    administratorLoginPassword: sqlServerPassword
    tags: tags
  }
}

module sqlServerName_auditingSettings_resource '?' /*TODO: replace with correct path to [variables('sqlAuditingTemplateUri')]*/ = {
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

module sqlServerName_securityAlertPolicies_resource '?' /*TODO: replace with correct path to [variables('sqlSecurityTemplateUri')]*/ = {
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

module database_name_database_resource '?' /*TODO: replace with correct path to [variables('sqlDatabaseTemplateUri')]*/ = {
  name: '${database.name}-database-resource'
  params: {
    sqlServerName: sqlServerName
    location: location
    databaseName: database.name
    omsWorkspaceResourceId: reference('deploy-sql-injection-attack-oms-resource').outputs.workspaceId.value
    tags: tags
    administratorLogin: sqlAdministratorName
    administratorLoginPassword: sqlServerPassword
    bacpacuri: bacpacUri
    bacpacUriSasToken: bacpacUriSasToken
    edition: database.edition
  }
  dependsOn: [
    sqlServerName_resource
  ]
}