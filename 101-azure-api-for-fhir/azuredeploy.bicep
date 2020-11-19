param serviceName string {
  metadata: {
    description: 'The name of the service.'
  }
}
param location string {
  allowed: [
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
  ]
  metadata: {
    description: 'Location of Azure API for FHIR®'
  }
}

resource serviceName_res 'Microsoft.HealthcareApis/services@2020-03-15' = {
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