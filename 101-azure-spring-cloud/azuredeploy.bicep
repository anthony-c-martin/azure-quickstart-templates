param serviceName string
param app1 string = 'gateway'
param app2 string = 'account-service'
param app3 string = 'auth-service'

@allowed([
  'westeurope'
  'eastus'
  'westus2'
  'southeastasia'
  'centralus'
  'australiaeast'
  'uksouth'
  'northeurope'
  'southcentralus'
  'eastus2'
])
param location string

resource serviceName_resource 'Microsoft.AppPlatform/Spring@2020-07-01' = {
  name: serviceName
  location: location
  sku: {
    name: 'S0'
    tier: 'Standard'
  }
  properties: {
    configServerProperties: {
      configServer: {
        gitProperty: {
          uri: 'https://github.com/Azure-Samples/piggymetrics-config'
        }
      }
    }
  }
}

resource serviceName_app1 'Microsoft.AppPlatform/Spring/apps@2020-07-01' = {
  parent: serviceName_resource
  name: '${app1}'
  properties: {
    public: true
  }
}

resource serviceName_app1_default 'Microsoft.AppPlatform/Spring/apps/deployments@2020-07-01' = {
  parent: serviceName_app1
  name: 'default'
  properties: {
    source: {
      relativePath: '<default>'
      type: 'Jar'
    }
  }
}

resource serviceName_app2 'Microsoft.AppPlatform/Spring/apps@2020-07-01' = {
  parent: serviceName_resource
  name: '${app2}'
  properties: {
    public: true
  }
}

resource serviceName_app2_default 'Microsoft.AppPlatform/Spring/apps/deployments@2020-07-01' = {
  parent: serviceName_app2
  name: 'default'
  properties: {
    source: {
      relativePath: '<default>'
      type: 'Jar'
    }
  }
}

resource serviceName_app3 'Microsoft.AppPlatform/Spring/apps@2020-07-01' = {
  parent: serviceName_resource
  name: '${app3}'
  properties: {
    public: false
  }
}

resource serviceName_app3_default 'Microsoft.AppPlatform/Spring/apps/deployments@2020-07-01' = {
  parent: serviceName_app3
  name: 'default'
  properties: {
    source: {
      relativePath: '<default>'
      type: 'Jar'
    }
  }
}

module setActiveDeployment './nested_setActiveDeployment.bicep' = {
  name: 'setActiveDeployment'
  params: {
    serviceName: serviceName
    app1: app1
    app2: app2
    app3: app3
  }
  dependsOn: [
    serviceName_app1_default
    serviceName_app2_default
    serviceName_app3_default
  ]
}