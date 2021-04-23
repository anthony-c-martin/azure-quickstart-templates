@minLength(50)
@description('Your Moesif Application Id (aka Collector Application Id) can be found in the Moesif Portal. After signing up for a Moesif account, your Moesif Application Id will be displayed during the onboarding steps. Sets environment variable APIMEVENTS-MOESIF-APPLICATION-ID in App Service')
param moesifApplicationId string

@minLength(0)
@description('Name of existing Api Management service. If blank, Log-to-eventhub logger is not created. The api management must be in same Resource Group as the deployment')
param existingApiMgmtName string = ''

@allowed([
  'B1'
  'B2'
  'B3'
  'S1'
  'S2'
  'S3'
  'P1v2'
  'P2v2'
  'P3v2'
  'P1v3'
  'P2v3'
  'P3v3'
])
@description('The instance / SKU name for Azure App Service eg: B1, B2, S1, P1V2. Note F1 and D1 shared plan are not supported as they do not support \'alwaysOn\'')
param azureAppServiceSku string = 'B1'

@minLength(6)
@description('A prefix that will be added to created resource names and DNS URLs. Allowed characters: alphabets and numbers only. Resulting name must be maximum 24 characters (storage account maximum)')
param dnsNamePrefix string = 'moesiflog${uniqueString(resourceGroup().id)}'

@description('Location for all resources. eg \'westus2\'')
param location string = resourceGroup().location

@description('The base URL where templates are located. Should end with trailing \'/\'')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/201-api-management-logs-to-moesif-using-eventhub-webapp/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

var moesifSessionToken = 'optional'
var moesifApiVersion = 'v1'
var apiManagementLoggerName = 'moesif-log-to-event-hub'
var azureWebsitesDomainLookup = {
  AzureCloud: '.azurewebsites.net'
  AzureUSGovernment: '.azurewebsites.us'
}
var azureWebsitesDomain = azureWebsitesDomainLookup[environment().name]
var eventHubNS = dnsNamePrefix
var eventHubName = dnsNamePrefix
var eventHubSendPolicyName = '${dnsNamePrefix}-send-policy'
var eventHubListenPolicy = '${dnsNamePrefix}-listen-policy'
var azStorageTemplUri = uri(artifactsLocation, 'nested/microsoft.storage/storageaccounts.json${artifactsLocationSasToken}')
var azEventHubTemplUri = uri(artifactsLocation, 'nested/microsoft.eventhub/namespaces.json${artifactsLocationSasToken}')
var azApiMgmtLoggerInstallTemplUri = uri(artifactsLocation, 'nested/microsoft.apimanagement/service/loggers.json${artifactsLocationSasToken}')
var azAppServicePlanTemplUri = uri(artifactsLocation, 'nested/microsoft.web/serverfarms.json${artifactsLocationSasToken}')
var azAppServiceTemplUri = uri(artifactsLocation, 'nested/microsoft.web/sites.json${artifactsLocationSasToken}')
var storageAccountName = replace(dnsNamePrefix, '-', '')
var apiMgrSpecified = (length(existingApiMgmtName) > 0)
var tags = {
  purpose: 'moesif'
}

module storage_deploy '?' /*TODO: replace with correct path to [variables('azStorageTemplUri')]*/ = {
  name: 'storage-deploy'
  params: {
    storageAccountName: storageAccountName
    tags: tags
    location: location
  }
}

module eventhub_deploy '?' /*TODO: replace with correct path to [variables('azEventHubTemplUri')]*/ = {
  name: 'eventhub-deploy'
  params: {
    eventHubNsName: dnsNamePrefix
    eventHubName: dnsNamePrefix
    eventHubSendPolicyName: eventHubSendPolicyName
    eventHubListenPolicy: eventHubListenPolicy
    tags: tags
    location: location
  }
}

module api_management_logger_deploy '?' /*TODO: replace with correct path to [variables('azApiMgmtLoggerInstallTemplUri')]*/ = if (apiMgrSpecified) {
  name: 'api-management-logger-deploy'
  params: {
    existingApiMgmtName: existingApiMgmtName
    logToEventhubLoggerName: apiManagementLoggerName
    eventHubNS: eventHubNS
    eventHubName: eventHubName
    eventHubSendPolicyName: eventHubSendPolicyName
    tags: tags
  }
  dependsOn: [
    eventhub_deploy
  ]
}

module app_service_plan_deploy '?' /*TODO: replace with correct path to [variables('azAppServicePlanTemplUri')]*/ = {
  name: 'app-service-plan-deploy'
  params: {
    appServicePlanName: dnsNamePrefix
    appServiceSkuName: azureAppServiceSku
    tags: tags
    location: location
  }
}

module app_service_deploy '?' /*TODO: replace with correct path to [variables('azAppServiceTemplUri')]*/ = {
  name: 'app-service-deploy'
  params: {
    appServiceName: dnsNamePrefix
    appServicePlanName: dnsNamePrefix
    eventHubNamespace: dnsNamePrefix
    eventHubName: dnsNamePrefix
    eventHubListenPolicy: eventHubListenPolicy
    apimEvtStorName: storageAccountName
    apimEvtMoesifApplicationId: moesifApplicationId
    apimEvtMoesifSessionToken: moesifSessionToken
    apimEvtMoesifApiVersion: moesifApiVersion
    azureWebsitesDomain: azureWebsitesDomain
    tags: tags
    location: location
  }
  dependsOn: [
    app_service_plan_deploy
    storage_deploy
    eventhub_deploy
  ]
}

output logToEventhubLoggerName string = apiManagementLoggerName