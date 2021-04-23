@description('Name for the container group')
param containergroupname string

@description('Name for the container 1')
param containername1 string

@description('Name for the container 2')
param containername2 string

@description('Name for the emptyDir volume')
param volumename string

@description('Container image to deploy. Should be of the form accountName/imagename[:tag] for images stored in Docker Hub or a fully qualified URI for a private registry like the Azure Container Registry.')
param image string = 'centos:latest'

@description('Port to open on the container and the public IP address.')
param port string = '80'

@description('The number of CPU cores to allocate to the container.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb string = '1.5'

@description('Location for all resources.')
param location string = resourceGroup().location

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
              memoryInGB: memoryInGb
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
              memoryInGB: memoryInGb
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
          protocol: 'TCP'
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