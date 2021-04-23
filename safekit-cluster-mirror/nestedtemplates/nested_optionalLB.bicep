param resourceId_Microsoft_Network_publicIPAddresses_concat_pip_parameters_VIPDnsLabel string
param resourceId_Microsoft_Network_loadBalancers_frontendIPConfigurations_variables_lbName_variables_frontEndIPConfigName string
param resourceId_Microsoft_Network_loadBalancers_backendAddressPools_variables_lbName_variables_lbPoolName string
param resourceId_Microsoft_Network_loadBalancers_probes_variables_lbName_variables_lbProbeName string
param variables_lbName ? /* TODO: fill in correct type */
param variables_frontEndIPConfigName ? /* TODO: fill in correct type */
param variables_lbPoolName ? /* TODO: fill in correct type */
param variables_lbProbeName ? /* TODO: fill in correct type */

@description('Public VIP dns label (optional. If set, an additionnal Standard SKU, unassociated public IP will be created)')
param VIPDnsLabel string

@allowed([
  'External'
  'none'
])
@description('loadbalancer (optional. If set, a loadbalancer will be created, with the VIP as frontend and the VMs in the backend pool.')
param Loadbalancer string

@description('resources location')
param location string

@description('name of the application module to install on all nodes (optional)')
param moduleName string

resource variables_lbName_resource 'Microsoft.Network/loadBalancers@2018-08-01' = if ((!empty(VIPDnsLabel)) && (!(Loadbalancer == 'none'))) {
  name: variables_lbName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: variables_frontEndIPConfigName
        properties: {
          publicIPAddress: {
            id: resourceId_Microsoft_Network_publicIPAddresses_concat_pip_parameters_VIPDnsLabel
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: variables_lbPoolName
      }
    ]
    loadBalancingRules: [
      {
        name: 'LBRule'
        properties: {
          frontendIPConfiguration: {
            id: resourceId_Microsoft_Network_loadBalancers_frontendIPConfigurations_variables_lbName_variables_frontEndIPConfigName
          }
          backendAddressPool: {
            id: resourceId_Microsoft_Network_loadBalancers_backendAddressPools_variables_lbName_variables_lbPoolName
          }
          protocol: 'Tcp'
          frontendPort: 9453
          backendPort: 9453
          enableFloatingIP: false
          idleTimeoutInMinutes: 5
          probe: {
            id: resourceId_Microsoft_Network_loadBalancers_probes_variables_lbName_variables_lbProbeName
          }
        }
      }
    ]
    probes: [
      {
        name: variables_lbProbeName
        properties: {
          protocol: 'Http'
          port: 9010
          requestPath: '/var/modules/${moduleName}/ready.txt'
          intervalInSeconds: 5
          numberOfProbes: 2
        }
      }
    ]
  }
}