@description('Unique name of the Service Bus namespace')
param serviceBusNamespaceName string = 'sb-${uniqueString(resourceGroup().id)}'

@description('Name of the Topic')
param serviceBusTopicName string = 'sbt-topic'

@description('Unique name of the Event Grid custom topic.')
param eventGridTopicName string = 'egt-${uniqueString(resourceGroup().id, serviceBusNamespaceName)}'

@description('The name of the Event Grid custom topic\'s subscription.')
param eventGridSubscriptionName string = 'evg-subscription'

@description('The location in which the Event Grid resources should be deployed.')
param location string = resourceGroup().location

resource serviceBusNamespaceName_resource 'Microsoft.ServiceBus/namespaces@2018-01-01-preview' = {
  name: serviceBusNamespaceName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {}
}

resource serviceBusNamespaceName_serviceBusTopicName 'Microsoft.ServiceBus/namespaces/topics@2017-04-01' = {
  parent: serviceBusNamespaceName_resource
  name: '${serviceBusTopicName}'
  properties: {
    path: serviceBusTopicName
  }
}

resource eventGridTopicName_resource 'Microsoft.EventGrid/topics@2020-06-01' = {
  name: eventGridTopicName
  location: location
  dependsOn: [
    serviceBusNamespaceName_resource
  ]
}

resource eventGridSubscriptionName_resource 'Microsoft.EventGrid/eventSubscriptions@2020-01-01-preview' = {
  name: eventGridSubscriptionName
  location: location
  properties: {
    destination: {
      endpointType: 'ServiceBusTopic'
      properties: {
        resourceId: serviceBusNamespaceName_serviceBusTopicName.id
      }
    }
    eventDeliverySchema: 'EventGridSchema'
    filter: {
      isSubjectCaseSensitive: false
    }
  }
  scope: eventGridTopicName_resource
  dependsOn: [
    eventGridTopicName_resource
  ]
}