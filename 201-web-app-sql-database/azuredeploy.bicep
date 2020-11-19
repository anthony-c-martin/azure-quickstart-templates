param skuName string {
  allowed: [
    'F1'
    'D1'
    'B1'
    'B2'
    'B3'
    'S1'
    'S2'
    'S3'
    'P1'
    'P2'
    'P3'
    'P4'
  ]
  metadata: {
    description: 'Describes plan\'s pricing tier and instance size. Check details at https://azure.microsoft.com/en-us/pricing/details/app-service/'
  }
  default: 'F1'
}
param skuCapacity int {
  minValue: 1
  maxValue: 3
  metadata: {
    description: 'Describes plan\'s instance count'
  }
  default: 1
}
param sqlAdministratorLogin string {
  metadata: {
    description: 'The admin user of the SQL Server'
  }
}
param sqlAdministratorLoginPassword string {
  metadata: {
    description: 'The password of the admin user of the SQL Server'
  }
  secure: true
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var hostingPlanName_var = 'hostingplan${uniqueString(resourceGroup().id)}'
var webSiteName_var = 'webSite${uniqueString(resourceGroup().id)}'
var sqlserverName_var = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName = 'sampledb'

resource sqlserverName 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlserverName_var
  location: location
  tags: {
    displayName: 'SqlServer'
  }
  properties: {
    administratorLogin: sqlAdministratorLogin
    administratorLoginPassword: sqlAdministratorLoginPassword
    version: '12.0'
  }
}

resource sqlserverName_databaseName 'Microsoft.Sql/servers/databases@2020-02-02-preview' = {
  name: '${sqlserverName_var}/${databaseName}'
  location: location
  tags: {
    displayName: 'Database'
  }
  properties: {
    edition: 'Basic'
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    maxSizeBytes: '1073741824'
    requestedServiceObjectiveName: 'Basic'
  }
}

resource sqlserverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  location: location
  name: '${sqlserverName_var}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource hostingPlanName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName_var
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName_var
  }
}

resource webSiteName 'Microsoft.Web/sites@2019-08-01' = {
  name: webSiteName_var
  location: location
  tags: {
    'hidden-related:${hostingPlanName.id}': 'empty'
    displayName: 'Website'
  }
  properties: {
    name: webSiteName_var
    serverFarmId: hostingPlanName.id
  }
}

resource webSiteName_connectionstrings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${webSiteName_var}/connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Data Source=tcp:${sqlserverName.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${sqlAdministratorLogin}@${sqlserverName.properties.fullyQualifiedDomainName};Password=${sqlAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
  dependsOn: [
    webSiteName_var
  ]
}

resource AppInsights_webSiteName 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'AppInsights${webSiteName_var}'
  location: location
  tags: {
    'hidden-link:${webSiteName.id}': 'Resource'
    displayName: 'AppInsightsComponent'
  }
  properties: {
    ApplicationId: webSiteName_var
    Application_Type: 'web'
  }
  dependsOn: [
    webSiteName_var
  ]
}