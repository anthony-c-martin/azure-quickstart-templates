@description('The Azure Region which should be targeted while provisioning the infrastructure described in this template.')
param location string = resourceGroup().location

@description('The image which defines the application to be hosted in Azure.')
param imageName string = 'appsvc/sample-hello-world:latest'

@description('A unique name to identify the site, and its relate assets once it is created.')
param name string = 'site${uniqueString(resourceGroup().id, deployment().name)}'

@allowed([
  'none'
  'postgresql'
  'mysql'
])
@description('The flavor of database that should be deployed alongside this application.')
param database string = 'postgresql'

@description('The name that will identify the database which is created, should one be created.')
param databaseName string = 'buffalo_development'

@description('The user handle for the administrator of the database to be created.')
param databaseAdministratorLogin string = ''

@description('The password for the administrator of the database to be created.')
@secure()
param databaseAdministratorLoginPassword string = ''

@allowed([
  'public'
  'private'
])
@description('Denotes whether the image selected lives in a public or private Docker registry.')
param dockerRegistryAccess string = 'public'

@description('The url of the Docker registry which hosts the repository being used to host the image for your site.')
param dockerRegistryServerURL string = ''

@description('The user handle used to authenticate against the private Docker registry, if applicable.')
param dockerRegistryServerUsername string = ''

@description('The password used to authenticate against the private Docker registry, if applicable.')
@secure()
param dockerRegistryServerPassword string = ''

var hostingPlanName_var = 'hostingPlan-${name}'
var postgresqlName_var = '${name}-postgresql'
var mysqlName_var = '${name}-mysql'
var appSettingsPublicRegistry = [
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
]
var appSettingsPrivateRegistry = [
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: dockerRegistryServerURL
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_USERNAME'
    value: dockerRegistryServerUsername
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_PASSWORD'
    value: dockerRegistryServerPassword
  }
]

resource name_resource 'Microsoft.Web/sites@2018-02-01' = {
  name: name
  location: location
  tags: {
    'hidden-related:${subscription().id}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${hostingPlanName_var}': 'empty'
    gobuffalo: 'empty'
  }
  properties: {
    name: name
    siteConfig: {
      appSettings: ((dockerRegistryAccess == 'private') ? appSettingsPrivateRegistry : appSettingsPublicRegistry)
      connectionStrings: [
        {
          name: 'DATABASE_URL'
          connectionString: ((database == 'postgresql') ? 'postgres://${databaseAdministratorLogin}@${postgresqlName_var}:${databaseAdministratorLoginPassword}@${postgresqlName.properties.fullyQualifiedDomainName}:5432/${databaseName}' : ((database == 'mysql') ? 'mysql://${databaseAdministratorLogin}@${mysqlName_var}:${databaseAdministratorLoginPassword}@tcp(${mysqlName.properties.fullyQualifiedDomainName}:3306/${databaseName}?allowNativePasswords=true' : 'not applicable'))
          type: ((database == 'mysql') ? 'mysql' : 'custom')
        }
      ]
      appCommandLine: ''
      linuxFxVersion: 'DOCKER|${imageName}'
    }
    serverFarmId: hostingPlanName.id
    hostingEnvironment: ''
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2016-09-01' = {
  sku: {
    tier: 'Basic'
    name: 'B1'
  }
  kind: 'linux'
  name: hostingPlanName_var
  location: location
  properties: {
    name: hostingPlanName_var
    workerSizeId: '0'
    reserved: true
    numberOfWorkers: '1'
    hostingEnvironment: ''
  }
}

resource postgresqlName 'Microsoft.DBforPostgreSQL/servers@2017-12-01-preview' = if (database == 'postgresql') {
  sku: {
    name: 'B_Gen5_1'
    family: 'Gen5'
    capacity: ''
    size: '5120'
    tier: 'Basic'
  }
  kind: ''
  name: postgresqlName_var
  location: location
  properties: {
    version: '9.6'
    administratorLogin: databaseAdministratorLogin
    administratorLoginPassword: databaseAdministratorLoginPassword
    sslEnforcement: 'Disabled'
  }
}

resource postgresqlName_AllowAzureIPs 'Microsoft.DBforPostgreSQL/servers/firewallRules@2017-12-01-preview' = if (database == 'postgresql') {
  parent: postgresqlName
  location: location
  name: 'AllowAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource mysqlName 'Microsoft.DBforMySQL/servers@2017-12-01-preview' = if (database == 'mysql') {
  sku: {
    name: 'B_Gen5_2'
    tier: 'Basic'
    capacity: 2
    size: 5120
    family: 'Gen5'
  }
  kind: ''
  name: mysqlName_var
  location: location
  properties: {
    version: '5.7'
    administratorLogin: databaseAdministratorLogin
    administratorLoginPassword: databaseAdministratorLoginPassword
    storageProfile: {
      storageMB: 5120
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    sslEnforcement: 'Disabled'
  }
}

resource mysqlName_AllowAzureIPs 'Microsoft.DBforMySQL/servers/firewallRules@2017-12-01-preview' = if (database == 'mysql') {
  parent: mysqlName
  location: location
  name: 'AllowAzureIPs'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}