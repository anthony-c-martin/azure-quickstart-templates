@allowed([
  'eastus'
  'eastus2'
  'northcentralus'
  'southcentralus'
  'westus'
  'northeurope'
  'westeurope'
  'eastasia'
  'southeastasia'
  'japaneast'
  'japanwest'
  'australiaeast'
  'australiasoutheast'
])
@description('Deployment location')
param location string = 'eastus'

@description('SQL Datawarehouse Admin Username')
param sqlDWDBAdminName string

@description('SQL Datawarehouse Admin password')
@secure()
param sqlDWAdminPassword string

@description('Job Id of the create table automation Job, use https://www.guidgenerator.com to generate unique jobid Ex:5f32ff4e-a5c5-47af-8b70-981c896a9163')
param jobId string

@description('Job Id of the sign-up automation Job, use https://www.guidgenerator.com to generate unique jobid Ex:5f32ff4e-a5c5-47af-8b70-981c896a9163')
param jobIdSignup string

@description('Job Id of the workflow automation Job, use https://www.guidgenerator.com to generate unique jobid Ex:5f32ff4e-a5c5-47af-8b70-981c896a9163')
param jobIdWorkflow string

@description('Job Id of the workflow automation Job, use https://www.guidgenerator.com to generate unique jobid Ex:5f32ff4e-a5c5-47af-8b70-981c896a9163')
param jobIdCont string

@description('Start time of the data slice. ex: 2016-09-23T18:00:00')
param start string

@description('End time of the data slice. ex: 2016-09-23T19:00:00')
param end string

@description('Tags for the resources')
param tag object = {
  value1: 'informatica'
}

@description('Valid Username to login into your Azure Portal')
param azurePortalUsername string

@description('Valid Password to login into your Azure Portal')
@secure()
param azurePortalPassword string

@description('Username to login into informatica vm')
param adminUsernameInformaticaVm string

@description('Password to login into informatica vm')
@secure()
param adminPasswordInformaticaVm string

@description(' Public IP dns prefix')
param publicIPdnsPrefix string = 'infodns'

@description('Informatica Cloud Email ID')
param userEmail string

@description('Informatica Cloud Username')
param informaticaUsername string

@description('Informatica Cloud password')
@secure()
param informaticaUserPassword string

@description('First name for Informatica Sign up')
param userFirstname string = 'tester'

@description('Last name for Informatica Sign up')
param userLastname string = 'master'

@description('User title for Informatica Sign up')
param userTitle string = 'mytitle'

@description('User phone number for Informatica Sign up. Only numbers Ex: 1234567890')
param userPhone string = '1234567890'

@description('Organization for Informatica Sign up')
param orgName string = 'sysgain'

@description('Organization Address for Informatica Sign up')
param orgAddress string = 'myadd'

@description('Organization city for Informatica Sign up')
param orgCity string = 'mycity'

@allowed([
  'AL'
  'AZ'
  'AR'
  'CA'
  'CT'
  'HI'
  'IL'
  'IN'
  'KS'
  'MI'
  'NE'
  'NY'
  'OH'
  'TX'
  'UT'
  'WA'
  'WI'
])
@description('Organization state for Informatica Sign up, Hint:Pass State Postal Codes Ex:CA')
param orgState string = 'CA'

@description('Organization zipcode for Informatica Sign up')
param orgZipcode string = '98512'

@description('Organization\'s country for Informatica Sign up, Hint:Pass Country\'s ISO Codes Ex:US')
param orgCountry string = 'US'

@allowed([
  '0_10'
  '11_25'
  '26_50'
  '51_100'
  '101_500'
  '501_1000'
  '1001_5000'
  '5001_'
])
@description('Organization\'s Employees for Informatica Sign up')
param orgEmployees string = '5001_'

@description('Base URL for the reference templates and scripts')
param baseUrl string = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/informatica-adf-hdinsight-powerbi'

var clientID = 'xSwkg5OMQCT4PxrIz5HrFOuq0rmiBUAV'
var publicIPdns = concat(publicIPdnsPrefix, uniqueString(resourceGroup().id))
var hivescript = ''
var sysgainMsEmail = 'syshyd${uniqueString(resourceGroup().id)}279@gmail.com'
var sysgainMsPassword = uniqueString(resourceGroup().id)
var automationLocation = 'East US 2'
var arguments = '${informaticaUsername} ${informaticaUserPassword}'
var sqlDWServName = 'sqlser'
var sqlDWDBName = 'testdwdb'
var azureRmUsername = azurePortalUsername
var azureRmPassword = azurePortalPassword
var automationAccountName = 'createtbl'
var accountName = concat(automationAccountName, uniqueString(resourceGroup().id))
var credentialName = 'aocred'
var runbookName = 'createtable'
var dataFactName = 'adf'
var tableName = 'bi9'
var vmName = 'informvm'
var storageAccountName = 'infosa'
var adfstorageAccountName = 'adfsa'
var storageAccName = concat(storageAccountName, uniqueString(resourceGroup().id))
var adfstorageAccName = concat(adfstorageAccountName, uniqueString(resourceGroup().id))
var sqlDWServerName = concat(sqlDWServName, uniqueString(resourceGroup().id))
var dataFactoryName = concat(dataFactName, uniqueString(resourceGroup().id))
var pubicIPAddressName = '${vmName}-publicIp'
var vnetName = '${vmName}-vnet'
var networkInterfaceName = '${vmName}-nic'
var networkSecurityGroupsName = '${vmName}-nsg'
var subnet1Name = 'subnet1'
var storageLinkedServiceName = 'AzureStorageLinkedService'
var hdInsightOnDemandLinkedServiceName = 'HDInsightOnDemandLinkedService'
var azureSqlDWLinkedServiceName = 'AzureSqlDWLinkedService'
var inforAutomationAccName = 'signup'
var automationAccName = concat(inforAutomationAccName, uniqueString(resourceGroup().id))
var credential1Name = 'AzureRmCredentials'
var wfAutomationAccName = 'workflow'
var wfaAtomationAccountName = concat(wfAutomationAccName, uniqueString(resourceGroup().id))
var serviceLevelObjective = 'DW100'
var ip = '138.91.243.84:10011'
var startIpAddress = '0.0.0.0'
var endIpAddress = '255.255.255.255'
var inputFolderPath = 'adfgetstarted/inputdata'
var outputFolderPath = 'adfgetstarted/partitioneddata'
var vnetAddressPrefix = '10.2.0.0/16'
var subnet1Prefix = '10.2.0.0/24'
var storageAccountType = 'Standard_LRS'
var vmSize = 'Standard_F4s'
var storageContainer = 'vhds'
var imagePublisher = 'informatica-cloud'
var imageOffer = 'informatica-cloud'
var imageVersion = 'latest'
var imageSKU = 'informatica_cloud_secure_agent_32_bit'
var subnetRef = '${resourceId('Microsoft.Network/virtualNetworks', vnetName)}/subnets/${subnet1Name}'
var storageApiVersion = '2015-06-15'
var networkApiVersion = '2015-06-15'
var computeApiVersion = '2015-06-15'
var sqlApiVersion = '2014-04-01'
var sqldbApiVersion = '2015-05-01-preview'
var sqlfirewallrulesApiVersion = '2014-04-01'
var version = '3.2'
var sqlVersion = '12.0'
var fileUris = '${armBaseUrl}/scripts/ICExtentionScript.ps1'
var apiVersion = '2015-10-01'
var blobInputDataset = 'AzureBlobInput'
var blobOutputDataset = 'AzureBlobOutput'
var sqlDWOutputDataset = 'AzureSqlDWOutput'
var azureSqlDWLinkedServiceConnectionString = 'Server=tcp:${sqlDWServerName}.database.windows.net,1433;Database=${sqlDWDBName};Trusted_Connection=False;User ID=${sqlDWDBAdminName}@${sqlDWServerName};Password=${sqlDWAdminPassword};Connection Timeout=30;Encrypt=True'
var clusterSize = 1
var timeToLive = '00:45:00'
var frequency = 'Hour'
var armBaseUrl = baseUrl
var interval = 1
var writeBatchSize = 0
var writeBatchTimeout = '00:00:00'
var timeout = '01:00:00'
var automationScriptUri = '${armBaseUrl}/scripts/createTable.ps1'
var runbookDescription = 'Create a Database Table in User provided Datawarehouse'
var sku = 'Basic'
var sqldwlocation = 'eastus'
var collation = 'SQL_Latin1_General_CP1_CI_AS'
var maxSizeBytes = '10995116277760'
var credSetupRunbookName = 'inforunbook1'
var wfrunbookName = 'inforunbook2'
var ccrunbookName = 'container1'
var wfrunbookUrl = '${armBaseUrl}/runbooks/info-restapi-workflow.ps1'
var containerPsUri = '${armBaseUrl}/runbooks/info-container-crt.ps1'
var credsrunbookUrl = '${armBaseUrl}/runbooks/info-restapi-signup.ps1'
var publicIpAddressUrl = '${armBaseUrl}/nested/public-ip.json'
var storageAccountUrl = '${armBaseUrl}/nested/storage.json'
var virtualNetworkUrl = '${armBaseUrl}/nested/vnet-subnet.json'
var networkInterfaceUrl = '${armBaseUrl}/nested/network-interface.json'
var networkSecurityGroupUrl = '${armBaseUrl}/nested/info-nsg.json'
var virtualMachineUrl = '${armBaseUrl}/nested/virtual-machine-with-plan.json'
var virtualMachineExtUrl = '${armBaseUrl}/nested/info-csa-extension.json'
var sqlDataWareHouseSetupURL = '${armBaseUrl}/nested/sqldatawarehouse.json'
var createTableAutomationSetupURL = '${armBaseUrl}/nested/createtableautomationjob.json'
var adfSetupURL = '${armBaseUrl}/nested/azuredatafactory.json'
var workflowAutomationSetupURL = '${armBaseUrl}/nested/workflow-automation.json'
var credentialsAutomationSetupURL = '${armBaseUrl}/nested/info-signup-automation.json'
var createContainerAutomationSetupUrl = '${armBaseUrl}/nested/contcreate-automation.json'
var informaticaTags = {
  type: 'object'
  provider: 'AACF690D-C725-4C78-9B1E-E586595B369F'
}
var quickstartTags = {
  type: 'object'
  name: 'informatica-adf-hdinsight-powerbi'
}

module publicIpAddressDeploy 'nested/public-ip.bicep' = {
  name: 'publicIpAddressDeploy'
  params: {
    location: location
    networkApiVersion: networkApiVersion
    publicIPAddressName: pubicIPAddressName
    publicIPdnsPrefix: publicIPdns
    tag: {
      key1: 'Public IP Address'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module storageAccountDeploy 'nested/storage.bicep' = {
  name: 'storageAccountDeploy'
  params: {
    location: location
    storageApiVersion: storageApiVersion
    storageAccountType: storageAccountType
    storageAccountName: storageAccName
    tag: {
      key1: 'Storage Account'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module adfstorageAccountDeploy 'nested/storage.bicep' = {
  name: 'adfstorageAccountDeploy'
  params: {
    location: location
    storageApiVersion: storageApiVersion
    storageAccountType: storageAccountType
    storageAccountName: adfstorageAccName
    tag: {
      key1: 'Storage Account'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module virtualNetworkDeploy 'nested/vnet-subnet.bicep' = {
  name: 'virtualNetworkDeploy'
  params: {
    location: location
    networkApiVersion: networkApiVersion
    vnetName: vnetName
    subnet1Name: subnet1Name
    vnetAddressPrefix: vnetAddressPrefix
    subnet1Prefix: subnet1Prefix
    tag: {
      key1: 'Virtual Network'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module networkInterfaceDeploy 'nested/network-interface.bicep' = {
  name: 'networkInterfaceDeploy'
  params: {
    location: location
    networkApiVersion: networkApiVersion
    networkInterfaceName: networkInterfaceName
    networkSecurityGroupName: networkSecurityGroupsName
    publicIPAddressName: pubicIPAddressName
    subnetRef: subnetRef
    tag: {
      key1: 'Network Interface'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    virtualNetworkDeploy
    networkSecurityGroupDeploy
    publicIpAddressDeploy
  ]
}

module networkSecurityGroupDeploy 'nested/info-nsg.bicep' = {
  name: 'networkSecurityGroupDeploy'
  params: {
    location: location
    networkApiVersion: networkApiVersion
    networkSecurityGroupsName: networkSecurityGroupsName
    tag: {
      key1: 'Network Security Group'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module virtualMachineDeploy 'nested/virtual-machine-with-plan.bicep' = {
  name: 'virtualMachineDeploy'
  params: {
    location: location
    computeApiVersion: computeApiVersion
    vmName: vmName
    storageAccountName: storageAccName
    vmStorageAccountContainerName: storageContainer
    vmSize: vmSize
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageVersion: imageVersion
    imageSKU: imageSKU
    adminUsername: adminUsernameInformaticaVm
    adminPassword: adminPasswordInformaticaVm
    networkInterfaceName: networkInterfaceName
    tag: {
      key1: 'Virtual Machine'
      value1: tag.value1
    }
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    'storageAccountDeploy'
    networkInterfaceDeploy
  ]
}

module virtualMachineExtDeploy 'nested/info-csa-extension.bicep' = {
  name: 'virtualMachineExtDeploy'
  params: {
    vmName: vmName
    location: location
    fileUris: fileUris
    arguments: arguments
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    virtualMachineDeploy
    informaticaCredentialsAutomationSetup
  ]
}

module informaticaCredentialsAutomationSetup 'nested/info-signup-automation.bicep' = {
  name: 'informaticaCredentialsAutomationSetup'
  params: {
    jobIdSignup: jobIdSignup
    automationAccountName: automationAccName
    credential1Name: credential1Name
    cred1Username: azureRmUsername
    cred1Password: azureRmPassword
    runbookName: credSetupRunbookName
    location: automationLocation
    runbookUrl: credsrunbookUrl
    sku: sku
    ip: ip
    sysgain_ms_email: sysgainMsEmail
    sysgain_ms_password: sysgainMsPassword
    user_email: userEmail
    informatica_user_name: informaticaUsername
    informatica_user_password: informaticaUserPassword
    user_firstname: userFirstname
    user_lastname: userLastname
    user_title: userTitle
    user_phone: userPhone
    org_name: orgName
    org_address: orgAddress
    org_city: orgCity
    org_state: orgState
    org_zipcode: orgZipcode
    org_country: orgCountry
    org_employees: orgEmployees
    client_id: clientID
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module workflowAutomationSetup 'nested/workflow-automation.bicep' = {
  name: 'workflowAutomationSetup'
  params: {
    jobIdWorkflow: jobIdWorkflow
    automationAccountName: wfaAtomationAccountName
    credential1Name: credential1Name
    cred1Username: azureRmUsername
    cred1Password: azureRmPassword
    runbookName: wfrunbookName
    location: automationLocation
    runbookUrl: wfrunbookUrl
    sku: sku
    ip: ip
    sysgain_ms_email: sysgainMsEmail
    sysgain_ms_password: sysgainMsPassword
    informatica_user_name: informaticaUsername
    informatica_user_password: informaticaUserPassword
    informatica_csa_vmname: vmName
    client_id: clientID
    adfStorageAccName: adfstorageAccName
    adfStorageAccKey: reference('adfstorageAccountDeploy').outputs.primaryKey.value
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    informaticaCredentialsAutomationSetup
    virtualMachineExtDeploy
    sqlDataWarehoueSetup
    adfstorageAccountDeploy
    createContainerAutomationSetup
  ]
}

module sqlDataWarehoueSetup 'nested/sqldatawarehouse.bicep' = {
  name: 'sqlDataWarehoueSetup'
  params: {
    location: sqldwlocation
    sqlDWServerName: sqlDWServerName
    sqlDWDBAdminName: sqlDWDBAdminName
    sqlDWAdminPassword: sqlDWAdminPassword
    sqlDWDBName: sqlDWDBName
    serviceLevelObjective: serviceLevelObjective
    startIpAddress: startIpAddress
    endIpAddress: endIpAddress
    'sql-api-version': sqlApiVersion
    'sqldb-api-version': sqldbApiVersion
    'sqlfirewallrules-api-version': sqlfirewallrulesApiVersion
    collation: collation
    maxSizeBytes: maxSizeBytes
    version: sqlVersion
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
}

module createTableAutomationSetup 'nested/createtableautomationjob.bicep' = {
  name: 'createTableAutomationSetup'
  params: {
    sqlDWServerName: sqlDWServerName
    sqlDWDBAdminName: sqlDWDBAdminName
    sqlDWAdminPassword: sqlDWAdminPassword
    sqlDWDBName: sqlDWDBName
    jobId: jobId
    accountName: accountName
    credentialName: credentialName
    runbookName: runbookName
    location: automationLocation
    scriptUri: automationScriptUri
    runbookDescription: runbookDescription
    sku: sku
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    sqlDataWarehoueSetup
  ]
}

module createContainerAutomationSetup 'nested/contcreate-automation.bicep' = {
  name: 'createContainerAutomationSetup'
  params: {
    adfStorageAccName: adfstorageAccName
    adfStorageAccKey: reference('adfstorageAccountDeploy').outputs.primaryKey.value
    jobIdCont: jobIdCont
    automationAccountName: wfaAtomationAccountName
    credential1Name: credential1Name
    cred1Username: azureRmUsername
    cred1Password: azureRmPassword
    runbookName: ccrunbookName
    location: automationLocation
    scriptUri: containerPsUri
    sku: sku
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    adfstorageAccountDeploy
  ]
}

module dataFactorySetup 'nested/azuredatafactory.bicep' = {
  name: 'dataFactorySetup'
  params: {
    sqlDWServerName: sqlDWServerName
    sqlDWDBAdminName: sqlDWDBAdminName
    sqlDWAdminPassword: sqlDWAdminPassword
    sqlDWDBName: sqlDWDBName
    dataFactoryName: dataFactoryName
    start: start
    end: end
    tableName: tableName
    inputFolderPath: inputFolderPath
    adfstorageAccountName: adfstorageAccName
    outputFolderPath: outputFolderPath
    apiVersion: apiVersion
    storageLinkedServiceName: storageLinkedServiceName
    hdInsightOnDemandLinkedServiceName: hdInsightOnDemandLinkedServiceName
    azureSqlDWLinkedServiceName: azureSqlDWLinkedServiceName
    blobInputDataset: blobInputDataset
    blobOutputDataset: blobOutputDataset
    sqlDWOutputDataset: sqlDWOutputDataset
    azureSqlDWLinkedServiceConnectionString: azureSqlDWLinkedServiceConnectionString
    clusterSize: clusterSize
    version: version
    timeToLive: timeToLive
    frequency: frequency
    interval: interval
    writeBatchSize: writeBatchSize
    writeBatchTimeout: writeBatchTimeout
    timeout: timeout
    script: hivescript
    informaticaTags: informaticaTags
    quickstartTags: quickstartTags
  }
  dependsOn: [
    sqlDataWarehoueSetup
    createContainerAutomationSetup
  ]
}