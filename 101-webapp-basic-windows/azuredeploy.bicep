param webAppName string {
  minLength: 2
  metadata: {
    description: 'Web app name.'
  }
  default: 'webApp-${uniqueString(resourceGroup().id)}'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param sku string {
  metadata: {
    description: 'The SKU of App Service Plan.'
  }
  default: 'F1'
}
param language string {
  allowed: [
    '.net'
    'php'
    'node'
    'html'
  ]
  metadata: {
    description: 'The language stack of the app.'
  }
  default: '.net'
}
param repoUrl string {
  metadata: {
    description: 'Optional Git Repo URL, if empty a \'hello world\' app will be deploy from the Azure-Samples repo'
  }
  default: ''
}

var appServicePlanPortalName_var = 'AppServicePlan-${webAppName}'
var gitRepoReference = {
  '.net': 'https://github.com/Azure-Samples/app-service-web-dotnet-get-started'
  node: 'https://github.com/Azure-Samples/nodejs-docs-hello-world'
  php: 'https://github.com/Azure-Samples/php-docs-hello-world'
  html: 'https://github.com/Azure-Samples/html-docs-hello-world'
}
var gitRepoUrl = (empty(repoUrl) ? gitRepoReference[language] : repoUrl)
var configReference = {
  '.net': {
    comments: '.Net app. No additional configuration needed.'
  }
  html: {
    comments: 'HTML app. No additional configuration needed.'
  }
  php: {
    phpVersion: '7.4'
  }
  node: {
    appSettings: [
      {
        name: 'WEBSITE_NODE_DEFAULT_VERSION'
        value: '12.15.0'
      }
    ]
  }
}

resource appServicePlanPortalName 'Microsoft.Web/serverfarms@2019-08-01' = {
  name: appServicePlanPortalName_var
  location: location
  sku: {
    name: sku
  }
}

resource webAppName_res 'Microsoft.Web/sites@2019-08-01' = {
  name: webAppName
  location: location
  properties: {
    siteConfig: configReference[language]
    serverFarmId: appServicePlanPortalName.id
  }
}

resource webAppName_web 'Microsoft.Web/sites/sourcecontrols@2019-08-01' = {
  name: '${webAppName}/web'
  location: location
  properties: {
    repoUrl: gitRepoUrl
    branch: 'master'
    isManualIntegration: true
  }
  dependsOn: [
    webAppName_res
  ]
}