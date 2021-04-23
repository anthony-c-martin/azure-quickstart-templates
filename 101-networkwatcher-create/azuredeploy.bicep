@description('Name of the Network Watcher resource')
param networkWatcherName string = 'NetworkWatcher'

@description('Location for all resources.')
param location string = resourceGroup().location

resource networkWatcherName_resource 'Microsoft.Network/networkWatchers@2020-05-01' = {
  name: networkWatcherName
  location: location
  properties: {}
}