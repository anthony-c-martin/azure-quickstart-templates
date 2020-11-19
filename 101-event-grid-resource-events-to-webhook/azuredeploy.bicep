param eventSubName string {
  metadata: {
    description: 'The name of the event subscription to create.'
  }
  default: 'subToResources'
}
param endpoint string {
  metadata: {
    description: 'The URL for the WebHook to receive events. Create your own endpoint for events.'
  }
}

resource eventSubName_resource 'Microsoft.EventGrid/eventSubscriptions@2020-06-01' = {
  name: eventSubName
  properties: {
    destination: {
      endpointType: 'WebHook'
      properties: {
        endpointUrl: endpoint
      }
    }
    filter: {
      isSubjectCaseSensitive: false
    }
  }
}