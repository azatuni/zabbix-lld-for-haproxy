#!/bin/bash
#Version: 1.0
#Author: Areg Hakobyan
#Purpose: Zabbix LLD for haproxy
#Date: 28.11.2016
HAPROXYCONF=/etc/haproxy/haproxy.cfg
STATSINSTANCES="`grep -o 'haproxy-stats-process-[0-9]\{1,3\}' $HAPROXYCONF`"
CURINSTANCE="haproxy-stats-process-$2"
BINDPROCESS=`sed -n /$CURINSTANCE/,/^$/p $HAPROXYCONF|grep bind-process|awk '{print $2}'`
BINDSOCKET=`sed -n /$CURINSTANCE/,/^$/p $HAPROXYCONF|grep bind\ |awk '{print $2}'`
CREDENTIALS=`sed -n /$CURINSTANCE/,/^$/p $HAPROXYCONF|grep auth| awk '{print $3}'`

function get-bind-proc ()
{
echo '{'
echo -e '\t"data":['
for stats in $STATSINSTANCES
do                                                                                                                                                                                           
        if echo $STATSINSTANCES | grep -vq $stats$                                                                                                                                           
                then ENDLINE=','                                                                                                                                                             
                else ENDLINE=""                                                                                                                                                              
        fi                                                                                                                                                                                   
        BINDPROCESS=`sed -n /$stats/,/^$/p $HAPROXYCONF|grep -m 1 bind-process|awk '{print $2}'`                                                                                                  
        echo -e '\t\t{"{#BINDPROC}":' \"$BINDPROCESS\"'}'$ENDLINE                                                                                                                            
                                                                                                                                                                                             
done                                                                                                                                                                                         
echo -e '\t]'                                                                                                                                                                                
echo '}'
}

function get-haproxy-current-connections ()
{
curl -s -u $CREDENTIALS http://$BINDSOCKET/ | grep current\ conns| awk -F';' '{print $1}'| awk '{print $4}'
}

function get-haproxy-connection-rate ()
{
curl -s -u $CREDENTIALS http://$BINDSOCKET/ |grep conn\ rate|awk -F';' '{print $3}'| awk '{print $4}'| sed 's/\/sec<br>//'
}

function get-haproxy-idle-proc ()
{
curl -s -u $CREDENTIALS http://$BINDSOCKET/ |grep idle | awk '{print $6}'
}


function get-haproxy-maximum-connection ()
{
curl -s -u $CREDENTIALS http://$BINDSOCKET/ |grep maxconn| awk '{print $8}'| sed 's/;//'
}

function echo-help () 
{
echo -e "Usage:\t$0 '[--curconn|--connrate|--idleproc|--maxconn]' bindprocessnumber"
}


if      [ $# == 0 ]
                then    get-bind-proc
elif    [ $# == 2 ]
                then    if      [ "$1" == "--curconn" ]
                                        then    get-haproxy-current-connections
                        elif    [ "$1" == "--connrate" ]
                                        then    get-haproxy-connection-rate
                        elif    [ "$1" == "--idleproc" ]
                                        then    get-haproxy-idle-proc
                        elif    [ "$1" == "--maxconn" ]
                                        then    get-haproxy-maximum-connection
                        else    echo-help
                        fi
else    echo-help
fi
