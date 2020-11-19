param appName string {
  metadata: {
    description: 'Name of azure web app'
  }
}
param appServiceTier string {
  allowed: [
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'Choose either Standard or Premium Azure Web Apps pricing tiers. It defaults to Standard'
  }
  default: 'Standard'
}
param appServiceWorkerSize string {
  allowed: [
    '0'
    '1'
    '2'
  ]
  metadata: {
    description: 'Worker Size( 0=Small, 1=Medium, 2=Large )'
  }
  default: '0'
}
param dbServerName string {
  metadata: {
    description: 'SQL Azure DB Server name'
  }
}
param dbAdministratorLogin string {
  metadata: {
    description: 'SQL Azure DB administrator  user login'
  }
}
param dbAdministratorLoginPassword string {
  metadata: {
    description: 'Database admin user password'
  }
  secure: true
}
param dbName string {
  metadata: {
    description: 'Database Name'
  }
}
param dbEdition string {
  allowed: [
    'Basic'
    'Standard'
    'Premium'
  ]
  metadata: {
    description: 'SQL DB appServiceTier : Basic,Standard,Premium'
  }
  default: 'Standard'
}
param nonAdminDatabaseUsername string {
  metadata: {
    description: 'Non-admin Database User. Must be Unique'
  }
}
param nonAdminDatabasePassword string {
  metadata: {
    description: 'Non-admin Database User password'
  }
  secure: true
}
param storageAccountType string {
  allowed: [
    'Standard_LRS'
    'Standard_GRS'
    'Standard_RAGRS'
    'Standard_ZRS'
  ]
  metadata: {
    description: 'Storage Account Type : Standard-LRS, Standard-GRS,Standard-RAGRS,Standard-ZRS'
  }
  default: 'Standard_LRS'
}
param redisCacheName string {
  metadata: {
    description: 'Redis Cache Name'
  }
}
param redisCacheServiceTier string {
  allowed: [
    'Basic'
    'Standard'
  ]
  metadata: {
    description: 'Redis Cache appServiceTier - Basic , Standard'
  }
  default: 'Standard'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var appInsightsRegion = location
var storageAccountName_var = '${uniqueString(resourceGroup().id)}standardsa'
var umbracoAdminWebAppName_var = '${appName}adminapp'
var appServicePlanName_var = '${appName}serviceplan'

resource redisCacheName_res 'Microsoft.Cache/Redis@2014-04-01-preview' = {
  name: redisCacheName
  location: location
  properties: {
    sku: {
      name: redisCacheServiceTier
      family: 'C'
      capacity: 0
    }
    redisVersion: '2.8'
    enableNonSslPort: true
  }
}

resource dbServerName_res 'Microsoft.Sql/servers@2014-04-01-preview' = {
  name: dbServerName
  location: location
  properties: {
    administratorLogin: dbAdministratorLogin
    administratorLoginPassword: dbAdministratorLoginPassword
    version: '12.0'
  }
}

resource dbServerName_dbName 'Microsoft.Sql/servers/databases@2014-04-01-preview' = {
  name: '${dbServerName}/${dbName}'
  location: location
  properties: {
    edition: dbEdition
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    requestedServiceObjectiveId: 'F1173C43-91BD-4AAA-973C-54E79E15235B'
  }
}

resource dbServerName_AllowAllWindowsAzureIps 'Microsoft.Sql/servers/firewallrules@2014-04-01-preview' = {
  name: '${dbServerName}/AllowAllWindowsAzureIps'
  location: location
  properties: {
    endIpAddress: '0.0.0.0'
    startIpAddress: '0.0.0.0'
  }
}

resource storageAccountName 'Microsoft.Storage/storageAccounts@2015-05-01-preview' = {
  name: storageAccountName_var
  location: location
  properties: {
    accountType: storageAccountType
  }
}

resource appServicePlanName 'Microsoft.Web/serverfarms@2014-06-01' = {
  name: appServicePlanName_var
  location: location
  properties: {
    name: appServicePlanName_var
    appServiceTier: appServiceTier
    workerSize: appServiceWorkerSize
    hostingEnvironment: ''
    numberOfWorkers: 1
  }
}

resource appName_res 'Microsoft.Web/Sites@2015-02-01' = {
  name: appName
  location: location
  tags: {
    'hidden-related:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'empty'
  }
  properties: {
    name: appName
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
    hostingEnvironment: ''
  }
}

resource appName_MSDeploy 'Microsoft.Web/Sites/Extensions@2014-06-01' = {
  name: '${appName}/MSDeploy'
  properties: {
    packageUri: 'https://auxmktplceprod.blob.core.windows.net/packages/ScalableUmbracoCms.WebPI.7.4.3.zip'
    dbType: 'SQL'
    connectionString: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${dbServerName}').fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
    setParameters: {
      'Application Path': appName
      'Database Server': reference('Microsoft.Sql/servers/${dbServerName}').fullyQualifiedDomainName
      'Database Name': dbName
      'Database Username': nonAdminDatabaseUsername
      'Database Password': nonAdminDatabasePassword
      'Database Administrator': dbAdministratorLogin
      'Database Administrator Password': dbAdministratorLoginPassword
      azurestoragerootUrl: 'https://${storageAccountName_var}.blob.core.windows.net'
      azurestoragecontainerName: 'media'
      azurestorageconnectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2015-05-01-preview').key1}'
      rediscachehost: '${redisCacheName}.redis.cache.windows.net'
      rediscacheport: '6379'
      rediscacheaccessKey: listKeys(redisCacheName_res.id, '2014-04-01').primaryKey
      azurestoragecacheControl: '*|public, max-age=31536000;js|no-cache'
    }
  }
}

resource appName_connectionstrings 'Microsoft.Web/Sites/config@2015-04-01' = {
  name: '${appName}/connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${dbServerName}').fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
}

resource appName_web 'Microsoft.Web/Sites/config@2014-06-01' = {
  name: '${appName}/web'
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

resource appServicePlanName_scaleset 'microsoft.insights/autoscalesettings@2014-04-01' = {
  name: '${appServicePlanName_var}-scaleset'
  location: appInsightsRegion
  tags: {
    'hidden-link:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'Resource'
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
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
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
              metricResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
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
    targetResourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
  }
}

resource ServerErrors_appName 'microsoft.insights/alertrules@2014-04-01' = {
  name: 'ServerErrors ${appName}'
  location: appInsightsRegion
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${appName}': 'Resource'
  }
  properties: {
    name: 'ServerErrors ${appName}'
    description: '${appName} has some server errors, status code 5xx.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/sites/${appName}'
        metricName: 'Http5xx'
      }
      operator: 'GreaterThan'
      threshold: 0
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
}

resource ForbiddenRequests_appName 'microsoft.insights/alertrules@2014-04-01' = {
  name: 'ForbiddenRequests ${appName}'
  location: appInsightsRegion
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${appName}': 'Resource'
  }
  properties: {
    name: 'ForbiddenRequests ${appName}'
    description: '${appName} has some requests that are forbidden, status code 403.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/sites/${appName}'
        metricName: 'Http403'
      }
      operator: 'GreaterThan'
      threshold: 0
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
}

resource CPUHigh_appServicePlanName 'microsoft.insights/alertrules@2014-04-01' = {
  name: 'CPUHigh ${appServicePlanName_var}'
  location: appInsightsRegion
  tags: {
    'hidden-link:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'Resource'
  }
  properties: {
    name: 'CPUHigh ${appServicePlanName_var}'
    description: 'The average CPU is high across all the instances of ${appServicePlanName_var}'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
        metricName: 'CpuPercentage'
      }
      operator: 'GreaterThan'
      threshold: 90
      windowSize: 'PT15M'
    }
    action: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
}

resource LongHttpQueue_appServicePlanName 'microsoft.insights/alertrules@2014-04-01' = {
  name: 'LongHttpQueue ${appServicePlanName_var}'
  location: appInsightsRegion
  tags: {
    'hidden-link:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'Resource'
  }
  properties: {
    name: 'LongHttpQueue ${appServicePlanName_var}'
    description: 'The HTTP queue for the instances of ${appServicePlanName_var} has a large number of pending requests.'
    isEnabled: false
    condition: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.ThresholdRuleCondition'
      dataSource: {
        'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleMetricDataSource'
        resourceUri: '${resourceGroup().id}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
        metricName: 'HttpQueueLength'
      }
      operator: 'GreaterThan'
      threshold: 100
      windowSize: 'PT5M'
    }
    action: {
      'odata.type': 'Microsoft.WindowsAzure.Management.Monitoring.Alerts.Models.RuleEmailAction'
      sendToServiceOwners: true
      customEmails: []
    }
  }
}

resource appName_appin 'microsoft.insights/components@2014-04-01' = {
  name: '${appName}-appin'
  location: appInsightsRegion
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${appName}': 'Resource'
  }
  properties: {
    applicationId: appName
  }
}

resource umbracoAdminWebAppName 'Microsoft.Web/Sites@2015-02-01' = {
  name: umbracoAdminWebAppName_var
  location: location
  tags: {
    'hidden-related:/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}': 'empty'
  }
  properties: {
    name: umbracoAdminWebAppName_var
    serverFarmId: '/subscriptions/${subscription().subscriptionId}/resourcegroups/${resourceGroup().name}/providers/Microsoft.Web/serverfarms/${appServicePlanName_var}'
    hostingEnvironment: ''
  }
}

resource umbracoAdminWebAppName_MSDeploy 'Microsoft.Web/Sites/Extensions@2014-06-01' = {
  name: '${umbracoAdminWebAppName_var}/MSDeploy'
  properties: {
    packageUri: 'https://auxmktplceprod.blob.core.windows.net/packages/ScalableUmbracoCms.WebPI.7.4.3.zip'
    dbType: 'SQL'
    connectionString: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${dbServerName}').fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
    setParameters: {
      'Application Path': umbracoAdminWebAppName_var
      'Database Server': reference('Microsoft.Sql/servers/${dbServerName}').fullyQualifiedDomainName
      'Database Name': dbName
      'Database Username': '${nonAdminDatabaseUsername}admin'
      'Database Password': nonAdminDatabasePassword
      'Database Administrator': dbAdministratorLogin
      'Database Administrator Password': dbAdministratorLoginPassword
      azurestoragerootUrl: 'https://${storageAccountName_var}.blob.core.windows.net'
      azurestoragecontainerName: 'media'
      azurestorageconnectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName_var};AccountKey=${listKeys('Microsoft.Storage/storageAccounts/${storageAccountName_var}', '2015-05-01-preview').key1}'
      rediscachehost: '${redisCacheName}.redis.cache.windows.net'
      rediscacheport: '6379'
      rediscacheaccessKey: listKeys(redisCacheName_res.id, '2014-04-01').primaryKey
      azurestoragecacheControl: '*|public, max-age=31536000;js|no-cache'
    }
  }
}

resource umbracoAdminWebAppName_connectionstrings 'Microsoft.Web/Sites/config@2015-04-01' = {
  name: '${umbracoAdminWebAppName_var}/connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Data Source=tcp:${reference('Microsoft.Sql/servers/${dbServerName}').fullyQualifiedDomainName},1433;Initial Catalog=${dbName};User Id=${dbAdministratorLogin}@${dbServerName};Password=${dbAdministratorLoginPassword};'
      type: 'SQLAzure'
    }
  }
}

resource umbracoAdminWebAppName_web 'Microsoft.Web/Sites/config@2014-06-01' = {
  name: '${umbracoAdminWebAppName_var}/web'
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