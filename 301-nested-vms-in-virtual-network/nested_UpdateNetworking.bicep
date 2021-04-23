param reference_parameters_HostNetworkInterface2Name_ipconfigurations_0_properties_privateIPAddress object
param reference_parameters_HostNetworkInterface1Name_ipconfigurations_0_properties_privateIPAddress object
param resourceId_Microsoft_Network_virtualNetworks_subnets_parameters_virtualNetworkName_parameters_NATSubnetName string
param resourceId_Microsoft_Network_publicIPAddresses_parameters_HostPublicIPAddressName string
param resourceId_Microsoft_Network_virtualNetworks_subnets_parameters_virtualNetworkName_parameters_hyperVSubnetName string
param variables_azureVMsSubnetUDRName ? /* TODO: fill in correct type */

@description('Location for all resources.')
param location string

@description('Ghosted Subnet Address Space')
param ghostedSubnetPrefix string

@description('Hyper-V Host Network Interface 1 Name, attached to NAT Subnet')
param HostNetworkInterface1Name string

@description('Hyper-V Host Network Interface 2 Name, attached to Hyper-V LAN Subnet')
param HostNetworkInterface2Name string

resource variables_azureVMsSubnetUDRName_resource 'Microsoft.Network/routeTables@2019-04-01' = {
  name: variables_azureVMsSubnetUDRName
  location: location
  properties: {
    routes: [
      {
        name: 'Nested-VMs'
        properties: {
          addressPrefix: ghostedSubnetPrefix
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: reference_parameters_HostNetworkInterface2Name_ipconfigurations_0_properties_privateIPAddress.ipconfigurations[0].properties.privateIPAddress
        }
      }
    ]
  }
}

resource HostNetworkInterface1Name_resource 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: HostNetworkInterface1Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          primary: 'true'
          privateIPAllocationMethod: 'Static'
          privateIPAddress: reference_parameters_HostNetworkInterface1Name_ipconfigurations_0_properties_privateIPAddress.ipconfigurations[0].properties.privateIPAddress
          subnet: {
            id: resourceId_Microsoft_Network_virtualNetworks_subnets_parameters_virtualNetworkName_parameters_NATSubnetName
          }
          publicIPAddress: {
            id: resourceId_Microsoft_Network_publicIPAddresses_parameters_HostPublicIPAddressName
          }
        }
      }
    ]
  }
}

resource HostNetworkInterface2Name_resource 'Microsoft.Network/networkInterfaces@2019-04-01' = {
  name: HostNetworkInterface2Name
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig'
        properties: {
          primary: 'true'
          privateIPAllocationMethod: 'Static'
          privateIPAddress: reference_parameters_HostNetworkInterface2Name_ipconfigurations_0_properties_privateIPAddress.ipconfigurations[0].properties.privateIPAddress
          subnet: {
            id: resourceId_Microsoft_Network_virtualNetworks_subnets_parameters_virtualNetworkName_parameters_hyperVSubnetName
          }
        }
      }
    ]
    enableIPForwarding: true
  }
}