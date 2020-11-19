param workspaceName string {
  metadata: {
    description: 'Specifies the name of the Azure Machine Learning workspace which will hold this datastore target.'
  }
}
param datastoreName string {
  metadata: {
    description: 'The name of the datastore, case insensitive, can only contain alphanumeric characters and underscore'
  }
}
param adlsStoreName string {
  metadata: {
    description: 'The ADLS store name.'
  }
}
param tenantId string {
  metadata: {
    description: 'The service principal Tenant ID.'
  }
  default: subscription().tenantId
}
param clientId string {
  metadata: {
    description: 'The service principal\'s client/application ID.'
  }
}
param clientSecret string {
  metadata: {
    description: 'The service principal\'s secret.'
  }
  secure: true
}
param resourceUrl string {
  metadata: {
    description: 'Optional : Determines what operations will be performed on the data lake store. Defaults to https://datalake.azure.net/ allowing for filesystem operations.'
  }
  default: ''
}
param authorityUrl string {
  metadata: {
    description: 'Optional : Authority url used to authenticate the user. Defaults to https://login.microsoftonline.com'
  }
  default: ''
}
param adlsStoreSubscriptionId string {
  metadata: {
    description: 'Optional : The ID of the subscription the ADLS store belongs to. Defaults to selected subscription'
  }
  default: subscription().subscriptionId
}
param adlsStoreResourceGroup string {
  metadata: {
    description: 'Optional : The resource group the ADLS store belongs to. Defaults to selected resource group'
  }
  default: resourceGroup().name
}
param skipValidation bool {
  metadata: {
    description: 'Optional : If set to true, the call will skip Datastore validation. Defaults to false'
  }
  default: false
}
param location string {
  metadata: {
    description: 'The location of the Azure Machine Learning Workspace.'
  }
  default: resourceGroup().location
}

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