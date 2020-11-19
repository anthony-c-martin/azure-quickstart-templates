param location string = resourceGroup().location
param applicationName string {
  metadata: {
    description: 'Managed application name'
  }
  default: 'applicationWithMetricsAndAlerts'
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
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-managed-application-with-metrics-and-alerts/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}

var applicationDefinitionName = '${applicationName}_definition'
var lockLevel = 'None'
var description = 'Sample managed application definition with metrics and alerts'
var displayName = 'Sample managed application definition with metrics and alerts'
var packageFileUri = uri(artifactsLocation, 'artifacts/ManagedAppZip/pkg.zip${artifactsLocationSasToken}')
var managedResourceGroupId = '${subscription().id}/resourceGroups/${applicationName}_managed'
var applicationDefinitionResourceId = applicationDefinitionName_resource.id

resource applicationDefinitionName_resource 'Microsoft.Solutions/applicationDefinitions@2019-07-01' = {
  name: applicationDefinitionName
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
    applicationDefinitionResourceId
  ]
}