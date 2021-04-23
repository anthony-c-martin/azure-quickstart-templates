@description('Object Id of the AAD user or service principal that will have access to the vault. Available from the Get-AzureRMADUser or the Get-AzureRMADServicePrincipal cmdlets')
@secure()
param objectId string = '44b29aa9-ccd0-4314-aaa0-fd4df282b906'

@allowed([
  'Standard'
  'Premium'
])
@description('SKU for the vault')
param vaultSku string = 'Standard'

@description('User name for the Virtual Machine.')
param adminUsername string = 'chefuser'

@description('SSH rsa public key file as a string.')
@secure()
param sshKeyData string = ''

@allowed([
  'Standard_DS3'
  'Standard_DS4'
  'Standard_DS11'
  'Standard_DS12'
  'Standard_DS13'
  'Standard_DS14'
  'Standard_DS3_v2'
  'Standard_DS4_v2'
  'Standard_DS5_v2'
  'Standard_DS11_v2'
  'Standard_DS12_v2'
  'Standard_DS13_v2'
  'Standard_DS14_v2'
  'Standard_DS15_v2'
  'Standard_F4s'
  'Standard_F8s'
  'Standard_F16s'
])
@description('size of the Virtual Machine.')
param vmSize string = 'Standard_DS3'

@description('dens name for chef server')
param chefServerDnsPrefix string = 'chefserver'

@description('chef automate dns name')
param chefAutomateDnsPrefix string = 'chefautomate'

@description('administrator user for chef automate')
param firstName string = ''

@description('administrator user for chef automate')
param lastName string = ''

@description('emaild for chef automate')
param emailId string = 'user@password.com'

@description('Organization name for chef automate')
param organizationName string = 'chef'

@minLength(1)
@description('servicePrinciple')
@secure()
param appID string = ''

@minLength(1)
@description('password')
@secure()
param password string = ''

@description('Location for all resources.')
param location string = resourceGroup().location

var keyvaultSettings = {
  keyVaultApiVersion: '2015-06-01'
  keyVaultName: 'chef-key${substring(prefix, 0, 5)}'
  tenantId: subscription().tenantId
  dbPasswordValue: 'chv-${substring(prefix, 0, 10)}-dbp'
  replicationPasswordValue: 'chv-${substring(prefix, 0, 11)}-rpp'
  clusterTokenValue: 'chv-${substring(prefix, 0, 12)}-ctt'
  clusterNameValue: 'chef-${substring(prefix, 0, 8)}'
  location: location
  objectId: objectId
  vaultSku: vaultSku
  dbPassword: 'dbPassword'
  replicationPassword: 'replicationPassword'
  clusterToken: 'clusterToken'
  clusterName: 'clusterName'
  appID: appID
  password: password
}
var computeSettings = {
  count: 7
  location: location
  computeApiVersion: '2016-04-30-preview'
  adminUsername: adminUsername
  sshKeyData: sshKeyData
  sshKeyPath: '/home/${adminUsername}/.ssh/authorized_keys'
  chefServerUserName: 'delivery'
  managedDiskName: 'dataDisk'
  storageAccountType: 'Premium_LRS'
  diagStorageAccountType: 'Standard_LRS'
  diskCreateOption: 'empty'
  diskSizeGB: 50
  vmSize: vmSize
  imagePublisher: 'Canonical'
  imageOffer: 'UbuntuServer'
  ubuntuOSVersion: '16.04-LTS'
  imageVersion: 'latest'
  chefBEAvailName: 'be-avail'
  leadercomputerName: 'be0'
  followercomputerName1: 'be1'
  followercomputerName2: 'be2'
  leaderExtensionName: 'be0-ex0'
  followerExtensionName1: 'be-ex1'
  followerExtensionName2: 'be-ex2'
  leadercustomData: customData.leaderCustomData
  followercustomData: customData.followerCustomData
  feComputerName0: 'fe0'
  feComputerName1: 'fe1'
  feComputerName2: 'fe2'
  feVmExtensionName0: 'fe0-ex0'
  feVmExtensionName1: 'fe1-ex1'
  feVmExtensionName2: 'fe1-ex2'
  fe0CustomData: customData.fe0Customdata
  feCustomData: customData.feCustomData
  chefFEAvailName: 'fe-avail'
  autoComputerName: 'chefautomate'
  chefAutoExtenName: 'chef-auto-ex'
  automateCustomData: customData.automateCustomData
  firstName: firstName
  lastName: lastName
  emailId: emailId
  organizationName: organizationName
  keyvaultId: '${subscription().id}/resourceGroups/${resourceGroup().name}/providers/Microsoft.KeyVault/vaults/${keyvaultSettings.keyVaultName}'
}
var storageSettings = {
  location: location
  diagStorageAccName: 'diagstr${substring(prefix, 0, 5)}'
  diagStorageAccountType: 'Standard_LRS'
  storageApiVersion: '2015-06-15'
}
var networkSettings = {
  location: location
  networkApiVersion: '2015-06-15'
  leaderNicName: 'be-nic0'
  followerNicName1: 'be-nic1'
  followerNicName2: 'be-nic2'
  feNicName0: 'fe-nic0'
  feNicName1: 'fe-nic1'
  feNicName2: 'fe-nic2'
  chefAutoNicName: 'chefauto-nic'
  feNsg: 'fe-nsg'
  beNsg: 'be-nsg'
  bePoolName1: 'chef-ha-pool-fe'
  bePoolName2: 'chef-ha-pool-ssh-admin'
  felbPublicIPAddressName: 'fe-pip'
  chefAutoPublicIPAddressName: 'chefauto-pip'
  virtualNetworkName: 'chef-vnet'
  addressPrefix: '10.0.0.0/16'
  feSubnetName: 'fe-subnet'
  feSubnetPrefix: '10.0.0.0/24'
  feLoadBalancerName: 'fe-lb'
  beSubnetName: 'be-subnet'
  beSubnetPrefix: '10.0.1.0/24'
  publicIPAddressType: 'Dynamic'
  dnsLabelPrefixFE: concat(chefServerDnsPrefix, substring(prefix, 0, 3))
  dnsLabelPrefixChefAuto: concat(chefAutomateDnsPrefix, substring(prefix, 0, 3))
  diagStorageAccName: 'diagstr${substring(prefix, 0, 5)}'
}
var chef_backend_install_script_base = 'dbPassword=$1\nreplicationPassword=$2\nclusterToken=$3\nclusterName=$4\napt-get install -y apt-transport-https\nwget -qO - https://downloads.chef.io/packages-chef-io-public.key | sudo apt-key add -\necho "deb https://packages.chef.io/stable-apt trusty main" > /etc/apt/sources.list.d/chef-stable.list\napt-get update\napt-get install -y chef-backend\napt-get install -y lvm2 xfsprogs sysstat atop\numount -f /mnt\npvcreate -f /dev/sdc\nvgcreate chef-vg /dev/sdc\nlvcreate -n chef-lv -l 80%VG chef-vg\nmkfs.xfs /dev/chef-vg/chef-lv\nmkdir -p /var/opt/chef-backend\nmount /dev/chef-vg/chef-lv /var/opt/chef-backend\ncat > /etc/chef-backend/chef-backend-secrets.json <<EOF\n{\n"postgresql": {\n"db_superuser_password": "######",\n"replication_password": "#######"\n},\n"etcd": {\n"initial_cluster_token": "########"\n },\n"elasticsearch": {\n"cluster_name": "#########"\n}\n}\nEOF\nsed -i \'0,/######/s//\'$dbPassword\'/\' /etc/chef-backend/chef-backend-secrets.json\nsed -i \'0,/#######/s//\'$replicationPassword\'/\' /etc/chef-backend/chef-backend-secrets.json\nsed -i \'0,/########/s//\'$clusterToken\'/\' /etc/chef-backend/chef-backend-secrets.json\nsed -i \'0,/#########/s//\'$clusterName\'/\' /etc/chef-backend/chef-backend-secrets.json\nIP=`ifconfig eth0 | awk \'/inet addr/{print substr($2,6)}\'`\ncat > /etc/chef-backend/chef-backend.rb <<EOF\npublish_address \'\${IP}\'\npostgresql.log_min_duration_statement = 500\nelasticsearch.heap_size = 3500\npostgresql.md5_auth_cidr_addresses = ["samehost", "samenet", "10.0.0.0/24"]\nEOF\n'
var chef_frontend_install_script_base = 'dbPassword=$1\nfirstName=$2\nlastName=$3\nemailId=$4\norganizationName=$5\nappID=$6\ntenantID=$7\npassword=$8\nobjectId=$9\nkeyVaultName=\${10}\nfqdn=`hostname -f`\napt-get install -y apt-transport-https\napt-get install -y sshpass\nwget -qO - https://downloads.chef.io/packages-chef-io-public.key | sudo apt-key add -\necho "deb https://packages.chef.io/stable-apt trusty main" > /etc/apt/sources.list.d/chef-stable.list\napt-get update\napt-get install -y lvm2 xfsprogs sysstat atop\numount -f /mnt\npvcreate -f /dev/sdc\nvgcreate chef-vg /dev/sdc\nlvcreate -n chef-data -l 20%VG chef-vg\nlvcreate -n chef-logs -l 80%VG chef-vg\nmkfs.xfs /dev/chef-vg/chef-data\nmkfs.xfs /dev/chef-vg/chef-logs\nmkdir -p /var/opt/opscode\nmkdir -p /var/log/opscode\nmount /dev/chef-vg/chef-data /var/opt/opscode\nmount /dev/chef-vg/chef-logs /var/log/opscode\napt-get install -y chef-server-core chef-manage\napt-get install -y libssl-dev libffi-dev python-dev build-essential\necho "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > /etc/apt/sources.list.d/azure-cli.list\napt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893\napt-get update\napt-get install azure-cli\ncat > /etc/opscode/chef-server.rb <<EOF\n\nfqdn "####"\n\nuse_chef_backend true\nchef_backend_members ["10.0.1.6", "10.0.1.5", "10.0.1.4"]\n\nhaproxy[\'remote_postgresql_port\'] = 5432\nhaproxy[\'remote_elasticsearch_port\'] = 9200\n\npostgresql[\'external\'] = true\npostgresql[\'vip\'] = \'127.0.0.1\'\npostgresql[\'db_superuser\'] = \'chef_pgsql\'\npostgresql[\'db_superuser_password\'] = \'######\'\n\nopscode_solr4[\'external\'] = true\nopscode_solr4[\'external_url\'] = \'http://127.0.0.1:9200\'\nopscode_erchef[\'search_provider\'] = \'elasticsearch\'\nopscode_erchef[\'search_queue_mode\'] = \'batch\'\n\nbookshelf[\'storage_type\'] = :sql\n\nrabbitmq[\'enable\'] = false\nrabbitmq[\'management_enabled\'] = false\nrabbitmq[\'queue_length_monitor_enabled\'] = false\n\nopscode_expander[\'enable\'] = false\n\ndark_launch[\'actions\'] = false\n\nopscode_erchef[\'nginx_bookshelf_caching\'] = :on\nopscode_erchef[\'s3_url_expiry_window_size\'] = \'50%\'\nopscode_erchef[\'s3_url_expiry_window_size\'] = \'100%\'\nlicense[\'nodes\'] = 999999\noc_chef_authz[\'http_init_count\'] = 100\noc_chef_authz[\'http_max_count\'] = 100\noc_chef_authz[\'http_queue_max\'] = 200\noc_bifrost[\'db_pool_size\'] = 20\noc_bifrost[\'db_pool_queue_max\'] = 40\noc_bifrost[\'db_pooler_timeout\'] = 2000\nopscode_erchef[\'depsolver_worker_count\'] = 4\nopscode_erchef[\'depsolver_timeout\'] = 20000\nopscode_erchef[\'db_pool_size\'] = 20\nopscode_erchef[\'db_pool_queue_max\'] = 40\nopscode_erchef[\'db_pooler_timeout\'] = 2000\nopscode_erchef[\'authz_pooler_timeout\'] = 2000\nEOF\nsed -i \'0,/######/s//\'$dbPassword\'/\' /etc/opscode/chef-server.rb\nsed -i \'0,/####/s//\'$fqdn\'/\' /etc/opscode/chef-server.rb\n'
var chef_automate_install_script_base = 'appID=$1\ntenantID=$2\npassword=$3\nobjectId=$4\nkeyVaultName=$5\napt-get install -y libssl-dev libffi-dev python-dev build-essential\necho "deb [arch=amd64] https://packages.microsoft.com/repos/azure-cli/ wheezy main" > /etc/apt/sources.list.d/azure-cli.list\napt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893\napt-get update\napt-get install azure-cli\napt-get install -y apt-transport-https\napt-get update\napt-get install -y sshpass\napt-get install -y wget\napt-get install -y lvm2 xfsprogs sysstat atop\numount -f /mnt\npvcreate -f /dev/sdc\nvgcreate delivery-vg /dev/sdc\nlvcreate -n delivery-lv -l 80%VG delivery-vg\nmkfs.xfs /dev/delivery-vg/delivery-lv\nmkdir -p /var/opt/delivery\nmount /dev/delivery-vg/delivery-lv /var/opt/delivery\nwget  https://packages.chef.io/files/stable/automate/0.8.5/ubuntu/16.04/automate_0.8.5-1_amd64.deb\ndpkg -i automate_0.8.5-1_amd64.deb\naz login --service-principal -u $appID --password $password --tenant $tenantID\naz keyvault secret download --file /etc/delivery/chefautomatedeliveryuser.pem --name chefdeliveryuserkey --vault-name $keyVaultName\ncat > /etc/delivery/command_to_execute <<EOF\nautomate-ctl setup --license AUTOMATE_LICENSE --key < AUTOMATE_CHEF_USER_KEY > --server-url https:// < CHEF_SERVER_FQDN/organizations >/chef-automate-org --fqdn < AUTOMATE_SERVER_FQDN >  --enterprise < ENTERPRISE_NAME >\nEOF\n'
var scripts = {
  chef_backend_install_script_leader: '${chef_backend_install_script_base}chef-backend-ctl create-cluster --accept-license --yes --quiet --verbose\n'
  chef_backend_install_script_follower: '${chef_backend_install_script_base}chef-backend-ctl join-cluster 10.0.1.4 -s /etc/chef-backend/chef-backend-secrets.json --accept-license --yes --quiet --verbose\n'
  chef_frontend_install_script_fe0: '${chef_frontend_install_script_base}chef-server-ctl reconfigure --accept-license\nsudo chef-manage-ctl reconfigure --accept-license\necho \'ENABLED="true"\' > /etc/default/sysstat\nservice sysstat start\nsleep 5\nchef-server-ctl user-create delivery $firstName $lastName $emailId $password --filename /etc/opscode/chefautomatedeliveryuser.pem\nsleep 5\nsudo chef-server-ctl org-create $organizationName \'Chef Automate Org\' --file /etc/opscode/chef_automate_org-validator.pem -a delivery\nsleep 5\naz login --service-principal -u $appID --password $password --tenant $tenantID\nif [ `echo $?` -eq 0 ]\nthen\necho "uploading the secret files to keyvault"\naz keyvault secret set --name chefsecrets --vault-name $keyVaultName --file /etc/opscode/private-chef-secrets.json\naz keyvault secret set --name chefdeliveryuserkey --vault-name $keyVaultName --file /etc/opscode/chefautomatedeliveryuser.pem\naz keyvault secret set --name chefdeliveryuserpassword --vault-name $keyVaultName --value $password\nelse\necho "Authentication to Azure keyvault failed"\nfi\n'
  chef_frontend_install_script_fe: '${chef_frontend_install_script_base}az login --service-principal -u $appID --password $password --tenant $tenantID\naz keyvault secret download --file /etc/opscode/private-chef-secrets.json --name chefsecrets --vault-name $keyVaultName\nmkdir -p /var/opt/opscode/upgrades/\ntouch /var/opt/opscode/bootstrapped\nchef-server-ctl reconfigure --accept-license\nsudo chef-manage-ctl reconfigure --accept-license\necho \'ENABLED="true"\' > /etc/default/sysstat\nservice sysstat start\n'
}
var customData = {
  fe0Customdata: base64('#cloud-config\n\nwrite_files:\n-   encoding: b64\n    content: ${base64(scripts.chef_frontend_install_script_fe0)}\n    path: /etc/opscode/chef-frontend-install.sh\n    permissions: 0700\n')
  feCustomData: base64('#cloud-config\n\nwrite_files:\n-   encoding: b64\n    content: ${base64(scripts.chef_frontend_install_script_fe)}\n    path: /etc/opscode/chef-frontend-install.sh\n    permissions: 0700\n')
  leaderCustomData: base64('#cloud-config\n\nwrite_files:\n-   encoding: b64\n    content: ${base64(scripts.chef_backend_install_script_leader)}\n    path: /etc/chef-backend/chef-backend-install.sh\n    permissions: 0700\n')
  followerCustomData: base64('#cloud-config\n\nwrite_files:\n-   encoding: b64\n    content: ${base64(scripts.chef_backend_install_script_follower)}\n    path: /etc/chef-backend/chef-backend-install.sh\n    permissions: 0700\n')
  automateCustomData: base64('#cloud-config\n\nwrite_files:\n-   encoding: b64\n    content: ${base64(chef_automate_install_script_base)}\n    path: /etc/delivery/chef-automate-install.sh\n    permissions: 0700\n')
}
var baseUrl = 'https://raw.githubusercontent.com/azure/azure-quickstart-templates/master/chef-automate-ha/'
var keyvaultResourcesURL = '${baseUrl}nested/keyvaultResource.json'
var managedDisksResourcesURL = '${baseUrl}nested/managedDisksResource.json'
var diagnosticStorageAccountResourcesURL = '${baseUrl}nested/diagnosticStorageAccountResource.json'
var availabilitySetSResourcesURL = '${baseUrl}nested/availabilitySetsResource.json'
var publicIPAddressesResourcesURL = '${baseUrl}nested/publicIPAddressResource.json'
var networkSecurityGroupsResourcesURL = '${baseUrl}nested/networkSecurityGroupsResource.json'
var virtualNetworksResourcesURL = '${baseUrl}nested/virtualNetworksResource.json'
var fe_loadBalancersResourcesURL = '${baseUrl}nested/loadBalancersResource.json'
var fe_networkInterfacesResourcesURL = '${baseUrl}nested/fe-networkInterfacesResource.json'
var be_networkInterfacesResourcesURL = '${baseUrl}nested/be-networkInterfacesResource.json'
var chefAuto_networkInterfacesResourcesURL = '${baseUrl}nested/chefAuto-networkInterfacesResource.json'
var fe_be_VmsWithExtensionsURL = '${baseUrl}nested/fe-be-virtualmachines-with-extensions.json'
var beSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', networkSettings.virtualNetworkName, networkSettings.beSubnetName)
var feSubnetRef = resourceId('Microsoft.Network/virtualNetworks/subnets/', networkSettings.virtualNetworkName, networkSettings.feSubnetName)
var felbPublicIPAddressID = resourceId('Microsoft.Network/publicIPAddresses', networkSettings.felbPublicIPAddressName)
var chefAutoPublicIPAddressID = resourceId('Microsoft.Network/publicIPAddresses', networkSettings.chefAutoPublicIPAddressName)
var prefix = uniqueString(resourceGroup().id)
var provider = toUpper('33194f91-eb5f-4110-827a-e95f640a9e46')
var tags = {
  provider: '18d63047-6cdf-4f34-beed-62f01fc73fc2'
}

module pid_tags_provider './nested_pid_tags_provider.bicep' = {
  name: 'pid-${tags.provider}'
  params: {}
}

module keyvaultResource '?' /*TODO: replace with correct path to [variables('keyvaultResourcesURL')]*/ = {
  name: 'keyvaultResource'
  params: {
    keyvaultSettings: keyvaultSettings
  }
}

module managedDisksResource '?' /*TODO: replace with correct path to [variables('managedDisksResourcesURL')]*/ = {
  name: 'managedDisksResource'
  params: {
    computeSettings: computeSettings
  }
}

module diagnosticStorageAccountsResource '?' /*TODO: replace with correct path to [variables('diagnosticStorageAccountResourcesURL')]*/ = {
  name: 'diagnosticStorageAccountsResource'
  params: {
    storageSettings: storageSettings
  }
}

module availabilitySetsResource '?' /*TODO: replace with correct path to [variables('availabilitySetSResourcesURL')]*/ = {
  name: 'availabilitySetsResource'
  params: {
    computeSettings: computeSettings
  }
}

module publicIPAddressesResource '?' /*TODO: replace with correct path to [variables('publicIPAddressesResourcesURL')]*/ = {
  name: 'publicIPAddressesResource'
  params: {
    networkSettings: networkSettings
  }
}

module networkSecurityGroupsResource '?' /*TODO: replace with correct path to [variables('networkSecurityGroupsResourcesURL')]*/ = {
  name: 'networkSecurityGroupsResource'
  params: {
    networkSettings: networkSettings
  }
}

module virtualNetworksResource '?' /*TODO: replace with correct path to [variables('virtualNetworksResourcesURL')]*/ = {
  name: 'virtualNetworksResource'
  params: {
    networkSettings: networkSettings
  }
  dependsOn: [
    networkSecurityGroupsResource
  ]
}

module fe_loadBalancersResource '?' /*TODO: replace with correct path to [variables('fe-loadBalancersResourcesURL')]*/ = {
  name: 'fe-loadBalancersResource'
  params: {
    networkSettings: networkSettings
    felbPublicIPAddressID: felbPublicIPAddressID
  }
  dependsOn: [
    publicIPAddressesResource
  ]
}

module fe_networkInterfacesResource '?' /*TODO: replace with correct path to [variables('fe-networkInterfacesResourcesURL')]*/ = {
  name: 'fe-networkInterfacesResource'
  params: {
    networkSettings: networkSettings
    feSubnetRef: feSubnetRef
  }
  dependsOn: [
    fe_loadBalancersResource
    virtualNetworksResource
    networkSecurityGroupsResource
  ]
}

module be_networkInterfacesResource '?' /*TODO: replace with correct path to [variables('be-networkInterfacesResourcesURL')]*/ = {
  name: 'be-networkInterfacesResource'
  params: {
    networkSettings: networkSettings
    beSubnetRef: beSubnetRef
  }
  dependsOn: [
    virtualNetworksResource
    networkSecurityGroupsResource
  ]
}

module chefAuto_networkInterfacesResource '?' /*TODO: replace with correct path to [variables('chefAuto-networkInterfacesResourcesURL')]*/ = {
  name: 'chefAuto-networkInterfacesResource'
  params: {
    networkSettings: networkSettings
    feSubnetRef: feSubnetRef
    chefAutoPublicIPAddressID: chefAutoPublicIPAddressID
  }
  dependsOn: [
    publicIPAddressesResource
    virtualNetworksResource
    networkSecurityGroupsResource
  ]
}

module fe_be_virtualMachinesWithExtensions '?' /*TODO: replace with correct path to [variables('fe-be-VmsWithExtensionsURL')]*/ = {
  name: 'fe-be-virtualMachinesWithExtensions'
  params: {
    computeSettings: computeSettings
    networkSettings: networkSettings
    keyvaultSettings: keyvaultSettings
  }
  dependsOn: [
    managedDisksResource
    diagnosticStorageAccountsResource
    availabilitySetsResource
    fe_networkInterfacesResource
    be_networkInterfacesResource
    chefAuto_networkInterfacesResource
    keyvaultResource
  ]
}

output adminusername string = computeSettings.adminUsername
output chef_server_url string = 'https://${reference('publicIPAddressesResource').outputs.chefServerfqdn.value}'
output chef_server_fqdn string = reference('publicIPAddressesResource').outputs.chefServerfqdn.value
output keyvaultName string = keyvaultSettings.keyVaultName
output chef_server_webLogin_userName string = computeSettings.chefServerUserName
output chef_server_webLogin_password string = 'The chef-server-weblogin-password stored in the keyvault,you can retrieve it using azure CLI 2.0 [az keyvault secret show --name chefdeliveryuserpassword --vault-name < keyvaultname >]'
output chef_automate_url string = 'https://${reference('publicIPAddressesResource').outputs.chefAutomatefqdn.value}'
output chef_automate_fqdn string = reference('publicIPAddressesResource').outputs.chefAutomatefqdn.value