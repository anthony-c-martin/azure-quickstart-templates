param containergroupname string {
  metadata: {
    description: 'Name for the container group'
  }
}
param containername string {
  metadata: {
    description: 'Name for the container'
  }
  default: 'container1'
}
param imagename string {
  metadata: {
    description: 'Name for the image'
  }
  default: 'nginx'
}
param port string {
  metadata: {
    description: 'Port to open on the container and the public IP address.'
  }
  default: '443'
}
param cpuCores string {
  metadata: {
    description: 'The number of CPU cores to allocate to the container.'
  }
  default: '1.0'
}
param memoryInGB string {
  metadata: {
    description: 'The amount of memory to allocate to the container in gigabytes.'
  }
  default: '1.5'
}
param location string {
  allowed: [
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
  ]
  metadata: {
    description: 'The location in which the resources will be created.'
  }
  default: 'West US 2'
}

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