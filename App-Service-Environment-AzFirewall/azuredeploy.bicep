param location string {
  metadata: {
    description: 'Location (region) for all resources.  Use the location value, not the display name, e.g. eastus, not East US 2'
  }
  default: resourceGroup().location
}
param aseName string {
  metadata: {
    description: 'Name of the ASE resource'
  }
  default: 'ASE${uniqueString(resourceGroup().id)}'
}
param vnetResourceName string {
  metadata: {
    description: 'The name of the vNet'
  }
  default: 'virtualNetwork'
}
param applicationName string {
  metadata: {
    description: 'Name of the initial ASE App (without the FQDN)'
  }
  default: 'application1'
}
param internalLoadBalancingMode int {
  allowed: [
    0
    3
  ]
  metadata: {
    description: '0 = public VIP only, 1 = only ports 80/443 are mapped to ILB VIP, 2 = only FTP ports are mapped to ILB VIP, 3 = both ports 80/443 and FTP ports are mapped to an ILB VIP.'
  }
  default: 3
}
param aseSubnetName string {
  metadata: {
    description: 'Subnet name which will contain the App Service Environment'
  }
  default: 'ase-subnet'
}
param serverFarmsAseAspName string {
  metadata: {
    description: 'Name of the app service'
  }
  default: 'ase-asp'
}
param artifactsLocation string {
  metadata: {
    description: 'The location of resources, such as templates and DSC modules, that the template depends on'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/App-Service-Environment-AzFirewall/'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param vnetAddressRange string {
  metadata: {
    description: 'Address range for the virtual network in CIDR notation'
  }
  default: '10.0.0.0/16'
}
param aseSubnetAddressRange string {
  metadata: {
    description: 'Address range for the ASE subnet in CIDR notation within the vnetAddress range'
  }
  default: '10.0.0.0/24'
}
param aseNSGName string {
  metadata: {
    description: 'Name for the NSG attached to the ASE subnet'
  }
  default: 'ase-NSG'
}
param aseRouteTableName string {
  metadata: {
    description: 'Name of the Route Table attached to the ASE subnet'
  }
  default: 'ase-RouteTable'
}
param azureFirewallName string {
  metadata: {
    description: 'Name of the Azure Firewall'
  }
  default: 'azFirewall'
}
param deployAzureFirewall bool {
  metadata: {
    description: 'Toggle whether to deploy the Azure Firewall'
  }
  default: true
}
param azureFirewallRouteTableName string {
  metadata: {
    description: 'Name of the Azure Firewall Route Table'
  }
  default: 'azFirewall-RouteTable'
}
param azureFirewallSubnetAddressRange string {
  metadata: {
    description: 'Address range that will be used by the Azure Firewall Subnet within the vnetAddress range'
  }
  default: '10.0.1.0/24'
}
param azureFirewallPublicIP string {
  metadata: {
    description: 'Name for the Azure Firewall public IP resource'
  }
  default: 'AzFirewall-pip'
}
param tags object {
  metadata: {
    description: 'The collection of resource tags passed from parameters file'
  }
  default: {}
}
param aseSubnetServiceEndpoints array {
  metadata: {
    description: 'Service Endpoints enabled on the ASE subnet'
  }
  default: []
}
param aseManagementIps array {
  metadata: {
    description: 'List of ASE management IP addresses'
  }
  default: []
}
param azureMonitorFQDNs array {
  metadata: {
    description: 'FQDNs to whitelist for Azure Monitor'
  }
}

var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetResourceName, aseSubnetName)
var nestedTemplateUri = uri(artifactsLocation, 'nestedtemplates/vnet.json${artifactsLocationSasToken}')

module BuildOrUpdateASENetworking '?' /*TODO: replace with correct path to [variables('nestedTemplateUri')]*/ = {
  name: 'BuildOrUpdateASENetworking'
  params: {
    location: location
    vnetResourceName: vnetResourceName
    vnetAddressRange: vnetAddressRange
    aseSubnetName: aseSubnetName
    aseSubnetAddressRange: aseSubnetAddressRange
    aseNSGName: aseNSGName
    aseRouteTableName: aseRouteTableName
    azureFirewallName: azureFirewallName
    azureFirewallSubnetAddressRange: azureFirewallSubnetAddressRange
    azureFirewallRouteTableName: azureFirewallRouteTableName
    azureFirewallPublicIP: azureFirewallPublicIP
    deployAzureFirewall: deployAzureFirewall
    tags: tags
    aseSubnetServiceEndpoints: aseSubnetServiceEndpoints
    aseManagementIps: aseManagementIps
    azureMonitorFQDNs: azureMonitorFQDNs
  }
}

resource aseName_res 'Microsoft.Web/hostingEnvironments@2019-08-01' = {
  name: aseName
  location: location
  kind: 'ASEV2'
  tags: {
    displayName: 'Deploy ASE'
  }
  properties: {
    name: aseName
    location: location
    ipsslAddressCount: 0
    internalLoadBalancingMode: internalLoadBalancingMode
    virtualNetwork: {
      id: subnetId
    }
  }
}

resource serverFarmsAseAspName_res 'Microsoft.web/serverfarms@2019-08-01' = {
  name: serverFarmsAseAspName
  location: location
  sku: {
    name: 'I1'
    tier: 'Isolated'
  }
  tags: {
    displayName: 'Deploy App Service'
  }
  kind: 'app'
  properties: {
    name: serverFarmsAseAspName
    workerSize: '0'
    workerSizeId: '0'
    numberOfWorkers: '1'
    reserved: false
    hostingEnvironment: aseName
  }
}

resource applicationName_res 'Microsoft.Web/sites@2019-08-01' = {
  name: applicationName
  location: location
  tags: {
    displayName: 'Deploy Web App'
  }
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: serverFarmsAseAspName_res.id
    reserved: false
    scmSiteAlsoStopped: false
    hostingEnvironmentProfile: {
      id: aseName_res.id
    }
    clientAffinityEnabled: true
    clientCertEnabled: false
    hostNamesDisabled: false
    containerSize: 0
    dailyMemoryTimeQuota: 0
    httpsOnly: false
  }
}

resource microsoft_insights_components_applicationName 'microsoft.insights/components@2018-05-01-preview' = {
  name: applicationName
  location: location
  tags: {
    applicationType: 'web'
    displayName: 'Deploy Application Insights'
  }
  kind: 'web'
  properties: {
    Application_Type: 'web'
    Flow_Type: 'Redfield'
    Request_Source: 'AppServiceEnablementCreate'
  }
}