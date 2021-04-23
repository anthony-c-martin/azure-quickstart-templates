@description('Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.')
param workspaceName string

@description('The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore')
param datastoreName string

@description('The ADLS store name.')
param adlsStoreName string

@description('The service principal Tenant ID.')
param tenantId string = subscription().tenantId

@description('The service principal\'s client/application ID.')
param clientId string

@description('The service principal\'s secret.')
@secure()
param clientSecret string

@description('Optional : Determines what operations will be performed on the data lake store. Defaults to https://datalake.azure.net/ allowing for filesystem operations.')
param resourceUrl string = ''

@description('Optional : Authority url used to authenticate the user. Defaults to https://login.microsoftonline.com')
param authorityUrl string = ''

@description('Optional : The ID of the subscription the ADLS store belongs to. Defaults to selected subscription')
param adlsStoreSubscriptionId string = subscription().subscriptionId

@description('Optional : The resource group the ADLS store belongs to. Defaults to selected resource group')
param adlsStoreResourceGroup string = resourceGroup().name

@description('Optional : If set to true, the call will skip Datastore validation. Defaults to false')
param skipValidation bool = false

@description('The location of the Azure Machine Learning Workspace.')
param location string = resourceGroup().location

resource workspaceName_datastoreName 'Microsoft.MachineLearningServices/workspaces/datastores@2020-05-01-preview' = {
  name: '${workspaceName}/${datastoreName}'
  location: location
  properties: {
    dataStoreType: 'adls'
    SkipValidation: skipValidation
    ClientId: clientId
    ClientSecret: clientSecret
    StoreName: adlsStoreName
    TenantId: tenantId
    ResourceUrl: resourceUrl
    AuthorityUrl: authorityUrl
    AdlsSubscriptionId: adlsStoreSubscriptionId
    AdlsResourceGroup: adlsStoreResourceGroup
  }
}