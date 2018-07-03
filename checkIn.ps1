# records mac addresses upon computer startup for the purpose of WOL

# collect info
$hash = @{
    "hostname"   = $env:computername
    "ipaddress"  = ((get-netipaddress).ipaddress -match '^172.*'|out-string).trim() # only collect from net adapter with local IP
    "macaddress" = (get-netadapter|where ifindex -match (get-netipaddress|where ipaddress -match '^172.*').interfaceindex).macaddress # get MAC from adapter with local address
    "datetime" = (get-date|out-string).trim()
}

$newRow = new-object psobject -property $hash # convert info for csv
while (!$remove){$remove = import-csv ($csv = "\\wsus\lists$\.master.csv")|where {$_.hostname -ne $hash.hostname}} # import all except $hash to update if IP change
$remove|export-csv $csv -notype # export csv without $hash
export-csv $csv -inputobject $newRow -append -force -notype # append $hash to end
while (!$sort){$sort = import-csv $csv|select hostname, ipaddress, macaddress, datetime -unique -excludeproperty pscomputername, psshowcomputername, pssourcejobinstanceid|sort hostname} # import without extraneous fields and sort
$sort|export-csv $csv -notype # export without extraneous fields