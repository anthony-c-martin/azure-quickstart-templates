param iotHubName string {
  minLength: 3
  metadata: {
    description: 'Specifies the name of the IoT Hub.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param skuName string {
  metadata: {
    description: 'Specifies the IotHub SKU.'
  }
  default: 'F1'
}
param capacityUnits int {
  minValue: 1
  maxValue: 1
  metadata: {
    description: 'Specifies the number of provisioned IoT Hub units. Restricted to 1 unit for the F1 SKU. Can be set up to maximum number allowed for subscription.'
  }
  default: 1
}

var consumerGroupName = '${iotHubName}/events/cg1'

resource iotHubName_resource 'Microsoft.Devices/IotHubs@2020-03-01' = {
  name: iotHubName
  location: location
  properties: {
    eventHubEndpoints: {
      events: {
        retentionTimeInDays: 1
        partitionCount: 2
      }
    }
    cloudToDevice: {
      defaultTtlAsIso8601: 'PT1H'
      maxDeliveryCount: 10
      feedback: {
        ttlAsIso8601: 'PT1H'
        lockDurationAsIso8601: 'PT60S'
        maxDeliveryCount: 10
      }
    }
    messagingEndpoints: {
      fileNotifications: {
        ttlAsIso8601: 'PT1H'
        lockDurationAsIso8601: 'PT1M'
        maxDeliveryCount: 10
      }
    }
  }
  sku: {
    name: skuName
    capacity: capacityUnits
  }
}

resource consumerGroupName_resource 'Microsoft.Devices/iotHubs/eventhubEndpoints/ConsumerGroups@2020-03-01' = {
  name: consumerGroupName
  dependsOn: [
    iotHubName_resource
  ]
}