param templateUri string
param location string
param Backend_VM_Template string
param Backend_VM_Name_Base string
param Backend_VM_Count int
param Proximity_PlacementGroup_Name string
param Admin_User_for_VM_Access string
param ssh_Key_for_VM_Access string
param Virtual_Network_Name string
param storageProfileAdvanced object
param osProfile object
param ostag string
param postInstallActions object
param availabilityset_id_or_empty string
param appgatewaybackend_id_or_empty string

module ParameterizedBackendVM '?' /*TODO: replace with correct path to [parameters('templateUri')]*/ = [for i in range(0, Backend_VM_Count): {
  name: 'ParameterizedBackendVM-${i}'
  params: {
    location: location
    vm_name: '${Backend_VM_Name_Base}-${i}'
    vm_size: storageProfileAdvanced[Backend_VM_Template].vmsize
    datadisk_size: storageProfileAdvanced[Backend_VM_Template].disksize
    datadisk_count: storageProfileAdvanced[Backend_VM_Template].diskcount
    proximity_group_name: Proximity_PlacementGroup_Name
    admin_user: Admin_User_for_VM_Access
    ssh_pub_key: ssh_Key_for_VM_Access
    vnet_name: Virtual_Network_Name
    vnet_subnet_name: 'backendSubnet'
    os_image: osProfile[ostag].image
    post_install_actions: postInstallActions.backend
    enable_enhanced_networking: true
    publicip_id_or_empty: ''
    appgatewaybackend_id_or_empty: appgatewaybackend_id_or_empty
    availabilityset_id_or_empty: availabilityset_id_or_empty
  }
}]

output backendIp array = [for i in range(0, Backend_VM_Count): reference(resourceId('Microsoft.Resources/deployments', 'ParameterizedBackendVM-${i}')).outputs.privateIp.value]