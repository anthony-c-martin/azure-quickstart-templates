param name string {
  metadata: {
    description: 'Name for the container group'
  }
  default: 'acilinuxpublicipcontainergroup'
}
param image string {
  metadata: {
    description: 'Container image to deploy. Should be of the form repoName/imagename:tag for images stored in public Docker Hub, or a fully qualified URI for other registries. Images from private registries require additional registry credentials.'
  }
  default: 'mcr.microsoft.com/azuredocs/aci-helloworld'
}
param port string {
  metadata: {
    description: 'Port to open on the container and the public IP address.'
  }
  default: '80'
}
param cpuCores string {
  metadata: {
    description: 'The number of CPU cores to allocate to the container.'
  }
  default: '1.0'
}
param memoryInGb string {
  metadata: {
    description: 'The amount of memory to allocate to the container in gigabytes.'
  }
  default: '1.5'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param restartPolicy string {
  allowed: [
    'never'
    'always'
    'onfailure'
  ]
  metadata: {
    description: 'The behavior of Azure runtime if container has stopped.'
  }
  default: 'always'
}

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
              memoryInGb: memoryInGb
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
          protocol: 'Tcp'
          port: port
        }
      ]
    }
  }
}

output containerIPv4Address string = name_resource.properties.ipAddress.ip