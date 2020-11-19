param contGroupName string {
  metadata: {
    description: 'Name for the container group'
  }
  default: 'acinavcontainergroup'
}
param dnsPrefix string {
  maxLength: 50
  metadata: {
    description: 'The DNS label for the public IP address. It must be lowercase. It should match the following regular expression, or it will raise an error: ^[a-z][a-z0-9-]{1,61}[a-z0-9]$'
  }
}
param letsEncryptMail string {
  metadata: {
    description: 'The eMail address to be used when requesting a Let\'s Encrypt certificate'
  }
}
param navRelease string {
  metadata: {
    description: 'Before the colon: dynamics-nav for NAV or bcsandbox for Business Central. After the colon: Identifier for the specific release like 2018-cu4-de for NAV or de for BC. Possible values can be found at https://hub.docker.com/r/microsoft/dynamics-nav/tags/ or https://hub.docker.com/r/microsoft/bcsandbox/tags/'
  }
  default: 'microsoft/bcsandbox:us'
}
param username string {
  metadata: {
    description: 'Username for your NAV super user'
  }
}
param password string {
  metadata: {
    description: 'Password for your NAV/BC super user and your sa user on the database'
  }
}
param cpuCores string {
  metadata: {
    description: 'The number of CPU cores to allocate to the container'
  }
  default: '2.0'
}
param memoryInGb string {
  metadata: {
    description: 'The amount of memory to allocate to the container in gigabytes. Provide a minimum of 2 as he container will include SQL Server and NAV NST'
  }
  default: '2.0'
}
param customNavSettings string {
  metadata: {
    description: 'Custom settings for the NAV / BC NST'
  }
  default: ''
}
param customWebSettings string {
  metadata: {
    description: 'Custom settings for the Web Client'
  }
  default: ''
}
param acceptEula string {
  allowed: [
    'Y'
    'N'
  ]
  metadata: {
    description: 'Change to \'Y\' to accept the end user license agreement available at https://go.microsoft.com/fwlink/?linkid=861843. This is necessary to successfully run the container'
  }
  default: 'N'
}
param azurecontainerSuffix string {
  allowed: [
    '.azurecontainer.io'
  ]
  metadata: {
    description: 'Please select the Azure container URL suffix for your current region. For the standard Azure cloud, this is azurecontainer.io'
  }
  default: '.azurecontainer.io'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located including a trailing \'/\''
  }
  default: deployment().properties.templateLink.uri
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated. Use the defaultValue if the staging location is not secured.'
  }
  secure: true
  default: ''
}

var image = navRelease
var publicdnsname = '${dnsPrefix}.${location}${azurecontainerSuffix}'

resource contGroupName_resource 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: contGroupName
  location: location
  properties: {
    containers: [
      {
        name: contGroupName
        properties: {
          environmentVariables: [
            {
              name: 'ACCEPT_EULA'
              value: acceptEula
            }
            {
              name: 'username'
              value: username
            }
            {
              name: 'password'
              value: password
            }
            {
              name: 'customNavSettings'
              value: customNavSettings
            }
            {
              name: 'customWebSettings'
              value: customWebSettings
            }
            {
              name: 'PublicDnsName'
              value: publicdnsname
            }
            {
              name: 'folders'
              value: 'c:\\run\\my=${uri(artifactsLocation, 'scripts/SetupCertificate.zip${artifactsLocationSasToken}')}'
            }
            {
              name: 'ContactEMailForLetsEncrypt'
              value: letsEncryptMail
            }
          ]
          image: image
          ports: [
            {
              protocol: 'Tcp'
              port: 443
            }
            {
              protocol: 'Tcp'
              port: 8080
            }
            {
              protocol: 'Tcp'
              port: 7049
            }
            {
              protocol: 'Tcp'
              port: 7048
            }
            {
              protocol: 'Tcp'
              port: 80
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
    osType: 'Windows'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'Tcp'
          port: 443
        }
        {
          protocol: 'Tcp'
          port: 8080
        }
        {
          protocol: 'Tcp'
          port: 7049
        }
        {
          protocol: 'Tcp'
          port: 7048
        }
        {
          protocol: 'Tcp'
          port: 80
        }
      ]
      dnsNameLabel: dnsPrefix
    }
  }
}

output containerIPAddressFqdn string = contGroupName_resource.properties.ipAddress.fqdn