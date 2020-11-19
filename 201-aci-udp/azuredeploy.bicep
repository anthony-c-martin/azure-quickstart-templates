param containerName string {
  metadata: {
    description: 'Name for the container group'
  }
}
param containerURI string {
  metadata: {
    description: 'Container image to deploy. Should be of the form accountName/imagename:tag for images stored in Docker Hub or a fully qualified URI for a private registry like the Azure Container Registry.'
  }
  default: 'annonator/aciudptest:latest'
}
param osType string {
  allowed: [
    'Linux'
    'Windows'
  ]
  metadata: {
    description: 'The host OS needed for your container'
  }
  default: 'Linux'
}
param numberCores string {
  metadata: {
    description: 'The number of CPU cores to allocate to the container. Must be an integer.'
  }
  default: '1'
}
param memory string {
  metadata: {
    description: 'The amount of memory to allocate to the container in gigabytes.'
  }
  default: '1.5'
}
param ports string {
  metadata: {
    description: 'The Ports that should be exposed.'
  }
  default: '1234'
}
param portProtocol string {
  metadata: {
    description: 'The Protocol used to expose the Port.'
  }
  default: 'udp'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var containerName_variable = containerName
var containerURI_variable = containerURI
var osType_variable = osType
var numberCores_variable = int(numberCores)
var memory_variable = float(memory)
var port = ports
var randomName = '-${substring(containerName, 0, 3)}'

resource containerName_randomName_1 'Microsoft.ContainerInstance/containerGroups@2017-10-01-preview' = {
  name: '${containerName_variable}${randomName}1'
  location: location
  properties: {
    containers: [
      {
        name: containerName_variable
        properties: {
          image: containerURI_variable
          ports: [
            {
              protocol: portProtocol
              port: port
            }
          ]
          resources: {
            requests: {
              cpu: numberCores_variable
              memoryInGb: memory_variable
            }
          }
        }
      }
    ]
    osType: osType_variable
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: portProtocol
          port: port
        }
      ]
    }
  }
}