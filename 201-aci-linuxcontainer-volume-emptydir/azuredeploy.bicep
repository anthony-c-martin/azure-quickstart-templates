param containergroupname string {
  metadata: {
    description: 'Name for the container group'
  }
}
param containername1 string {
  metadata: {
    description: 'Name for the container 1'
  }
}
param containername2 string {
  metadata: {
    description: 'Name for the container 2'
  }
}
param volumename string {
  metadata: {
    description: 'Name for the emptyDir volume'
  }
}
param image string {
  metadata: {
    description: 'Container image to deploy. Should be of the form accountName/imagename[:tag] for images stored in Docker Hub or a fully qualified URI for a private registry like the Azure Container Registry.'
  }
  default: 'centos:latest'
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

resource containergroupname_resource 'Microsoft.ContainerInstance/containerGroups@2017-10-01-preview' = {
  name: containergroupname
  location: location
  properties: {
    containers: [
      {
        name: containername1
        properties: {
          command: []
          image: 'nginx'
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
          volumeMounts: [
            {
              name: volumename
              mountPath: '/var/log/nginx'
              readOnly: false
            }
          ]
        }
      }
      {
        name: containername2
        properties: {
          command: [
            'bin/bash'
            '-c'
            'while sleep 5; do cat /mnt/input/access.log; done'
          ]
          image: image
          resources: {
            requests: {
              cpu: cpuCores
              memoryInGb: memoryInGb
            }
          }
          volumeMounts: [
            {
              name: volumename
              mountPath: '/mnt/input'
              readOnly: true
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
    volumes: [
      {
        name: volumename
        emptyDir: {}
      }
    ]
  }
}

output containerIPv4Address string = containergroupname_resource.properties.ipAddress.ip