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
param volumename string {
  metadata: {
    description: 'Name for the gitRepo volume'
  }
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

resource containergroupname_resource 'Microsoft.ContainerInstance/containerGroups@2017-12-01-preview' = {
  name: containergroupname
  location: location
  properties: {
    containers: [
      {
        name: containername
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
              mountPath: '/mnt/gitrepos/'
              readOnly: false
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
        gitRepo: {
          repository: 'https://github.com/Azure-Samples/aci-helloworld.git'
        }
      }
    ]
  }
}

output containerIPv4Address string = containergroupname_resource.properties.ipAddress.ip