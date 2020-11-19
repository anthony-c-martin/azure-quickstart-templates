param location string {
  metadata: {
    description: 'Location for the resources.'
  }
  default: resourceGroup().location
}
param streamAnalyticsJobName string {
  minLength: 3
  maxLength: 63
  metadata: {
    description: 'Stream Analytics Job Name, can contain alphanumeric characters and hypen and must be 3-63 characters long'
  }
}
param numberOfStreamingUnits int {
  allowed: [
    1
    3
    6
    12
    18
    24
    30
    36
    42
    48
  ]
  minValue: 1
  maxValue: 48
  metadata: {
    description: 'Number of Streaming Units'
  }
}

resource streamAnalyticsJobName_res 'Microsoft.StreamAnalytics/StreamingJobs@2019-06-01' = {
  name: streamAnalyticsJobName
  location: location
  properties: {
    sku: {
      name: 'standard'
    }
    outputErrorPolicy: 'stop'
    eventsOutOfOrderPolicy: 'adjust'
    eventsOutOfOrderMaxDelayInSeconds: 0
    eventsLateArrivalMaxDelayInSeconds: 5
    dataLocale: 'en-US'
    transformation: {
      name: 'Transformation'
      properties: {
        streamingUnits: numberOfStreamingUnits
        query: 'SELECT\r\n    *\r\nINTO\r\n    [YourOutputAlias]\r\nFROM\r\n    [YourInputAlias]'
      }
    }
  }
}