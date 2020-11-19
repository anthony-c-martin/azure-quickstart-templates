param aseName string {
  metadata: {
    description: 'Name of the App Service Environment'
  }
}
param aseLocation string {
  allowed: [
    'Central US'
    'East US'
    'East US 2'
    'North Central US'
    'South Central US'
    'West Central US'
    'West US'
    'West US 2'
    'Canada Central'
    'North Europe'
    'West Europe'
    'East Asia'
    'Southeast Asia'
    'Japan East'
    'Japan West'
    'Brazil South'
    'Australia East'
    'Australia Southeast'
    'West India'
    'Central India'
    'South India'
  ]
  metadata: {
    description: 'Location of the App Service Environment'
  }
}
param ipSslAddressCount int {
  metadata: {
    description: 'Number of IP addresses for the IP-SSL address pool.'
  }
  default: 1
}
param existingVnetResourceId string {
  metadata: {
    description: 'ARM Url reference for the virtual network that will contain the ASE.  Use Microsoft.Network for ARM vnets.  Use Microsoft.ClassicNetwork for older ASM vnets.  /subscriptions/subIDGoesHere/resourceGroups/rgNameGoesHere/providers/Microsoft.Network/virtualNetworks/vnetnamegoeshere'
  }
}
param subnetName string {
  metadata: {
    description: 'Subnet name that will contain the App Service Environment'
  }
}
param frontEndSize string {
  allowed: [
    'Medium'
    'Large'
    'ExtraLarge'
  ]
  metadata: {
    description: 'Instance size for the front-end pool.  Maps to P2,P3,P4.'
  }
  default: 'Medium'
}
param frontEndCount int {
  metadata: {
    description: 'Number of instances in the front-end pool.  Minimum of two.'
  }
  default: 2
}
param workerPoolOneInstanceSize string {
  allowed: [
    'Small'
    'Medium'
    'Large'
    'ExtraLarge'
  ]
  metadata: {
    description: 'Instance size for worker pool one.  Maps to P1,P2,P3,P4.'
  }
  default: 'Small'
}
param workerPoolOneInstanceCount int {
  metadata: {
    description: 'Number of instances in worker pool one.  Minimum of two.'
  }
  default: 2
}
param workerPoolTwoInstanceSize string {
  allowed: [
    'Small'
    'Medium'
    'Large'
    'ExtraLarge'
  ]
  metadata: {
    description: 'Instance size for worker pool two.  Maps to P1,P2,P3,P4.'
  }
  default: 'Small'
}
param workerPoolTwoInstanceCount int {
  metadata: {
    description: 'Number of instances in worker pool two.  Can be zero if not using worker pool two.'
  }
  default: 0
}
param workerPoolThreeInstanceSize string {
  allowed: [
    'Small'
    'Medium'
    'Large'
    'ExtraLarge'
  ]
  metadata: {
    description: 'Instance size for worker pool three.  Maps to P1,P2,P3,P4.'
  }
  default: 'Small'
}
param workerPoolThreeInstanceCount int {
  metadata: {
    description: 'Number of instances in worker pool three.  Can be zero if not using worker pool three.'
  }
  default: 0
}

resource aseName_res 'Microsoft.Web/hostingEnvironments@2015-08-01' = {
  name: aseName
  location: aseLocation
  properties: {
    name: aseName
    location: aseLocation
    ipSslAddressCount: ipSslAddressCount
    virtualNetwork: {
      Id: existingVnetResourceId
      Subnet: subnetName
    }
    multiSize: frontEndSize
    multiRoleCount: frontEndCount
    workerPools: [
      {
        workerSizeId: 0
        workerSize: workerPoolOneInstanceSize
        workerCount: workerPoolOneInstanceCount
      }
      {
        workerSizeId: 1
        workerSize: workerPoolTwoInstanceSize
        workerCount: workerPoolTwoInstanceCount
      }
      {
        workerSizeId: 2
        workerSize: workerPoolThreeInstanceSize
        workerCount: workerPoolThreeInstanceCount
      }
    ]
  }
}