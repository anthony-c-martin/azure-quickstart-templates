param namespaceName string {
  metadata: {
    description: 'The name of the Notification Hubs namespace.'
  }
}
param location string {
  metadata: {
    description: 'The location in which the Notification Hubs resources should be deployed.'
  }
  default: resourceGroup().location
}

var hubName = 'MyHub'

resource namespaceName_resource 'Microsoft.NotificationHubs/namespaces@2017-04-01' = {
  name: namespaceName
  location: location
  sku: {
    name: 'Free'
  }
  kind: 'NotificationHub'
}

resource namespaceName_hubName 'Microsoft.NotificationHubs/namespaces/notificationHubs@2017-04-01' = {
  name: '${namespaceName}/${hubName}'
  location: location
  dependsOn: [
    namespaceName_resource
  ]
}