@description('The name of the Event Grid custom topic.')
param eventGridTopicName string

@description('The name of the Event Grid custom topic\'s subscription.')
param eventGridSubscriptionName string

@description('The webhook URL to send the subscription events to. This URL must be valid and must be prepared to accept the Event Grid webhook URL challenge request.')
param eventGridSubscriptionUrl string

@description('The location in which the Event Grid resources should be deployed.')
param location string = resourceGroup().location

resource eventGridTopicName_resource 'Microsoft.EventGrid/topics@2020-06-01' = {
  name: eventGridTopicName
  location: location
}

resource eventGridSubscriptionName_resource 'Microsoft.EventGrid/eventSubscriptions@2020-06-01' = {
  name: eventGridSubscriptionName
  location: location
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: eventGridSubscriptionUrl
      }
    }
  }
  scope: eventGridTopicName_resource
  dependsOn: [
    eventGridTopicName_resource
  ]
}