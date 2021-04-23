@description('Name of the App Service Certificate')
param certificateOrderName string

@allowed([
  'StandardDomainValidatedSsl'
  'StandardDomainValidatedWildCardSsl'
])
@description('App Service Certificate type')
param productType string = 'StandardDomainValidatedWildCardSsl'

@description('Existing Key Vault resource Id that already has access policies to allow Microsoft.CertificateRegistration and Microsoft.Web RPs to perform required operations on secret (Checkout README.md for more information)')
param existingKeyVaultId string

@description('Existing App name to use for creating SSL bindings. This App should have the domain assigned as a custom domain')
param existingAppName string

@description('Hostname for App Service Certificate. The root and www subdomain should be assigned to the Web App as custom domains')
param rootHostname string

@description('App location')
param existingAppLocation string

@description('Location for all resources.')
param location string = resourceGroup().location

var distinguishedName = 'CN=*.${rootHostname}'
var wwwHostname = 'www.${rootHostname}'

resource certificateOrderName_resource 'Microsoft.CertificateRegistration/certificateOrders@2015-08-01' = {
  name: certificateOrderName
  location: 'global'
  properties: {
    distinguishedName: distinguishedName
    validityInYears: 1
    productType: productType
  }
}

resource rootHostname_certificateOrderName 'Microsoft.DomainRegistration/domains/domainOwnershipIdentifiers@2015-04-01' = {
  name: '${rootHostname}/${certificateOrderName}'
  location: 'global'
  properties: {
    ownershipId: certificateOrderName_resource.properties.domainVerificationToken
  }
}

resource certificateOrderName_certificateOrderName 'Microsoft.CertificateRegistration/certificateOrders/certificates@2015-08-01' = {
  parent: certificateOrderName_resource
  name: '${certificateOrderName}'
  location: 'global'
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: certificateOrderName
  }
  dependsOn: [
    rootHostname_certificateOrderName
  ]
}

resource Microsoft_Web_certificates_certificateOrderName 'Microsoft.Web/certificates@2015-08-01' = {
  name: certificateOrderName
  location: existingAppLocation
  properties: {
    keyVaultId: existingKeyVaultId
    keyVaultSecretName: certificateOrderName
  }
  dependsOn: [
    certificateOrderName_certificateOrderName
  ]
}

resource existingAppName_resource 'Microsoft.Web/sites@2015-08-01' = {
  name: existingAppName
  location: existingAppLocation
  properties: {
    name: existingAppName
    hostNameSslStates: [
      {
        name: rootHostname
        sslState: 1
        thumbprint: certificateOrderName_resource.properties.signedCertificate.thumbprint
        toUpdate: true
      }
      {
        name: wwwHostname
        sslState: 1
        thumbprint: certificateOrderName_resource.properties.signedCertificate.thumbprint
        toUpdate: true
      }
    ]
  }
  dependsOn: [
    Microsoft_Web_certificates_certificateOrderName
  ]
}