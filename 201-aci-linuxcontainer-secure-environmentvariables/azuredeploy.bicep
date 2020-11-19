param containergroupname string {
  metadata: {
    description: 'Name for the container group'
  }
}
param containername string {
  metadata: {
    description: 'Name for the container'
  }
}
param imagename string {
  metadata: {
    description: 'Name for the image'
  }
  default: 'nginx'
}
param port string {
  metadata: {
    description: 'Port to open on the container and the public IP address.'
  }
  default: '443'
}
param cpuCores string {
  metadata: {
    description: 'The number of CPU cores to allocate to the container.'
  }
  default: '1.0'
}
param memoryInGB string {
  metadata: {
    description: 'The amount of memory to allocate to the container in gigabytes.'
  }
  default: '1.5'
}
param environmentVariableName string {
  metadata: {
    description: 'The environment variable name.'
  }
}
param environmentVariableValue string {
  metadata: {
    description: 'The environment variable value.'
  }
}
param location string {
  metadata: {
    description: 'The location in which the resources will be created.'
  }
  default: resourceGroup().location
}

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
          protocol: 'Tcp'
          port: port
        }
      ]
    }
  }
}

output containerIPv4Address string = containergroupname_resource.properties.ipAddress.ip