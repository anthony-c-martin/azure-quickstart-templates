@description('Name for the container group')
param containergroupname string

@description('Name for the container')
param containername string

@description('Name for the gitRepo volume')
param volumename string

@description('Port to open on the container and the public IP address.')
param port string = '80'

@description('The number of CPU cores to allocate to the container.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb string = '1.5'

@description('Location for all resources.')
param location string = resourceGroup().location

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
              memoryInGB: memoryInGb
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
          protocol: 'TCP'
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