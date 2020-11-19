param existingRIPSubId string {
  metadata: {
    description: 'The ID of the subscription containing your existing reserved IP.'
  }
}
param existingRIPResourceGroupName string {
  metadata: {
    description: 'The name of the resource group containing your existing reserved IP.'
  }
}
param existingRIPName string {
  metadata: {
    description: 'The name of your existing reserved IP.'
  }
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var network_LB_Public_Name_var = 'publicLB'
var network_LB_Public_Id = network_LB_Public_Name.id
var network_LB_Public_FEName = 'publicLBFE'
var network_LB_Public_FEId = '${network_LB_Public_Id}/frontendIPConfigurations/${network_LB_Public_FEName}'
var network_LB_Public_BEPoolName = 'publicLBBEPool'
var network_LB_Public_NatRule_SSH_vm_Name = 'fg1SSHNat'
var network_LB_Public_NatRule_SSH_vm_PublicPort = '50101'
var network_LB_Public_Name2_var = 'publicLB2'
var network_LB_Public_Id2 = network_LB_Public_Name2.id
var network_LB_Public_FEName2 = 'publicLBFE2'
var network_LB_Public_FEId2 = '${network_LB_Public_Id2}/frontendIPConfigurations/${network_LB_Public_FEName2}'
var network_LB_Public_BEPoolName2 = 'publicLBBEPool2'
var network_LB_Public_NatRule_SSH_vm_Name2 = 'fg1SSHNat2'
var network_LB_Public_NatRule_SSH_vm_PublicPort2 = '50101'
var network_PIP_Reserved_Name_var = 'goliveARMPIP'
var network_PIP_Reserved_Id = network_PIP_Reserved_Name.id
var network_PIP_Reserved_FQDN = 'golivereservedip'
var network_PIP_Reserved_Id2 = '/subscriptions/${existingRIPSubId}/resourceGroups/${existingRIPResourceGroupName}/providers/Microsoft.Network/publicIPAddresses/${existingRIPName}'

resource network_PIP_Reserved_Name 'Microsoft.Network/publicIPAddresses@2015-06-15' = {
  name: network_PIP_Reserved_Name_var
  location: location
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: network_PIP_Reserved_FQDN
    }
  }
}

resource network_LB_Public_Name 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: network_LB_Public_Name_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: network_LB_Public_FEName
        properties: {
          publicIPAddress: {
            id: network_PIP_Reserved_Id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: network_LB_Public_BEPoolName
      }
    ]
    inboundNatRules: [
      {
        name: network_LB_Public_NatRule_SSH_vm_Name
        properties: {
          frontendIPConfiguration: {
            id: network_LB_Public_FEId
          }
          protocol: 'Tcp'
          frontendPort: network_LB_Public_NatRule_SSH_vm_PublicPort
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
  }
  dependsOn: [
    network_PIP_Reserved_Id
  ]
}

resource network_LB_Public_Name2 'Microsoft.Network/loadBalancers@2015-06-15' = {
  name: network_LB_Public_Name2_var
  location: location
  properties: {
    frontendIPConfigurations: [
      {
        name: network_LB_Public_FEName2
        properties: {
          publicIPAddress: {
            id: network_PIP_Reserved_Id2
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: network_LB_Public_BEPoolName2
      }
    ]
    inboundNatRules: [
      {
        name: network_LB_Public_NatRule_SSH_vm_Name2
        properties: {
          frontendIPConfiguration: {
            id: network_LB_Public_FEId2
          }
          protocol: 'Tcp'
          frontendPort: network_LB_Public_NatRule_SSH_vm_PublicPort2
          backendPort: 22
          enableFloatingIP: false
        }
      }
    ]
  }
}