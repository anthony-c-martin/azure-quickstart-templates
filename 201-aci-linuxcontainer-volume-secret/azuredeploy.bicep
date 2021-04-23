@description('Name for the container group')
param containergroupname string

@description('Name for the container')
param containername string = 'container1'

@description('Name for the image')
param imagename string = 'containerinstance/helloworld:ssl'

@description('Name for the secret volume')
param volumename string = 'volume1'

@description('The DSN name label')
param dnsnamelabel string

@description('Base-64 encoded authentication PFX certificate.')
@secure()
param sslcertificateData string

@description('Base-64 encoded password of authentication PFX certificate.')
@secure()
param sslcertificatePwd string

@description('Port to open on the container and the public IP address.')
param port string = '443'

@description('The number of CPU cores to allocate to the container.')
param cpuCores string = '1.0'

@description('The amount of memory to allocate to the container in gigabytes.')
param memoryInGb string = '1.5'

@description('Location for all resources.')
param location string = resourceGroup().location

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
              memoryInGB: memoryInGb
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
          protocol: 'TCP'
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