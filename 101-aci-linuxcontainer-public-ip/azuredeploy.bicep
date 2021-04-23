@description('Name for the container group')
param name string = 'acilinuxpublicipcontainergroup'

@description('Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials.')
param image string = 'mcr.microsoft.com/azuredocs/aci-helloworld'

@description('Port to open on the container and the public IP address.')
param port string = '80'

@description('The number of CPU cores to allocate to the container.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb string = '1.5'

@description('Location for all resources.')
param location string = resourceGroup().location

@allowed([
  'never'
  'always'
  'onfailure'
])
@description('The behavior of Azure runtime if container has stopped.')
param restartPolicy string = 'always'

resource name_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: name
  location: location
  properties: {
    containers: [
      {
        name: name
        properties: {
          image: image
          ports: [
            {
              port: port
            }
          ]
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGB: memoryInGb
            }
          }
        }
      }
    ]
    osType: 'Linux'
    restartPolicy: restartPolicy
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

output containerIPv4Address string = name_resource.properties.ipAddress.ip