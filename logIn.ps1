# for recording login events

# collect info
$hash = @{
    "event"      = "login"
    "hostname"   = $env:computername
    "ipaddress"  = ((get-netipaddress).ipaddress -match '^172.*'|out-string).trim() # only collect from net adapter with local IP
    "macaddress" = (get-netadapter|where ifindex -match (get-netipaddress|where ipaddress -match '^172.*').interfaceindex).macaddress # get MAC from adapter with local address
    "login"      = $env:username
    "datetime"   = (get-date|out-string).trim()
}

ni ($ccsv = "\\wsus\lists$\computers\$($hash.hostname).csv") -ea 0 # create csv for computer if doesn't exist
ni ($ucsv = "\\wsus\lists$\users\$($hash.login).csv") -ea 0 # create csv for user if doesn't exist

# machine log

$addm = import-csv $ccsv # import for manipulation

# group policy loop back logs twice, ignores last entry if within 10 seconds
if (!$addm -or (get-date) -ge ([datetime]($addm|select -f 1).datetime).addseconds(10)) {

    $newrow = new-object psobject -property $hash # create object for adding to csv
    export-csv $ccsv -inputobject $newrow -append -force -notype # append to end of file

    # sort by datetime descending to keep newest events at top
    $sort = import-csv $ccsv|select event, hostname, ipaddress, macaddress, login, datetime -unique -excludeproperty pscomputername, psshowcomputername, pssourcejobinstanceid|sort datetime -des

    $sort|export-csv $ccsv -notype # export to csv
}

# user log

$addu = import-csv $ucsv # import for manipulation

# group policy loop back logs twice, ignores last entry if within 10 seconds
if (!$addu -or (get-date) -ge ([datetime]($addm|select -f 1).datetime).addseconds(10)) {

    $newrow = new-object psobject -property $hash # create object for adding to csv
    export-csv $ucsv -inputobject $newrow -append -force -notype # append to end of file

    # sort by datetime descending to keep newest events at top
    $sort = import-csv $ucsv|select event, hostname, ipaddress, macaddress, login, datetime -unique -excludeproperty pscomputername, psshowcomputername, pssourcejobinstanceid|sort datetime -des

    $sort|export-csv $ucsv -notype # export to csv

}