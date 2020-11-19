param clusterName string {
  metadata: {
    description: 'The name of the HDInsight cluster to be created. The cluster name must be globally unique.'
  }
}
param artifactsLocation string {
  metadata: {
    description: 'The base URI where artifacts required by this template are located. When the template is deployed using the accompanying scripts, a private location in the subscription will be used and this value will be automatically generated.'
  }
  default: 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/101-hdinsight-linux-add-edge-node'
}
param artifactsLocationSasToken string {
  metadata: {
    description: 'The sasToken required to access _artifactsLocation.  When the template is deployed using the accompanying scripts, a sasToken will be automatically generated.'
  }
  secure: true
  default: ''
}
param installScriptActionFolder string {
  metadata: {
    description: 'A script action you can run on the empty node to install or configure additiona software.'
  }
  default: 'scripts'
}
param installScriptAction string {
  metadata: {
    description: 'A script action you can run on the empty node to install or configure additiona software.'
  }
  default: 'EmptyNodeSetup.sh'
}

var applicationName = 'new-edgenode'

resource clusterName_applicationName 'Microsoft.HDInsight/clusters/applications@2015-03-01-preview' = {
  name: '${clusterName}/${applicationName}'
  properties: {
    marketplaceIdentifier: 'EmptyNode'
    computeProfile: {
      roles: [
        {
          name: 'edgenode'
          targetInstanceCount: 1
          hardwareProfile: {
            vmSize: 'Standard_D3_v2'
          }
        }
      ]
    }
    installScriptActions: [
      {
        name: 'emptynode-${uniqueString(applicationName)}'
        uri: '${artifactsLocation}/${installScriptActionFolder}/${installScriptAction}${artifactsLocationSasToken}'
        roles: [
          'edgenode'
        ]
      }
    ]
    uninstallScriptActions: []
    httpsEndpoints: []
    applicationType: 'CustomApplication'
  }
  dependsOn: []
}

output application object = clusterName_applicationName.properties