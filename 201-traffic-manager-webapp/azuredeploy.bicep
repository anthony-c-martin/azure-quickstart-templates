param uniqueDnsName string {
  metadata: {
    description: 'Relative DNS name for the traffic manager profile, resulting FQDN will be <uniqueDnsName>.trafficmanager.net, must be globally unique.'
  }
}
param uniqueDnsNameForWebApp string {
  metadata: {
    description: 'Relative DNS name for the WebApps, must be globally unique.  An index will be appended for each Web App.'
  }
}
param webServerName string {
  metadata: {
    description: 'Name of the App Service Plan that is being created'
  }
}
param location string = resourceGroup().location
param trafficManagerName string {
  metadata: {
    description: 'Name of the trafficManager being created'
  }
}

resource webServerName_resource 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: webServerName
  location: location
  sku: {
    name: 'S1'
    tier: 'Standard'
  }
}

resource uniqueDnsNameForWebApp_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: uniqueDnsNameForWebApp
  location: location
  properties: {
    serverFarmId: webServerName
  }
  dependsOn: [
    webServerName_resource
  ]
}

resource trafficManagerName_resource 'Microsoft.Network/trafficManagerProfiles@2018-08-01' = {
  name: trafficManagerName
  location: 'global'
  properties: {
    profileStatus: 'Enabled'
    trafficRoutingMethod: 'Priority'
    dnsConfig: {
      relativeName: uniqueDnsName
      ttl: 30
    }
    monitorConfig: {
      protocol: 'HTTPS'
      port: 443
      path: '/'
    }
  }
}

resource trafficManagerName_uniqueDnsNameForWebApp 'Microsoft.Network/trafficManagerProfiles/azureEndpoints@2018-08-01' = {
  location: 'global'
  name: '${trafficManagerName}/${uniqueDnsNameForWebApp}'
  properties: {
    targetResourceId: uniqueDnsNameForWebApp_resource.id
    endpointStatus: 'Enabled'
  }
  dependsOn: [
    trafficManagerName_resource
    uniqueDnsNameForWebApp_resource
  ]
}