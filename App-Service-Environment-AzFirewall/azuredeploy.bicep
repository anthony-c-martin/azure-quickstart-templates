@description('Location (region) for all resources.  Use the location value, not the display name, e.g. eastus, not East US 2')
param location string = resourceGroup().location

@description('Name of the ASE resource')
param aseName string = 'ASE${uniqueString(resourceGroup().id)}'

@description('The name of the vNet')
param vnetResourceName string = 'virtualNetwork'

@description('Name of the initial ASE App (without the FQDN)')
param applicationName string = 'application1'

@allowed([
  0
  3
])
@description('0 = public VIP only, 1 = only ports 80/443 are mapped to ILB VIP, 2 = only FTP ports are mapped to ILB VIP, 3 = both ports 80/443 and FTP ports are mapped to an ILB VIP.')
param internalLoadBalancingMode int = 3

@description('Subnet name which will contain the App Service Environment')
param aseSubnetName string = 'ase-subnet'

@description('Name of the app service')
param serverFarmsAseAspName string = 'ase-asp'

@description('The location of resources, such as templates and DSC modules, that the template depends on')
param artifactsLocation string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/App-Service-Environment-AzFirewall/'

@description('The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.')
@secure()
param artifactsLocationSasToken string = ''

@description('Address range for the virtual network in CIDR notation')
param vnetAddressRange string = '10.0.0.0/16'

@description('Address range for the ASE subnet in CIDR notation within the vnetAddress range')
param aseSubnetAddressRange string = '10.0.0.0/24'

@description('Name for the NSG attached to the ASE subnet')
param aseNSGName string = 'ase-NSG'

@description('Name of the Route Table attached to the ASE subnet')
param aseRouteTableName string = 'ase-RouteTable'

@description('Name of the Azure Firewall')
param azureFirewallName string = 'azFirewall'

@description('Toggle whether to deploy the Azure Firewall')
param deployAzureFirewall bool = true

@description('Name of the Azure Firewall Route Table')
param azureFirewallRouteTableName string = 'azFirewall-RouteTable'

@description('Address range that will be used by the Azure Firewall Subnet within the vnetAddress range')
param azureFirewallSubnetAddressRange string = '10.0.1.0/24'

@description('Name for the Azure Firewall public IP resource')
param azureFirewallPublicIP string = 'AzFirewall-pip'

@description('The collection of resource tags passed from parameters file')
param tags object = {}

@description('Service Endpoints enabled on the ASE subnet')
param aseSubnetServiceEndpoints array = []

@description('List of ASE management IP addresses')
param aseManagementIps array = []

@description('FQDNs to whitelist for Azure Monitor')
param azureMonitorFQDNs array

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

resource aseName_resource 'Microsoft.Web/hostingEnvironments@2019-08-01' = {
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
  dependsOn: [
    BuildOrUpdateASENetworking
  ]
}

resource serverFarmsAseAspName_resource 'Microsoft.web/serverfarms@2019-08-01' = {
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
  dependsOn: [
    aseName_resource
  ]
}

resource applicationName_resource 'Microsoft.Web/sites@2019-08-01' = {
  name: applicationName
  location: location
  tags: {
    displayName: 'Deploy Web App'
  }
  kind: 'app'
  properties: {
    enabled: true
    serverFarmId: serverFarmsAseAspName_resource.id
    reserved: false
    scmSiteAlsoStopped: false
    hostingEnvironmentProfile: {
      id: aseName_resource.id
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
  dependsOn: [
    BuildOrUpdateASENetworking
  ]
}