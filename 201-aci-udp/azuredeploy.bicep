@description('Name for the container group')
param containerName string

@description('Container image to deploy. Should be of the form accountName/imagename:tag for images stored in Docker Hub or a fully qualified URI for a private registry like the Azure Container Registry.')
param containerURI string = 'annonator/aciudptest:latest'

@allowed([
  'Linux'
  'Windows'
])
@description('The host OS needed for your container')
param osType string = 'Linux'

@description('The number of CPU cores to allocate to the container. Must be an integer.')
param numberCores string = '1'

@description('The amount of memory to allocate to the container in gigabytes.')
param memory string = '1.5'

@description('The Ports that should be exposed.')
param ports string = '1234'

@description('The Protocol used to expose the Port.')
param portProtocol string = 'udp'

@description('Location for all resources.')
param location string = resourceGroup().location

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