param iotHubName string {
  metadata: {
    description: 'Specify the name of the Iot hub.'
  }
}
param provisioningServiceName string {
  metadata: {
    description: 'Specify the name of the provisioning service.'
  }
}
param location string {
  metadata: {
    description: 'Specify the location of the resources.'
  }
  default: resourceGroup().location
}
param skuName string {
  metadata: {
    description: 'The SKU to use for the IoT Hub.'
  }
  default: 'S1'
}
param skuUnits string {
  metadata: {
    description: 'The number of IoT Hub units.'
  }
  default: '1'
}

var iotHubKeyName = 'iothubowner'

resource iotHubName_res 'Microsoft.Devices/IotHubs@2020-03-01' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {}
}

resource provisioningServiceName_res 'Microsoft.Devices/provisioningServices@2020-01-01' = {
  name: provisioningServiceName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    iotHubs: [
      {
        connectionString: 'HostName=${iotHubName_res.properties.hostName};SharedAccessKeyName=${iotHubKeyName};SharedAccessKey=${listkeys(resourceId('Microsoft.Devices/Iothubs/Iothubkeys', iotHubName, iotHubKeyName), '2020-03-01').primaryKey}'
        location: location
        name: iotHubName_res.properties.hostName
      }
    ]
  }
}