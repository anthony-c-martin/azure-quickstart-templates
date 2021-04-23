@description('The default SSL certificate will be configured for this App Service Environment.')
param appServiceEnvironmentName string

@description('Set this to the same location as the App Service Environment defined in appServiceEnvironmentName.')
param existingAseLocation string

@description('A pfx file encoded as a base-64 string.  The pfx contains the SSL certificate that will be configured as the default SSL certificate for the ASE.')
param pfxBlobString string

@description('The password for the pfx filed contained in pfxBlobString.')
param password string

@description('The hexadecimal certificate thumbprint of the certificate contained in pfxBlobString.  All spaces need to be removed from the hex string.')
param certificateThumbprint string

@description('Name of the certificate.  This can be any name you want to use to identify the certificate.')
param certificateName string

resource certificateName_resource 'Microsoft.Web/certificates@2015-08-01' = {
  name: certificateName
  location: existingAseLocation
  properties: {
    pfxBlob: pfxBlobString
    password: password
    hostingEnvironmentProfile: {
      id: appServiceEnvironmentName_resource.id
    }
  }
}

resource appServiceEnvironmentName_resource 'Microsoft.Web/hostingEnvironments@2015-08-01' = {
  name: appServiceEnvironmentName
  location: existingAseLocation
  properties: {
    clusterSettings: [
      {
        name: 'DefaultSslCertificateThumbprint'
        value: certificateThumbprint
      }
    ]
  }
  dependsOn: [
    certificateName_resource
  ]
}