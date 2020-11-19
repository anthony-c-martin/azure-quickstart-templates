param location string = resourceGroup().location
param applicationName string {
  metadata: {
    description: 'Managed application name'
  }
  default: 'helloWorldApplication'
}
param storageAccountName string {
  metadata: {
    description: 'Storage account name'
  }
}
param storageAccountType string = 'Standard_LRS'
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-managed-application/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var lockLevel = 'None'
var description = 'Sample Managed application definition'
var displayName = 'Sample Managed application definition'
var managedApplicationDefinitionName = '${applicationName}_ApplicationDefinition'
var packageFileUri = uri(artifactsLocation, 'artifacts/ManagedAppZip/pkg.zip${artifactsLocationSasToken}')
var managedResourceGroupId = '${subscription().id}/resourceGroups/${applicationName}_managed'
var applicationDefinitionResourceId = managedApplicationDefinitionName_resource.id

resource managedApplicationDefinitionName_resource 'Microsoft.Solutions/applicationDefinitions@2019-07-01' = {
  name: managedApplicationDefinitionName
  location: location
  properties: {
    lockLevel: lockLevel
    description: description
    displayName: displayName
    packageFileUri: packageFileUri
  }
}

resource applicationName_resource 'Microsoft.Solutions/applications@2019-07-01' = {
  name: applicationName
  location: location
  kind: 'ServiceCatalog'
  properties: {
    managedResourceGroupId: managedResourceGroupId
    applicationDefinitionId: applicationDefinitionResourceId
    parameters: {
      location: {
        value: location
      }
      storageAccountName: {
        value: storageAccountName
      }
      storageAccountType: {
        value: storageAccountType
      }
    }
  }
  dependsOn: [
    managedApplicationDefinitionName_resource
  ]
}