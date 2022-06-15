#!/bin/bash
####This is a template of a report to submit to a customer about system usage around the time they specify for an unwanted event
header(){
	####Provides basic system information
	echo Hostname
	cat hostname
	echo
	echo redhat-release:
	cat etc/redhat-release
	echo
	echo Date:
	cat date
	echo
	echo Uptime:
	cat uptime
	echo
	#echo '$ grep RESTART sar* var/log/sa/sar*'
	#grep RESTART sar* var/log/sa/sar*
	echo DMI:
	grep -A 2 'System Information' dmidecode
	echo
	echo CPU Count:
	grep '^CPU(s)' sos_commands/processor/lscpu
	echo
	echo "DO NOT PASTE! Checking to ensure this is our kernel"
	grep -i build var/log/dmesg
	echo
}
kdump(){
    # Kdump checking script by Steve Barcomb (sbarcomb@redhat.com)
    #
    # 04-12-2018 Added a check to for a missing crashkernel reservation so it does not report a syntax error
    # 04-11-2018 This version will now check for systemd vs sysvinit scripts
    # It also will calculate the size of the crash kernel reservation if the sosreport captures /proc/iomem
        ####Section checks the version of kdump or kexec-tools installed
    echo Kdump version:
    echo -------------
    echo $ grep kexec installed-rpms
    grep kexec installed-rpms
    echo
    echo
        ####Check to see if the service is running or enabled
    echo Checking to see if the kdump service is running:
    echo -----------------------------------------------

    if [ ! -f sos_commands/systemd/systemctl_status_--all ]
    then
        echo $ grep kdump chkconfig
        grep kdump chkconfig

    else
        grep kdump ./sos_commands/systemd/systemctl_status_--all
    fi
        ####Display the kdump configuration
    echo
    echo
    echo Printing /etc/kdump.conf:
    echo ------------------------
    echo '$ grep -v ^# etc/kdump.conf | grep -v ^$'
    grep -v ^# etc/kdump.conf | grep -v ^$
    echo
    echo

    if [ ! -f proc/iomem ]
    then
        echo Crashkernel reservation from /proc/cmdline:
        echo -------------------------------------------
        cat proc/cmdline
        echo
        echo
    else
        BIGGER=$(grep -i crash proc/iomem | awk -F '-' '{print $2}' | sed 's/\ \:\ Crash\ kernel//g'| tr /a-z/ /A-Z/)
        SMALLER=$(grep -i crash proc/iomem | awk -F '-' '{print $1}' | sed 's/\ //g'| tr /a-z/ /A-Z/)
        echo Crashkernel reservation:
        echo ------------------------


        if [ -z "$BIGGER" ]
        then
            echo Crashkernel reservation not set!
            echo
            echo
        else
            SIZE=$(echo "ibase=16;$BIGGER - $SMALLER"|bc)
            VALUE=$(echo $SIZE/1024/1024|bc)
            echo The crashkernel value from /proc/iomem is $VALUE MiB
            echo
            echo
        fi
    fi

    echo Panic tunables:
    echo ---------------
    echo $ grep panic ./sos_commands/kernel/sysctl_-a
    grep panic ./sos_commands/kernel/sysctl_-a
    echo
    echo
    echo Checking for sysrq keybinding:
    echo ------------------------------
    echo $ grep sysrq ./sos_commands/kernel/sysctl_-a
    grep sysrq ./sos_commands/kernel/sysctl_-a
    echo
    echo
    echo Generating a blacklist if needed, this will probably not be complete:
    echo ---------------------------------------------------------------------
    grep -e vx -e emc -e qla -e lpfc -e ocfs -e ora lsmod| grep -v fdd | grep -v usb_storage | grep -v scsi_mod | awk '{printf("%s ", $1)}END{printf("\n")}'
    echo
    echo

    if grep --quiet cciss lsmod;
    then
       echo CCISS firmware revision, please ensure it is greater than 5.6 or https://access.redhat.com/solutions/65848
       grep -i version proc/driver/cciss/cciss0

     else
        echo 'no CCISS device found'
      fi
    echo
    echo
}
####################AM/PM Reporting###########################################
report() {
    ####Everything in this function is self explanatory in the titles
    printf "%s\n" "    $(head -n 1 $file)"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Load Average")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/ldavg/,/^$/' $file | head -n 1)"
    awk '/ldavg/,/^$/' $file | grep -B 5 $timesearch | grep $tz | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "CPU Usage Report")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/idle/,/^$/' $file | grep -e idle -e all | head -n 1)"
    awk '/idle/,/^$/' $file | grep -e idle -e all | grep -B 5 $timesearch | grep $tz | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Memory Usage Report")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/kbmem/,/^$/' $file | head -n 1)"
    awk '/kbmem/,/^$/' $file | grep -B 5 $timesearch | grep $tz | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Swap Usage Report")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/pswp/,/^$/' $file | head -n 1)"
    awk '/pswp/,/^$/' $file | grep -B 5 $timesearch | grep $tz | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Disk Usage")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/await/,/^$/' $file | head -n 1)"
    awk '/await/,/^$/' $file | grep $timesearch | grep $tz | while read line; do printf "%s\n" "    $line"; done
    echo 
}
####################Military Time Reporting ##################################
report2() {
####Everything in this function is self explanatory in the titles
    printf "%s\n" "    $(head -n 1 $file)"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Load Average")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/ldavg/,/^$/' $file | head -n 1)"    
    awk '/ldavg/,/^$/' $file | grep -B 5 $timesearch | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "CPU Usage Report")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/idle/,/^$/' $file | grep -e idle -e all | head -n 1)"    
    awk '/idle/,/^$/' $file | grep -e idle -e all | grep -B 5 $timesearch | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Memory Usage Report")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/kbmem/,/^$/' $file | head -n 1)"    
    awk '/kbmem/,/^$/' $file | grep -B 5 $timesearch | while read line; do printf "%s\n" "    $line"; done
    echo
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Swap Usage Report")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/pswp/,/^$/' $file | head -n 1)"    
    awk '/pswp/,/^$/' $file | grep -B 5 $timesearch | while read line; do printf "%s\n" "    $line"; done
    echo ''
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(echo "Disk Usage")"
    printf "%s\n" "    $(echo '================================================================================================')"
    printf "%s\n" "    $(awk '/await/,/^$/' $file | head -n 1)"    
    awk '/await/,/^$/' $file | grep $timesearch | while read line; do printf "%s\n" "    $line"; done
    echo ''

}
####################Oracle tuning check#######################################
oracle(){
    echo 'Oracle tuning guide'
    echo Looking to see what io scheduler we are using and is transparent hugepages are disabled
    echo '$ grep -e elevator -e transparent proc/cmdline'
    grep -e elevator -e transparent proc/cmdline
    echo
    echo
    echo '$ grep -i huge proc/meminfo'
    grep -i huge proc/meminfo
    echo
    echo
    echo '$ cat proc/sys/vm/swappiness'
    echo "$( cat proc/sys/vm/swappiness) <==== we recommend 10"
    echo
    echo '$ cat proc/sys/vm/dirty_ratio'
    echo "$( cat proc/sys/vm/dirty_ratio) <==== we recommend 15"
    echo
    echo '$ cat proc/sys/vm/dirty_background_ratio'
    echo "$( cat proc/sys/vm/dirty_background_ratio) <==== we recommend 3"
    echo
    echo '$cat proc/sys/vm/dirty_writeback_centisecs'
    echo "$( cat proc/sys/vm/dirty_writeback_centisecs) <==== we recommend 100"
    echo
    echo '$ cat proc/sys/vm/dirty_expire_centisecs'
    echo "$( cat proc/sys/vm/dirty_expire_centisecs) <==== we recommend 500"
    echo
    echo
    mem=$(cat free|grep Mem|awk '{print $2}')
    totmem=$(echo "$mem*1024"|bc)
    huge=$(grep Hugepagesize proc/meminfo|awk '{print $2}')
    max=$(echo "$totmem*75/100"|bc)
    all=$(echo "$max/$huge"|bc)
    echo Checking for the shmmax value
    echo "$(grep kernel.shmmax ./sos_commands/kernel/sysctl_-a) <==== should be $max based on the sosreport"
    echo
    echo Checking for the shmmall value
    echo "$(grep kernel.shmall ./sos_commands/kernel/sysctl_-a) <==== should be $all based on the sosreport"
    echo
    echo Checking the shmmni value
    echo "$(grep kernel.shmmni ./sos_commands/kernel/sysctl_-a) <==== should be 4096"
    echo
    echo Checking semaphore minimums
    echo "$(grep kernel.sem ./sos_commands/kernel/sysctl_-a) <==== should be 250 32000 100 128"
    echo
    echo Checking open file descriptors for the Oracle user
    echo "$(grep oracle etc/security/limits.conf | grep hard | grep nofile) <==== should be at least 10000"
    echo
    echo
    echo Checking to see if tuned and ktune are running
    echo '$ grep tune chkconfig'
    grep tune chkconfig
}
####Gather information about the file and time to search
read -e -p "Where is the sar file to read? " file ##File to gather data from
##############################################################################
grep AM $file &> /dev/null ##Determine if it runs on military time or am/pm
##############################################################################
if [[ "$?" = 0 ]]; then ##If it uses AM/PM
    read -p "AM or PM?(in caps)" tz
    if [[ "$tz" = '' ]]; then
    read -p "Are you sure you wish to display both pm and am(y or n)? " ans
    case $ans in
        y) report2 > sar-report
            ;;
        n) read -p "AM or PM?(in caps)" tz
            report
            ;;
    esac
    fi
    read -p "What time do you want to search for(in 10 min increments)? " timesearch ##Time to find inside of file
    report > sar-report.txt ##If you use AM/PM report on it to the file
##############################################################################
else ##If it uses military time
    read -p "What time do you want to search for(in 10 min increments)? " timesearch ##Time to find inside of file
    report2 > sar-report.txt ##If you choice to use military time, report it to the file
fi
################What to do if you forget data in the command##################
if [[ "$file" = '' ]] || [[ "$timesearch" = '' ]]; then
    echo '=================================='
    echo "Usage sar-report <sar file> <time in 10min increments>"
    echo '=================================='
    exit 5
fi
################Finish the report#############################################
#oracle >> sar-report.txt
#echo '===============================================================================================' >> sar-report.txt
#echo '' >> sar-report.txt
#kdump >> sar-report.txt
vim sar-report.txt
