@description('The name of the service.')
param serviceName string

@allowed([
  'australiaeast'
  'eastus'
  'eastus2'
  'japaneast'
  'northcentralus'
  'northeurope'
  'southcentralus'
  'southeastasia'
  'uksouth'
  'ukwest'
  'westcentralus'
  'westeurope'
  'westus2'
])
@description('Location of Azure API for FHIR®')
param location string

resource serviceName_resource 'Microsoft.HealthcareApis/services@2020-03-15' = {
  name: serviceName
  location: location
  kind: 'fhir-R4'
  properties: {
    authenticationConfiguration: {
      audience: 'https://${serviceName}.azurehealthcareapis.com'
      authority: uri(environment().authentication.loginEndpoint, subscription().tenantId)
    }
  }
}