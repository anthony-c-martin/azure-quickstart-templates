param networkWatcherName string {
  metadata: {
    description: 'Name of the Network Watcher resource'
  }
  default: 'NetworkWatcher'
}
param location string {
  metadata: {
    description: 'Location for all resources.'
  }
  default: resourceGroup().location
}

resource networkWatcherName_resource 'Microsoft.Network/networkWatchers@2020-05-01' = {
  name: networkWatcherName
  location: location
  properties: {}
}