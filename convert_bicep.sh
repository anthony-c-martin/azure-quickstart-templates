#!/bin/bash

bicep_dll='/Users/ant/Code/bicep/src/Bicep.Cli/bin/Debug/net5.0/bicep.dll'
quickstart_folder='/Users/ant/Code/azure-quickstart-templates'
log_file="$quickstart_folder/convert_bicep.txt"

json_files=$(find $quickstart_folder -name "azuredeploy.json")

echo "" > $log_file

for json_file in $json_files
do
    dotnet $bicep_dll decompile $json_file >> $log_file 2>&1
    echo "" >> $log_file
    echo "" >> $log_file
done