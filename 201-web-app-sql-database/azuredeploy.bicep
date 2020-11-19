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

var hostingPlanName = 'hostingplan${uniqueString(resourceGroup().id)}'
var webSiteName = 'webSite${uniqueString(resourceGroup().id)}'
var sqlserverName = 'sqlserver${uniqueString(resourceGroup().id)}'
var databaseName = 'sampledb'

resource sqlserverName_resource 'Microsoft.Sql/servers@2020-02-02-preview' = {
  name: sqlserverName
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
  name: '${sqlserverName}/${databaseName}'
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
  dependsOn: [
    sqlserverName_resource
  ]
}

resource sqlserverName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2020-02-02-preview' = {
  location: location
  name: '${sqlserverName}/AllowAllWindowsAzureIps'
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
  dependsOn: [
    sqlserverName_resource
  ]
}

resource hostingPlanName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: hostingPlanName
  location: location
  tags: {
    displayName: 'HostingPlan'
  }
  sku: {
    name: skuName
    capacity: skuCapacity
  }
  properties: {
    name: hostingPlanName
  }
}

resource webSiteName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: webSiteName
  location: location
  tags: {
    'hidden-related:${hostingPlanName_resource.id}': 'empty'
    displayName: 'Website'
  }
  properties: {
    name: webSiteName
    serverFarmId: hostingPlanName_resource.id
  }
  dependsOn: [
    hostingPlanName_resource
  ]
}

resource webSiteName_connectionstrings 'Microsoft.Web/sites/config@2019-08-01' = {
  name: '${webSiteName}/connectionstrings'
  properties: {
    DefaultConnection: {
      value: 'Data Source=tcp:${sqlserverName_resource.properties.fullyQualifiedDomainName},1433;Initial Catalog=${databaseName};User Id=${sqlAdministratorLogin}@${sqlserverName_resource.properties.fullyQualifiedDomainName};Password=${sqlAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
  dependsOn: [
    webSiteName
  ]
}

resource AppInsights_webSiteName 'Microsoft.Insights/components@2020-02-02-preview' = {
  name: 'AppInsights${webSiteName}'
  location: location
  tags: {
    'hidden-link:${webSiteName_resource.id}': 'Resource'
    displayName: 'AppInsightsComponent'
  }
  properties: {
    ApplicationId: webSiteName
    Application_Type: 'web'
  }
  dependsOn: [
    webSiteName
  ]
}