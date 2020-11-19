param eventGridTopicName string {
  metadata: {
    description: 'The name of the Event Grid custom topic.'
  }
}
param eventGridSubscriptionName string {
  metadata: {
    description: 'The name of the Event Grid custom topic\'s subscription.'
  }
}
param eventGridSubscriptionUrl string {
  metadata: {
    description: 'The webhook URL to send the subscription events to. This URL must be valid and must be prepared to accept the Event Grid webhook URL challenge request.'
  }
}
param location string {
  metadata: {
    description: 'The location in which the Event Grid resources should be deployed.'
  }
  default: resourceGroup().location
}

resource eventGridTopicName_res 'Microsoft.EventGrid/topics@2018-01-01' = {
  name: eventGridTopicName
  location: location
}

resource eventGridTopicName_Microsoft_EventGrid_eventGridSubscriptionName 'Microsoft.EventGrid/topics/providers/eventSubscriptions@2018-01-01' = {
  name: '${eventGridTopicName}/Microsoft.EventGrid/${eventGridSubscriptionName}'
  location: location
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: eventGridSubscriptionUrl
      }
    }
    filter: {
      includedEventTypes: [
        'All'
      ]
    }
  }
  dependsOn: [
    eventGridTopicName_res
  ]
}