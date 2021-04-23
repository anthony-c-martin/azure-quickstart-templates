@description('The name of the Notification Hubs namespace.')
param namespaceName string

@description('The location in which the Notification Hubs resources should be deployed.')
param location string = resourceGroup().location

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
  parent: namespaceName_resource
  name: '${hubName}'
  location: location
}