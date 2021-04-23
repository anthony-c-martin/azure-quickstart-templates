@description('Name of azure web app')
param appName string = 'umbraco${uniqueString(resourceGroup().id)}'

@allowed([
  'Standard'
  'Premium'
  'PremiumV2'
])
@description('Tier for Service Plan')
param servicePlanTier string = 'PremiumV2'

@allowed([
  'S1'
  'S2'
  'S3'
  'P1'
  'P2'
  'P3'
  'P1V2'
  'P2V2'
  'P3V3'
])
@description('Size for Service Plan')
param servicePlanSku string = 'P1V2'

@description('SQL Azure DB Server name')
param dbServerName string = 'umbraco${uniqueString(resourceGroup().id)}'

@description('SQL Azure DB administrator  user login')
param dbAdministratorLogin string

@description('Database admin user password')
@secure()
param dbAdministratorLoginPassword string

@description('Database Name')
param dbName string = 'umbraco-db'

@description('Non-admin Database User. Must be Unique')
param nonAdminDatabaseUserName string

@description('Non-admin Database User password')
@secure()
param nonAdminDatabasePassword string

@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_RAGRS'
  'Standard_ZRS'
])
@description('Storage Account Type : Standard-LRS, Standard-GRS,Standard-RAGRS,Standard-ZRS')
param storageAccountType string = 'Standard_LRS'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.')
param artifactsLocation string = deployment().properties.templateLink.uri

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var storageAccountName_var = '${uniqueString(resourceGroup().id)}standardsa'
var appServicePlanName_var = '${appName}serviceplan'

resource dbServerName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: dbServerName
  location: location
  properties: {
    administratorLogin: dbAdministratorLogin
    administratorLoginPassword: dbAdministratorLoginPassword
    version: '12.0'
  }
}

resource dbServerName_dbName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  parent: dbServerName_resource
  name: '${dbName}'
  location: location
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  kind: 'v12.0,user'
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
  }
}

resource dbServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  parent: dbServerName_resource
  name: 'AllowAllWindowsAzureIps'
  location: location
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource appServicePlanName 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: appServicePlanName_var
  location: location
  sku: {
    tier: servicePlanTier
    name: servicePlanSku
  }
  kind: 'linux'
  properties: {}
}

resource appName_resource 'Microsoft.Web/Sites@2020-06-01' = {
  name: appName
  location: location
  tags: {
    'hidden-related:${appServicePlanName.id}': 'empty'
  }
  properties: {
    name: appName
    serverFarmId: appServicePlanName.id
  }
}

resource appName_MSDeploy 'Microsoft.Web/Sites/Extensions@2020-06-01' = {
  parent: appName_resource
  name: 'MSDeploy'
  properties: {
    packageUri: uri(artifactsLocation, 'UmbracoCms.WebPI.7.4.3.zip${artifactsLocationSasToken}')
    dbType: 'SQL'
    connectionString: 'Data Source=tcp:${dbServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
    setParameters: {
      'Application Path': appName
      'Database Server': dbServerName_resource.properties.fullyQualifiedDomainName
      'Database Name': dbName
      'Database Username': nonAdminDatabaseUserName
      'Database Password': nonAdminDatabasePassword
      'Database Administrator': dbAdministratorLogin
      'Database Administrator Password': dbAdministratorLoginPassword
    }
  }
  dependsOn: [
    appName_web
    dbServerName_dbName
    storageAccountName
  ]
}

resource appName_connectionstrings 'Microsoft.Web/Sites/config@2020-06-01' = {
  parent: appName_resource
  name: 'connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Data Source=tcp:${dbServerName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
  dependsOn: [
    dbServerName_dbName
    appName_MSDeploy
  ]
}

resource appName_web 'Microsoft.Web/Sites/config@2020-06-01' = {
  parent: appName_resource
  name: 'web'
  properties: {
    phpVersion: 'off'
    netFrameworkVersion: 'v4.5'
    use32BitWorkerProcess: 'true'
    webSocketsEnabled: true
    alwaysOn: 'true'
    httpLoggingEnabled: true
    logsDirectorySizeLimit: 40
  }
}

resource appServicePlanName_scaleset 'microsoft.insights/autoscalesettings@2015-04-01' = {
  name: '${appServicePlanName_var}-scaleset'
  location: location
  tags: {
    'hidden-link:${appServicePlanName.id}': 'Resource'
  }
  properties: {
    profiles: [
      {
        name: 'Default'
        capacity: {
          minimum: '1'
          maximum: '2'
          default: '1'
        }
        rules: [
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanName.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT10M'
              timeAggregation: 'Average'
              operator: 'GreaterThan'
              threshold: 80
            }
            scaleAction: {
              direction: 'Increase'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT10M'
            }
          }
          {
            metricTrigger: {
              metricName: 'CpuPercentage'
              metricResourceUri: appServicePlanName.id
              timeGrain: 'PT1M'
              statistic: 'Average'
              timeWindow: 'PT1H'
              timeAggregation: 'Average'
              operator: 'LessThan'
              threshold: 60
            }
            scaleAction: {
              direction: 'Decrease'
              type: 'ChangeCount'
              value: '1'
              cooldown: 'PT1H'
            }
          }
        ]
      }
    ]
    enabled: false
    name: '${appServicePlanName_var}-scaleset'
    targetResourceUri: appServicePlanName.id
  }
}

resource appName_appin 'microsoft.insights/components@2020-02-02-preview' = {
  name: '${appName}-appin'
  location: location
  tags: {
    'hidden-link:${appName_resource.id}': 'Resource'
  }
  properties: {
    ApplicationId: appName
    Application_Type: 'web'
  }
}