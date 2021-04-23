@description('Specify the name of the Iot hub.')
param iotHubName string

@description('Specify the name of the provisioning service.')
param provisioningServiceName string

@description('Specify the location of the resources.')
param location string = resourceGroup().location

@description('The SKU to use for the IoT Hub.')
param skuName string = 'S1'

@description('The number of IoT Hub units.')
param skuUnits string = '1'

var iotHubKeyName = 'iothubowner'

resource iotHubName_resource 'Microsoft.Devices/IotHubs@2020-03-01' = {
  name: iotHubName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {}
}

resource provisioningServiceName_resource 'Microsoft.Devices/provisioningServices@2020-01-01' = {
  name: provisioningServiceName
  location: location
  sku: {
    name: skuName
    capacity: skuUnits
  }
  properties: {
    iotHubs: [
      {
        connectionString: 'HostName=${iotHubName_resource.properties.hostName};SharedAccessKeyName=${iotHubKeyName};SharedAccessKey=${listkeys(resourceId('Microsoft.Devices/Iothubs/Iothubkeys', iotHubName, iotHubKeyName), '2020-03-01').primaryKey}'
        location: location
        name: iotHubName_resource.properties.hostName
      }
    ]
  }
}