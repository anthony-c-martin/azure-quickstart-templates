@description('Traffic Manager profile DNS name. Must be unique in .trafficmanager.net')
param dnsName string = 'tm-${uniqueString(resourceGroup().id)}'

@description('Location of the primary endpoint')
param primarylocation string

@description('Location of the secondary endpoint')
param secondarylocation string

@allowed([
  'Priority'
  'Weighted'
  'Performance'
])
@description('Traffic routing methods available in Traffic Manager')
param trafficRoutingMethod string = 'Weighted'

@minLength(1)
@description('User name for the backend Web servers')
param adminUsername string

@description('Password for the backend Web servers')
@secure()
param adminPassword string

@description('The base URI where artifacts required by this template are located.')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/traffic-manager-demo-setup/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Location for all resources.')
param vmSize string = 'Standard_D2_v3'

var backendDnsPrefix = 'backend-'
var nestedTemplatesFolder = 'nested'
var webServerTemplateName = 'azuredeploywebserver.json'
var serverTestPageInfo = '<p><strong>Request headers:</strong> <br /><?php $hs = apache_request_headers();foreach($hs as $h => $value){echo "$h: $value <br />\n";}?></p>'
var dnsPrefix = concat(backendDnsPrefix, uniqueString(resourceGroup().id))
var locations = [
  primarylocation
  secondarylocation
]

module webServer_1 '?' /*TODO: replace with correct path to [uri(parameters('_artifactsLocation'), concat(variables('nestedTemplatesFolder'), '/', variables('webServerTemplateName'), parameters('_artifactsLocationSasToken')))]*/ = [for i in range(0, 2): {
  name: 'webServer${(i + 1)}'
  params: {
    adminUsername: adminUsername
    adminPassword: adminPassword
    dnsNameForPublicIP: '${dnsPrefix}-${(i + 1)}'
    testPageBody: serverTestPageInfo
    testPage: 'index.php'
    testPageTitle: 'Server ${(i + 1)}'
    installPHP: true
    location: locations[i]
    '_artifactsLocation': artifactsLocation
    '_artifactsLocationSasToken': artifactsLocationSasToken
    vmSize: vmSize
  }
}]

resource trafficManagerDemo 'Microsoft.Network/trafficManagerProfiles@2018-08-01' = {
  name: 'trafficManagerDemo'
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: trafficRoutingMethod
    dnsConfig: {
      relativeName: dnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTP'
      port: 80
      path: '/'
    }
    endpoints: [
      {
        name: 'endpoint1'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: resourceId('Microsoft.Network/publicIpAddresses', '${dnsPrefix}-1')
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
      {
        name: 'endpoint2'
        type: 'Microsoft.Network/trafficManagerProfiles/azureEndpoints'
        properties: {
          targetResourceId: resourceId('Microsoft.Network/publicIpAddresses', '${dnsPrefix}-2')
          endpointStatus: 'Enabled'
          weight: 1
        }
      }
    ]
  }
  dependsOn: [
    webServer_1
  ]
}