param dnsNamePrefix string {
  metadata: {
    description: 'Sets the Domain name prefix for the cluster.  The concatenation of the domain name and the regionalized DNS zone make up the fully qualified domain name associated with the public IP address.'
  }
}
param agentCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'The number of agents for the cluster.  This value can be from 1 to 100 (note, for Kubernetes clusters you will also get 1 or 2 public agents in addition to these seleted masters)'
  }
  default: 1
}
param agentVMSize string {
  metadata: {
    description: 'The size of the Virtual Machine.'
  }
  default: 'Standard_D2_v2'
}
param adminUsername string {
  metadata: {
    description: 'User name for the Linux Virtual Machines.'
  }
}
param orchestratorType string {
  allowed: [
    'Kubernetes'
    'DCOS'
    'Swarm'
  ]
  metadata: {
    description: 'The type of orchestrator used to manage the applications on the cluster.'
  }
  default: 'Kubernetes'
}
param masterCount int {
  allowed: [
    1
  ]
  metadata: {
    description: 'The number of Kubernetes masters for the cluster.'
  }
  default: 1
}
param sshRSAPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH RSA public key string.  Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param servicePrincipalClientId string {
  metadata: {
    description: 'Client ID (used by cloudprovider)'
  }
  secure: true
  default: 'n/a'
}
param servicePrincipalClientSecret string {
  metadata: {
    description: 'The Service Principal Client Secret.'
  }
  secure: true
  default: 'n/a'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var agentsEndpointDNSNamePrefix = '${dnsNamePrefix}agents'
var mastersEndpointDNSNamePrefix = '${dnsNamePrefix}mgmt'
var useServicePrincipalDictionary = {
  DCOS: 0
  Swarm: 0
  Kubernetes: 1
}
var useServicePrincipal = useServicePrincipalDictionary[orchestratorType]
var servicePrincipalFields = [
  null
  {
    ClientId: servicePrincipalClientId
    Secret: servicePrincipalClientSecret
  }
]

resource containerservice_name 'Microsoft.ContainerService/containerServices@2016-09-30' = {
  location: location
  name: 'containerservice-${resourceGroup().name}'
  properties: {
    orchestratorProfile: {
      orchestratorType: orchestratorType
    }
    masterProfile: {
      count: masterCount
      dnsPrefix: mastersEndpointDNSNamePrefix
    }
    agentPoolProfiles: [
      {
        name: 'agentpools'
        count: agentCount
        vmSize: agentVMSize
        dnsPrefix: agentsEndpointDNSNamePrefix
      }
    ]
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey
          }
        ]
      }
    }
    servicePrincipalProfile: servicePrincipalFields[useServicePrincipal]
  }
}

output masterFQDN string = reference('Microsoft.ContainerService/containerServices/containerservice-${resourceGroup().name}').masterProfile.fqdn
output sshMaster0 string = 'ssh ${adminUsername}@${reference('Microsoft.ContainerService/containerServices/containerservice-${resourceGroup().name}').masterProfile.fqdn} -A -p 22'
output agentFQDN string = reference('Microsoft.ContainerService/containerServices/containerservice-${resourceGroup().name}').agentPoolProfiles[0].fqdn