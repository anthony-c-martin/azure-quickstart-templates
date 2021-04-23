@description('Sets the Domain name prefix for the cluster.  The concatenation of the domain name and the regionalized DNS zone make up the fully qualified domain name associated with the public IP address.')
param dnsNamePrefix string

@minValue(1)
@maxValue(100)
@description('The number of agents for the cluster.  This value can be from 1 to 100 (note, for Kubernetes clusters you will also get 1 or 2 public agents in addition to these seleted masters)')
param agentCount int = 1

@description('The size of the Virtual Machine.')
param agentVMSize string = 'Standard_D2_v2'

@description('User name for the Linux Virtual Machines.')
param adminUsername string

@allowed([
  'Kubernetes'
  'DCOS'
  'Swarm'
])
@description('The type of orchestrator used to manage the applications on the cluster.')
param orchestratorType string = 'Kubernetes'

@allowed([
  1
])
@description('The number of Kubernetes masters for the cluster.')
param masterCount int = 1

@description('Configure all linux machines with the SSH RSA public key string.  Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\'')
param sshRSAPublicKey string

@description('Client ID (used by cloudprovider)')
@secure()
param servicePrincipalClientId string = 'n/a'

@description('The Service Principal Client Secret.')
@secure()
param servicePrincipalClientSecret string = 'n/a'

@description('Location for all resources.')
param location string = resourceGroup().location

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