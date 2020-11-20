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

var containerName_var = containerName
var containerURI_var = containerURI
var osType_var = osType
var numberCores_var = int(numberCores)
var memory_var = float(memory)
var port = ports
var randomName = '-${substring(containerName, 0, 3)}'

resource containerName_randomName_1 'Microsoft.ContainerInstance/containerGroups@2017-10-01-preview' = {
  name: '${containerName_var}${randomName}1'
  location: location
  properties: {
    containers: [
      {
        name: containerName_var
        properties: {
          image: containerURI_var
          ports: [
            {
              protocol: portProtocol
              port: port
            }
          ]
          resources: {
            requests: {
              cpu: numberCores_var
              memoryInGB: memory_var
            }
          }
        }
      }
    ]
    osType: osType_var
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