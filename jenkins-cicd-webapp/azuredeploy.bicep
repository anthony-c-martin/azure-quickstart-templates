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

var storageAccountName_var = '${toLower(appDnsPrefix)}storage'
var servicePlanName_var = '${appDnsPrefix}ServicePlan'
var webAppName_var = '${appDnsPrefix}Web'
var appInsightsName_var = '${appDnsPrefix}AppInsights'
var mySqlServerName_var = '${toLower(appDnsPrefix)}mysqlserver'
var mySqlDbName = '${toLower(appDnsPrefix)}mysqldb'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2017-06-01' = {
  sku: {
    name: 'Standard_RAGRS'
  }
  kind: 'Storage'
  name: storageAccountName_var
  location: location
  properties: {}
}

resource servicePlanName 'Microsoft.Web/serverfarms@2016-09-01' = {
  sku: {
    name: 'B1'
  }
  kind: 'app'
  name: servicePlanName_var
  location: location
  properties: {
    name: servicePlanName_var
  }
}

resource webAppName 'Microsoft.Web/sites@2016-08-01' = {
  kind: 'app'
  name: webAppName_var
  location: location
  properties: {
    serverFarmId: servicePlanName.id
  }
}

resource webAppName_web 'Microsoft.Web/sites/config@2016-08-01' = {
  name: '${webAppName_var}/web'
  location: location
  properties: {
    javaVersion: '1.8'
    javaContainer: 'TOMCAT'
    javaContainerVersion: '9.0'
  }
}

resource webAppName_connectionstrings 'Microsoft.Web/sites/config@2016-08-01' = {
  name: '${webAppName_var}/connectionstrings'
  properties: {
    defaultConnection: {
      value: 'Database=${mySqlDbName};Data Source=${mySqlServerName.properties.fullyQualifiedDomainName};User Id=${mySqlAdminLogin}@${mySqlServerName_var};Password=${mySqlAdminPassword}'
      type: 'MySql'
    }
  }
}

resource appInsightsName 'microsoft.insights/components@2015-05-01' = {
  kind: 'java'
  name: appInsightsName_var
  location: 'eastus'
  tags: {
    'hidden-link:${resourceGroup().id}/providers/Microsoft.Web/sites/${webAppName_var}': 'Resource'
  }
  properties: {
    ApplicationId: appInsightsName_var
  }
}

resource mySqlServerName 'Microsoft.DBforMySQL/servers@2017-12-01' = {
  location: location
  name: mySqlServerName_var
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
  name: '${mySqlServerName_var}/${mySqlServerName_var}Firewall'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '255.255.255.255'
  }
}

resource mySqlServerName_mySqlDbName 'Microsoft.DBforMySQL/servers/databases@2017-12-01' = {
  name: '${mySqlServerName_var}/${mySqlDbName}'
  properties: {
    charset: 'utf8'
    collation: 'utf8_general_ci'
  }
}

module jenkinsDeployment '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat('nested/jenkins.json', parameters('_artifactsLocationSasToken')))]*/ = {
  name: 'jenkinsDeployment'
  params: {
    adminUsername: jenkinsVMAdminUsername
    dnsPrefix: jenkinsDnsPrefix
    jenkinsReleaseType: jenkinsReleaseType
    repositoryUrl: repositoryUrl
    clientId: clientId
    clientSecret: clientSecret
    storageAccountName: storageAccountName_var
    storageAccountKey: listKeys(storageAccountName.id, '2016-01-01').keys[0].value
    webAppName: webAppName_var
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    authenticationType: authenticationType
    adminPasswordOrKey: adminPasswordOrKey
  }
  dependsOn: [
    storageAccountName
  ]
}

output jenkinsURL string = reference('jenkinsDeployment').outputs.jenkinsURL.value
output jenkinsSSH string = reference('jenkinsDeployment').outputs.jenkinsSSH.value
output webAppURL string = 'http://${reference(webAppName_var).defaultHostName}'