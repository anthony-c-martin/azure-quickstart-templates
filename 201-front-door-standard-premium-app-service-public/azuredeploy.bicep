@description('The location into which regionally scoped resources should be deployed. Note that Front Door is a global resource.')
param location string = resourceGroup().location

@description('The name of the App Service application to create. This must be globally unique.')
param appName string = 'myapp-${uniqueString(resourceGroup().id)}'

@description('The name of the SKU to use when creating the App Service plan.')
param appServicePlanSkuName string = 'S1'

@description('The number of worker instances of your App Service plan that should be provisioned.')
param appServicePlanCapacity int = 1

@description('The name of the Front Door endpoint to create. This must be globally unique.')
param frontDoorEndpointName string = 'afd-${uniqueString(resourceGroup().id)}'

@allowed([
  'Standard_AzureFrontDoor'
  'Premium_AzureFrontDoor'
])
@description('The name of the SKU to use when creating the Front Door profile.')
param frontDoorSkuName string = 'Standard_AzureFrontDoor'

var appServicePlanName_var = 'AppServicePlan'
var frontDoorProfileName_var = 'MyFrontDoor'
var frontDoorOriginGroupName = 'MyOriginGroup'
var frontDoorOriginName = 'MyAppServiceOrigin'
var frontDoorRouteName = 'MyRoute'

resource frontDoorProfileName 'Microsoft.Cdn/profiles@2020-09-01' = {
  name: frontDoorProfileName_var
  location: 'global'
  sku: {
    name: frontDoorSkuName
  }
}

resource appServicePlanName 'Microsoft.Web/serverfarms@2020-06-01' = {
  name: appServicePlanName_var
  location: location
  sku: {
    name: appServicePlanSkuName
    capacity: appServicePlanCapacity
  }
  kind: 'app'
}

resource appName_resource 'Microsoft.Web/sites@2020-06-01' = {
  name: appName
  location: location
  kind: 'app'
  properties: {
    serverFarmId: appServicePlanName.id
    httpsOnly: true
    siteConfig: {
      ipSecurityRestrictions: [
        {
          tag: 'ServiceTag'
          ipAddress: 'AzureFrontDoor.Backend'
          action: 'Allow'
          priority: 100
          headers: {
            'x-azure-fdid': [
              frontDoorProfileName.properties.frontdoorId
            ]
          }
          name: 'Allow traffic from Front Door'
        }
      ]
    }
  }
}

resource frontDoorProfileName_frontDoorEndpointName 'Microsoft.Cdn/profiles/afdEndpoints@2020-09-01' = {
  parent: frontDoorProfileName
  name: '${frontDoorEndpointName}'
  location: 'global'
  properties: {
    originResponseTimeoutSeconds: 240
    enabledState: 'Enabled'
  }
}

resource frontDoorProfileName_frontDoorOriginGroupName 'Microsoft.Cdn/profiles/originGroups@2020-09-01' = {
  parent: frontDoorProfileName
  name: '${frontDoorOriginGroupName}'
  properties: {
    loadBalancingSettings: {
      sampleSize: 4
      successfulSamplesRequired: 3
    }
    healthProbeSettings: {
      probePath: '/'
      probeRequestType: 'HEAD'
      probeProtocol: 'Http'
      probeIntervalInSeconds: 100
    }
  }
}

resource frontDoorProfileName_frontDoorOriginGroupName_frontDoorOriginName 'Microsoft.Cdn/profiles/originGroups/origins@2020-09-01' = {
  parent: frontDoorProfileName_frontDoorOriginGroupName
  name: frontDoorOriginName
  properties: {
    hostName: appName_resource.properties.defaultHostName
    httpPort: 80
    httpsPort: 443
    originHostHeader: appName_resource.properties.defaultHostName
    priority: 1
    weight: 1000
  }
  dependsOn: [
    resourceId('Microsoft.Cdn/profiles/originGroups', split('${frontDoorProfileName_var}/${frontDoorOriginGroupName}', '/')[0], split('${frontDoorProfileName_var}/${frontDoorOriginGroupName}', '/')[1])
  ]
}

resource frontDoorProfileName_frontDoorEndpointName_frontDoorRouteName 'Microsoft.Cdn/profiles/afdEndpoints/routes@2020-09-01' = {
  parent: frontDoorProfileName_frontDoorEndpointName
  name: frontDoorRouteName
  properties: {
    originGroup: {
      id: resourceId('Microsoft.Cdn/profiles/originGroups', split('${frontDoorProfileName_var}/${frontDoorOriginGroupName}', '/')[0], split('${frontDoorProfileName_var}/${frontDoorOriginGroupName}', '/')[1])
    }
    supportedProtocols: [
      'Http'
      'Https'
    ]
    patternsToMatch: [
      '/*'
    ]
    compressionSettings: {
      contentTypesToCompress: [
        'application/eot'
        'application/font'
        'application/font-sfnt'
        'application/javascript'
        'application/json'
        'application/opentype'
        'application/otf'
        'application/pkcs7-mime'
        'application/truetype'
        'application/ttf'
        'application/vnd.ms-fontobject'
        'application/xhtml+xml'
        'application/xml'
        'application/xml+rss'
        'application/x-font-opentype'
        'application/x-font-truetype'
        'application/x-font-ttf'
        'application/x-httpd-cgi'
        'application/x-javascript'
        'application/x-mpegurl'
        'application/x-opentype'
        'application/x-otf'
        'application/x-perl'
        'application/x-ttf'
        'font/eot'
        'font/ttf'
        'font/otf'
        'font/opentype'
        'image/svg+xml'
        'text/css'
        'text/csv'
        'text/html'
        'text/javascript'
        'text/js'
        'text/plain'
        'text/richtext'
        'text/tab-separated-values'
        'text/xml'
        'text/x-script'
        'text/x-component'
        'text/x-java-source'
      ]
      isCompressionEnabled: true
    }
    queryStringCachingBehavior: 'IgnoreQueryString'
    forwardingProtocol: 'HttpsOnly'
    linkToDefaultDomain: 'Enabled'
    httpsRedirect: 'Enabled'
  }
  dependsOn: [
    resourceId('Microsoft.Cdn/profiles/afdEndpoints', split('${frontDoorProfileName_var}/${frontDoorEndpointName}', '/')[0], split('${frontDoorProfileName_var}/${frontDoorEndpointName}', '/')[1])
    resourceId('Microsoft.Cdn/profiles/originGroups', split('${frontDoorProfileName_var}/${frontDoorOriginGroupName}', '/')[0], split('${frontDoorProfileName_var}/${frontDoorOriginGroupName}', '/')[1])
  ]
}

output appServiceHostName string = appName_resource.properties.defaultHostName
output frontDoorEndpointHostName string = reference(resourceId('Microsoft.Cdn/profiles/afdEndpoints', split('${frontDoorProfileName_var}/${frontDoorEndpointName}', '/')[0], split('${frontDoorProfileName_var}/${frontDoorEndpointName}', '/')[1])).hostName