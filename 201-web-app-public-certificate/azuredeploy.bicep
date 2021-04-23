@description('The name of the web app that would use this public certificate. The web app should belong to a dedicated App Service Plan.')
param exisitngWebAppName string

@allowed([
  'CurrentUserMy'
  'LocalMachineMy'
])
@description('Location where you wish to install the public certificate. \'LocalMachineMy\' is supported in App Service Environment only.')
param publicCertificateLocation string

@description('Base 64 encoded public certificate file. \'azuredeploy.parameters.json\' file contains an example of this parameter.')
param blob string

var publicCertificateName = '${exisitngWebAppName}-publiccert'

resource exisitngWebAppName_publicCertificateName 'Microsoft.Web/sites/publicCertificates@2016-03-01' = {
  name: '${exisitngWebAppName}/${publicCertificateName}'
  location: resourceGroup().location
  properties: {
    publicCertificateLocation: publicCertificateLocation
    blob: blob
  }
}