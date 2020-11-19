param existingFailoverClusterName string {
  metadata: {
    description: 'Specify the name of the failover cluster'
  }
}
param existingSqlAvailabilityGroup string {
  metadata: {
    description: 'Specify the name of SQL Availability Group for which listener is being created'
  }
}
param existingVmList string {
  metadata: {
    description: 'Specify the Virtual machine list participating in SQL Availability Group e.g. VM1, VM2. Maximum number is 6.'
  }
}
param Listener string {
  metadata: {
    description: 'Specify a name for the listener for SQL Availability Group'
  }
  default: 'aglistener'
}
param ListenerPort int {
  metadata: {
    description: 'Specify the port for listener'
  }
  default: 1433
}
param ListenerIp string {
  metadata: {
    description: 'Specify the available private IP address for the listener from the subnet the existing Vms are part of.'
  }
  default: '10.0.0.7'
}
param existingVnetResourcegroup string {
  metadata: {
    description: 'Specify the resourcegroup for virtual network'
  }
  default: resourceGroup().name
}
param existingVnet string {
  metadata: {
    description: 'Specify the virtual network for Listener IP Address'
  }
}
param existingSubnet string {
  metadata: {
    description: 'Specify the subnet under Vnet for Listener IP address'
  }
}
param existingInternalLoadBalancer string {
  metadata: {
    description: 'Name of existing internal load balancer for the AG listener. Choose Standard Sku if the VMs are not in an availability set.'
  }
}
param ProbePort int {
  metadata: {
    description: 'Specify the load balancer port number (e.g. 59999)'
  }
  default: 59999
}
param Location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

var LoadBalancerResourceId = resourceId('Microsoft.Network/loadBalancers', existingInternalLoadBalancer)
var SubnetResourceId = '${resourceId(existingVnetResourcegroup, 'Microsoft.Network/virtualNetworks', existingVnet)}/subnets/${existingSubnet}'
var VmArray = split(existingVmList, ',')
var VM0 = ((0 < length(VmArray)) ? createArray(resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachines', trim(VmArray[0]))) : json('[]'))
var VM1 = ((1 < length(VmArray)) ? createArray(resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachines', trim(VmArray[1]))) : json('[]'))
var VM2 = ((2 < length(VmArray)) ? createArray(resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachines', trim(VmArray[2]))) : json('[]'))
var VM3 = ((3 < length(VmArray)) ? createArray(resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachines', trim(VmArray[3]))) : json('[]'))
var VM4 = ((4 < length(VmArray)) ? createArray(resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachines', trim(VmArray[4]))) : json('[]'))
var VM5 = ((5 < length(VmArray)) ? createArray(resourceId('Microsoft.SqlVirtualMachine/sqlVirtualMachines', trim(VmArray[5]))) : json('[]'))
var SqlVmResourceIdList = union(VM0, VM1, VM2, VM3, VM4, VM5)

resource existingFailoverClusterName_Listener 'Microsoft.SqlVirtualMachine/SqlVirtualMachineGroups/availabilityGroupListeners@2017-03-01-preview' = {
  name: '${existingFailoverClusterName}/${Listener}'
  location: Location
  properties: {
    AvailabilityGroupName: existingSqlAvailabilityGroup
    LoadBalancerConfigurations: [
      {
        privateIPAddress: {
          IpAddress: ListenerIp
          SubnetResourceId: SubnetResourceId
        }
        LoadBalancerResourceId: LoadBalancerResourceId
        ProbePort: ProbePort
        SqlVirtualMachineInstances: SqlVmResourceIdList
      }
    ]
    Port: ListenerPort
  }
}