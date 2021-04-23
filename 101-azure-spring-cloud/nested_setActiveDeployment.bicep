param serviceName string
param app1 string
param app2 string
param app3 string

resource serviceName_app1 'Microsoft.AppPlatform/Spring/apps@2020-07-01' = {
  name: '${serviceName}/${app1}'
  properties: {
    public: true
    activeDeploymentName: 'default'
  }
}

resource serviceName_app2 'Microsoft.AppPlatform/Spring/apps@2020-07-01' = {
  name: '${serviceName}/${app2}'
  properties: {
    public: false
    activeDeploymentName: 'default'
  }
}

resource serviceName_app3 'Microsoft.AppPlatform/Spring/apps@2020-07-01' = {
  name: '${serviceName}/${app3}'
  properties: {
    public: false
    activeDeploymentName: 'default'
  }
}