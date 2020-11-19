param certificateOrderName string {
  metadata: {
    description: 'Name of the App Service Certificate'
  }
}
param productType string {
  allowed: [
    'StandardDomainValidatedSsl'
    'StandardDomainValidatedWildCardSsl'
  ]
  metadata: {
    description: 'App Service Certificate type'
  }
  default: 'StandardDomainValidatedSsl'
}
param existingKeyVaultId string {
  metadata: {
    description: 'Existing Key Vault resource Id that already has access policies to allow Microsoft.CertificateRegistration and Microsoft.Web RPs to perform required operations on secret (Checkout README.md for more information)'
  }
}
param existingAppName string {
  metadata: {
    description: 'Existing App name to use for verification and assignment. This App should have the domain assigned as a custom domain'
  }
}
param rootHostname string {
  metadata: {
    description: 'Hostname for App Service Certificate. The root and www subdomain should be assigned to the Web App as custom domains'
  }
}
param existingAppLocation string {
  metadata: {
    description: 'App location'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var distinguishedName = 'CN=${rootHostname}'
var wwwHostname = 'www.${rootHostname}'

resource certificateOrderName_res 'Microsoft.CertificateRegistration/certificateOrders@2015-08-01' = {
  name: certificateOrderName
  location: 'global'
  properties: {
    distinguishedName: distinguishedName
    validityInYears: 1
    productType: productType
  }
}

resource existingAppName_certificateOrderName 'Microsoft.Web/sites/domainOwnershipIdentifiers@2016-08-01' = {
  name: concat(existingAppName, '/${certificateOrderName}')
  location: existingAppLocation
  properties: {
    id: certificateOrderName_res.properties.DomainVerificationToken
  }
  dependsOn: [
    certificateOrderName_res
  ]
}

resource certificateOrderName_certificateOrderName 'Microsoft.CertificateRegistration/certificateOrders/certificates@2015-08-01' = {
  name: concat(certificateOrderName, '/${certificateOrderName}')
  location: 'global'
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: certificateOrderName
  }
}

resource Microsoft_Web_certificates_certificateOrderName 'Microsoft.Web/certificates@2015-08-01' = {
  name: certificateOrderName
  location: existingAppLocation
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: certificateOrderName
  }
}

resource existingAppName_res 'Microsoft.Web/sites@2015-08-01' = {
  name: existingAppName
  location: existingAppLocation
  properties: {
    name: existingAppName
    hostNameSslStates: [
      {
        name: rootHostname
        sslState: 1
        thumbprint: certificateOrderName_res.properties.SignedCertificate.Thumbprint
        toUpdate: true
      }
      {
        name: wwwHostname
        sslState: 1
        thumbprint: certificateOrderName_res.properties.SignedCertificate.Thumbprint
        toUpdate: true
      }
    ]
  }
}