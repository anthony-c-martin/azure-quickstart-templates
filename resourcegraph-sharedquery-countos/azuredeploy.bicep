param queryName string {
  metadata: {
    description: 'The name of the shared query.'
  }
  default: 'Count VMs by OS'
}
param queryCode string {
  metadata: {
    description: 'The Azure Resource Graph query to be saved to the shared query.'
  }
  default: 'Resources | where type =~ \'Microsoft.Compute/virtualMachines\' | summarize count() by tostring(properties.storageProfile.osDisk.osType)'
}
param queryDescription string {
  metadata: {
    description: 'The description of the saved Azure Resource Graph query.'
  }
  default: 'This shared query counts all virtual machine resources and summarizes by the OS type.'
}

resource queryName_res 'Microsoft.ResourceGraph/queries@2018-09-01-preview' = {
  name: queryName
  location: 'global'
  properties: {
    query: queryCode
    description: queryDescription
  }
}