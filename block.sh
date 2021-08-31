#!/bin/sh

ETC_FILE_PATH='/etc/hosts'

my_ping_function()
{
    ERROR=$(ping -c 1 -W 1 "$1" 2>&1 > /dev/null)
    echo $ERROR
}

get_saved_hosts()
{
    filename="saved_hosts.txt";
    
    if [ -f "$filename" ]; then
        rm "$filename"
    fi
    
    echo '' >> "$filename"
    while read -r line
    do
        echo "$("wc -w <<< '$line'")";
        if [[ $line == 0* ]] || [ $("wc -w <<< '$line'") -lt 2 ]
        then
            echo $line >> $filename
        fi
    done < "$ETC_FILE_PATH"

    echo $filename
}
get_dead_hosts()
{
    filename="dead_hosts.txt";
    
    if [ ! -f "$filename" ]; then
        echo '' >> $filename
    fi
    
    echo $filename
}
download_hosts()
{
    source='https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts';
    
    filename=$(basename "$source");
    
    if [ -f "$filename" ]; then
        rm "$filename"
    fi
    wget "$source"
    
    echo "$filename" 
}

clear_saved_hosts_from_first_file()
{
    filename="$3";
    if [ -f "$filename" ] && $4; then
        rm "$filename"
    fi
    echo "$(awk 'FNR==NR {hash[$0]; next} !($0 in hash)' $1 $2)" > $filename
    echo "$filename"
}

while getopts 's' flag; do
  case "${flag}" in
    s)skip_pings='true';;
    *);;
  esac
done

saved_hosts="$(get_saved_hosts)";
dowloaded_hosts="$(download_hosts)";
dead_hosts="$(get_dead_hosts)";

new_hosts="$(clear_saved_hosts_from_first_file $saved_hosts  $dowloaded_hosts "new_hosts.txt" true)";
filtered_hosts="$(clear_saved_hosts_from_first_file $dead_hosts $new_hosts "filtered_hosts.txt" false)";

number_of_lines="$(wc -l "$filtered_hosts" | awk '{ print $1 }')" ;

i=0;
while read -r line
do
    ((i=i+1))
    address="${line##* }"
    result= [ "$skip_pings" == 'true' ] || [ -z "$(my_ping_function $address)" ];
    printf "\r                                                                                                                        \r";
    printf "#$i/$number_of_lines\t $address\t\t";
    if $result
    then
        printf "is Blocked"
        echo $line >> "$ETC_FILE_PATH"
    else
        printf "is dead"
        echo $line >> $dead_hosts
    fi
done < "$filtered_hosts"

# rm "$filtered_hosts"
# rm "$new_hosts"
# rm "$saved_hosts"
# rm "$dowloaded_hosts"
