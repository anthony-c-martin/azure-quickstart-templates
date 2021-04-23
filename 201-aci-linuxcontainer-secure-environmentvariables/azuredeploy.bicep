@description('Name for the container group')
param containergroupname string

@description('Name for the container')
param containername string

@description('Name for the image')
param imagename string = 'nginx'

@description('Port to open on the container and the public IP address.')
param port string = '443'

@description('The number of CPU cores to allocate to the container.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGB string = '1.5'

@description('The environment variable name.')
param environmentVariableName string

@description('The environment variable value.')
param environmentVariableValue string

@description('The location in which the resources will be created.')
param location string = resourceGroup().location

resource containergroupname_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: containergroupname
  location: location
  properties: {
    containers: [
      {
        name: containername
        properties: {
          image: imagename
          ports: [
            {
              port: port
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGB
            }
          }
          environmentVariables: [
            {
              name: environmentVariableName
              secureValue: environmentVariableValue
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'TCP'
          port: port
        }
      ]
    }
  }
}

output containerIPv4Address string = containergroupname_resource.properties.ipAddress.ip