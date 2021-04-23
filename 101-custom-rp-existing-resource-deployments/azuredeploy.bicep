@allowed([
  'australiaeast'
  'australiasoutheast'
  'eastus'
  'westus2'
  'eastus2euap'
  'westeurope'
  'northeurope'
  'canadacentral'
  'canadaeast'
  'japaneast'
  'japanwest'
])
@description('Location for the resources.')
param location string

@description('Name of the logic app to be created.')
param logicAppName string = uniqueString(resourceGroup().id)

@description('Name of the custom provider to be created.')
param customResourceProviderName string = uniqueString(resourceGroup().id)

@description('The resource id of an existing custom provider. Provide this to skip deployment of new logic app and custom provider.')
param customResourceProviderId string = ''

@description('Name of the association resource that is being created.')
param associationName string = 'myDemoAssociationResource'

module customProviderInfrastructureTemplate './nested_customProviderInfrastructureTemplate.bicep' = if (empty(customResourceProviderId)) {
  name: 'customProviderInfrastructureTemplate'
  params: {
    location: location
    logicAppName: logicAppName
    customResourceProviderName: customResourceProviderName
  }
}

resource associationName_resource 'Microsoft.CustomProviders/associations@2018-09-01-preview' = {
  name: associationName
  location: 'global'
  properties: {
    targetResourceId: (empty(customResourceProviderId) ? reference('customProviderInfrastructureTemplate').outputs.customProviderResourceId.value : customResourceProviderId)
    myCustomInputProperty: 'myCustomInputValue'
    myCustomInputObject: {
      Property1: 'Value1'
    }
  }
  dependsOn: [
    customProviderInfrastructureTemplate
  ]
}

output associationResource object = reference(associationName, '2018-09-01-preview', 'Full')