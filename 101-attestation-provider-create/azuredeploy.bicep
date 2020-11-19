param attestationProviderName string {
  metadata: {
    description: 'Name of the Attestation provider. Must be between 3 and 24 characters in length and use numbers and lower-case letters only.'
  }
  default: uniqueString(resourceGroup().name, deployment().name)
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param tags object = {}
param policySigningCertificates string = ''

var PolicySigningCertificates_variable = {
  PolicySigningCertificates: {
    keys: [
      {
        kty: 'RSA'
        use: 'sig'
        x5c: [
          policySigningCertificates
        ]
      }
    ]
  }
}

resource attestationProviderName_resource 'Microsoft.Attestation/attestationProviders@2020-10-01' = {
  name: attestationProviderName
  location: location
  tags: tags
  properties: (empty(policySigningCertificates) ? json('{}') : PolicySigningCertificates_variable)
}