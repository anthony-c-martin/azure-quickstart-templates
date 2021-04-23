@description('Name for the container group')
param containergroupname string

@description('Name for the container')
param containername string = 'container1'

@description('Name for the image')
param imagename string = 'nginx'

@description('Port to open on the container and the public IP address.')
param port string = '443'

@description('The number of CPU cores to allocate to the container.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGB string = '1.5'

@allowed([
  'West US'
  'East US'
  'West Europe'
  'West US 2'
  'North Europe'
  'Central US EUAP'
  'East US 2 EUAP'
  'Southeast Asia'
  'East US 2'
  'Central US'
  'Australia East'
  'UK South'
])
@description('The location in which the resources will be created.')
param location string = 'West US 2'

resource containergroupname_resource 'Microsoft.ContainerInstance/containerGroups@2018-10-01' = {
  name: containergroupname
  location: location
  properties: {
    containers: [
      {
        name: containername
        properties: {
          command: [
            '/bin/sh'
            '-c'
            'touch /tmp/healthy; sleep 30; rm -rf /tmp/healthy; sleep 600'
          ]
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
          livenessProbe: {
            exec: {
              command: [
                'cat'
                '/tmp/healthy'
              ]
            }
            periodSeconds: 5
          }
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
  dependsOn: []
}

output containerIPv4Address string = containergroupname_resource.properties.ipAddress.ip