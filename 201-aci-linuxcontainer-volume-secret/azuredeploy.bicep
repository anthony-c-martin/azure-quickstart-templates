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
  default: 'containerinstance/helloworld:ssl'
}
param volumename string {
  metadata: {
    description: 'Name for the secret volume'
  }
  default: 'volume1'
}
param dnsnamelabel string {
  metadata: {
    description: 'The DSN name label'
  }
}
param sslcertificateData string {
  metadata: {
    description: 'Base-64 encoded authentication PFX certificate.'
  }
  secure: true
}
param sslcertificatePwd string {
  metadata: {
    description: 'Base-64 encoded password of authentication PFX certificate.'
  }
  secure: true
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

resource containergroupname_resource 'Microsoft.ContainerInstance/containerGroups@2018-02-01-preview' = {
  name: containergroupname
  location: location
  properties: {
    containers: [
      {
        name: containername
        properties: {
          command: []
          image: imagename
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
              mountPath: '/mnt/secrets'
              readOnly: false
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      dnsNameLabel: dnsnamelabel
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
        secret: {
          sslcertificateData: sslcertificateData
          sslcertificatePwd: base64(sslcertificatePwd)
        }
      }
    ]
  }
  dependsOn: []
}

output containerIPAddressFqdn string = containergroupname_resource.properties.ipAddress.fqdn