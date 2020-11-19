param jenkinsVMAdminUsername string {
  minLength: 1
  metadata: {
    description: 'User name for the Jenkins Virtual Machine.'
  }
}
param jenkinsDnsPrefix string {
  minLength: 3
  metadata: {
    description: 'Unique DNS Name for the Public IP used to access the Jenkins Virtual Machine.'
  }
}
param jenkinsReleaseType string {
  allowed: [
    'LTS'
    'weekly'
    'verified'
  ]
  metadata: {
    description: 'The Jenkins release type.'
  }
  default: 'LTS'
}
param repositoryUrl string {
  minLength: 1
  metadata: {
    description: 'GitHub repository URL for the source code.'
  }
  default: 'https://github.com/Azure/azure-quickstart-templates'
}
param clientId string {
  minLength: 1
  metadata: {
    description: 'Client id for Azure service principal.'
  }
}
param clientSecret string {
  minLength: 1
  metadata: {
    description: 'Client secret for Azure service principal.'
  }
}
param appDnsPrefix string {
  minLength: 3
  metadata: {
    description: 'Prefix name for web app components, accepts numbers and letters only.'
  }
}
param mySqlAdminLogin string {
  minLength: 3
  metadata: {
    description: 'User name for MySQL admin login.'
  }
}
param mySqlAdminPassword string {
  minLength: 6
  metadata: {
    description: 'Password for MySQL admin login.'
  }
  secure: true
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/jenkins-cicd-webapp/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param authenticationType string {
  allowed: [
    'sshPublicKey'
    'password'
  ]
  metadata: {
    description: 'Type of authentication to use on the Virtual Machine. SSH key is recommended.'
  }
  default: 'sshPublicKey'
}
param adminPasswordOrKey string {
  metadata: {
    description: 'SSH Key or password for the Virtual Machine. SSH key is recommended.'
  }
  secure: true
}

var storageAccountName = '${toLower(appDnsPrefix)}storage'
var servicePlanName = '${appDnsPrefix}ServicePlan'
var webAppName = '${appDnsPrefix}Web'
var appInsightsName = '${appDnsPrefix}AppInsights'
var mySqlServerName = '${toLower(appDnsPrefix)}mysqlserver'
var mySqlDbName = '${toLower(appDnsPrefix)}mysqldb'

resource storageAccountName_resource 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'Storage'
  name: storageAccountName
  location: location
  properties: {}
}

resource servicePlanName_resource 'Microsoft.Web/serverfarms@2016-09-01' = {
  sku: {
    name: 'B1'
  }
  kind: 'app'
  name: servicePlanName
  location: location
  properties: {
    name: servicePlanName
  }
}

resource webAppName_resource 'Microsoft.Web/sites@2016-08-01' = {
  kind: 'app'
  name: webAppName
  location: location
  properties: {
    serverFarmId: servicePlanName_resource.id
  }
  dependsOn: [
    servicePlanName_resource
  ]
}

resource webAppName_web 'Microsoft.Web/sites/config@2016-08-01' = {
  name: '${webAppName}/web'
  location: location
  properties: {
    javaVersion: '1.8'
    javaContainer: 'TOMCAT'
    javaContainerVersion: '9.0'
  }
  dependsOn: [
    webAppName_resource
  ]
}

resource webAppName_connectionstrings 'Microsoft.Web/sites/config@2016-08-01' = {
  name: '${webAppName}/connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Database=${mySqlDbName};Data Source=${mySqlServerName_resource.properties.fullyQualifiedDomainName};User Id=${mySqlAdminLogin}@${mySqlServerName};Password=${mySqlAdminPassword}'
      type: 'MySql'
    }
  }
  dependsOn: [
    webAppName_resource
  ]
}

resource appInsightsName_resource 'microsoft.insights/components@2015-05-01' = {
  kind: 'java'
  name: appInsightsName
  location: 'eastus'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${webAppName}': 'Resource'
  }
  properties: {
    ApplicationId: appInsightsName
  }
}

resource mySqlServerName_resource 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  location: location
  name: mySqlServerName
  properties: {
    version: '5.7'
    storageMB: 51200
    administratorLogin: mySqlAdminLogin
    administratorLoginPassword: mySqlAdminPassword
  }
  sku: {
    name: 'B_Gen5_2'
    tier: 'Basic'
    capacity: 2
  }
}

resource mySqlServerName_mySqlServerName_Firewall 'Microsoft.DBforMySQL/servers/firewallrules@2017-12-01' = {
  location: location
  name: '${mySqlServerName}/${mySqlServerName}Firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
  dependsOn: [
    mySqlServerName_resource
  ]
}

resource mySqlServerName_mySqlDbName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  name: '${mySqlServerName}/${mySqlDbName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
  dependsOn: [
    mySqlServerName_resource
  ]
}

module jenkinsDeployment '<failed to parse [uri(parameters(\'_artifactsLocation\'), concat(\'nested/jenkins.json\', parameters(\'_artifactsLocationSasToken\')))]>' = {
  name: 'jenkinsDeployment'
  params: {
    adminUsername: jenkinsVMAdminUsername
    dnsPrefix: jenkinsDnsPrefix
    jenkinsReleaseType: jenkinsReleaseType
    repositoryUrl: repositoryUrl
    clientId: clientId
    clientSecret: clientSecret
    storageAccountName: storageAccountName
    storageAccountKey: listKeys(storageAccountName_resource.id, '2016-01-01').keys[0].value
    webAppName: webAppName
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    storageAccountName_resource
  ]
}

output jenkinsURL string = reference('jenkinsDeployment').outputs.jenkinsURL.value
output jenkinsSSH string = reference('jenkinsDeployment').outputs.jenkinsSSH.value
output webAppURL string = 'http://${reference(webAppName).defaultHostName}'