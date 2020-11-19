param dnsNamePrefix string {
  metadata: {
    description: 'Sets the Domain name prefix for the cluster.  The concatenation of the domain name and the regionalized DNS zone make up the fully qualified domain name associated with the public IP address.'
  }
}
param agentCount int {
  minValue: 1
  maxValue: 100
  metadata: {
    description: 'The number of agents for the cluster.  This value can be from 1 to 100 (note, for DC/OS clusters you will also get 1 or 2 public agents in addition to these seleted masters)'
  }
  default: 1
}
param agentVMSize string {
  allowed: [
    'Standard_A0'
    'Standard_A1'
    'Standard_A2'
    'Standard_A3'
    'Standard_A4'
    'Standard_A5'
    'Standard_A6'
    'Standard_A7'
    'Standard_A8'
    'Standard_A9'
    'Standard_A10'
    'Standard_A11'
    'Standard_D1'
    'Standard_D2'
    'Standard_D3'
    'Standard_D4'
    'Standard_D11'
    'Standard_D12'
    'Standard_D13'
    'Standard_D14'
    'Standard_D1_v2'
    'Standard_D2_v2'
    'Standard_D3_v2'
    'Standard_D4_v2'
    'Standard_D5_v2'
    'Standard_D11_v2'
    'Standard_D12_v2'
    'Standard_D13_v2'
    'Standard_D14_v2'
    'Standard_G1'
    'Standard_G2'
    'Standard_G3'
    'Standard_G4'
    'Standard_G5'
    'Standard_DS1'
    'Standard_DS2'
    'Standard_DS3'
    'Standard_DS4'
    'Standard_DS11'
    'Standard_DS12'
    'Standard_DS13'
    'Standard_DS14'
    'Standard_GS1'
    'Standard_GS2'
    'Standard_GS3'
    'Standard_GS4'
    'Standard_GS5'
  ]
  metadata: {
    description: 'The size of the Virtual Machine.'
  }
  default: 'Standard_D2_v2'
}
param linuxAdminUsername string {
  metadata: {
    description: 'User name for the Linux Virtual Machines.'
  }
  default: 'azureuser'
}
param orchestratorType string {
  allowed: [
    'DCOS'
    'Swarm'
  ]
  metadata: {
    description: 'The type of orchestrator used to manage the applications on the cluster.'
  }
  default: 'DCOS'
}
param masterCount int {
  allowed: [
    1
    3
    5
  ]
  metadata: {
    description: 'The number of DC/OS masters for the cluster.'
  }
  default: 1
}
param sshRSAPublicKey string {
  metadata: {
    description: 'Configure all linux machines with the SSH RSA public key string.  Your key should include three parts, for example \'ssh-rsa AAAAB...snip...UcyupgH azureuser@linuxvm\''
  }
}
param enableDiagnostics bool {
  metadata: {
    description: 'Enable or disable VM diagnostics.'
  }
  default: false
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var adminUsername = linuxAdminUsername
var agentCount_var = agentCount
var agentsEndpointDNSNamePrefix = '${dnsNamePrefix}agents'
var agentVMSize_var = agentVMSize
var masterCount_var = masterCount
var mastersEndpointDNSNamePrefix = '${dnsNamePrefix}mgmt'
var orchestratorType_var = orchestratorType
var sshRSAPublicKey_var = sshRSAPublicKey
var enableDiagnostics_var = enableDiagnostics

resource containerservice_name 'Microsoft.ContainerService/containerServices@2016-09-30' = {
  location: location
  name: 'containerservice-${resourceGroup().name}'
  properties: {
    orchestratorProfile: {
      orchestratorType: orchestratorType_var
    }
    masterProfile: {
      count: masterCount_var
      dnsPrefix: mastersEndpointDNSNamePrefix
    }
    agentPoolProfiles: [
      {
        name: 'agentpools'
        count: agentCount_var
        vmSize: agentVMSize_var
        dnsPrefix: agentsEndpointDNSNamePrefix
      }
    ]
    diagnosticsProfile: {
      vmDiagnostics: {
        enabled: enableDiagnostics_var
      }
    }
    linuxProfile: {
      adminUsername: adminUsername
      ssh: {
        publicKeys: [
          {
            keyData: sshRSAPublicKey_var
          }
        ]
      }
    }
  }
}

output masterFQDN string = reference('Microsoft.ContainerService/containerServices/containerservice-${resourceGroup().name}').masterProfile.fqdn
output sshMaster0 string = 'ssh ${adminUsername}@${reference('Microsoft.ContainerService/containerServices/containerservice-${resourceGroup().name}').masterProfile.fqdn} -A -p 2200'
output agentFQDN string = reference('Microsoft.ContainerService/containerServices/containerservice-${resourceGroup().name}').agentPoolProfiles[0].fqdn