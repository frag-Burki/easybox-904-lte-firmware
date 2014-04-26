#!/bin/sh

DRV_STAT_PATH="/tmp/fs"
DRV_STAT_FILE="${DRV_STAT_PATH}/drvstat"
VOL_INFO_FILE="${DRV_STAT_PATH}/volinfo"

DATA=

cfg_enable=0
cfg_online=0
cfg_account=
cfg_password=
cfg_name= 
cfg_vendor=
cfg_model=
cfg_partition_idx=
cfg_path=
cfg_readonly=0
cfg_devname=
cfg_partition=

CFGIDX1=0
CFGIDX2=0

smb_global_add() {
	local name
	local workgroup
	local description

	name=`umngcli get computerName@samba`
	description=`umngcli get computerDescription@samba`
	workgroup=`umngcli get groupName@samba`

	[ -z "$name" ] && name=samba
	[ -z "$workgroup" ] && workgroup=WORKGROUP
	[ -z "$description" ] && description=samba

	
	sed -i "s/|NAME|/$name/g" /tmp/smb.conf
	sed -i "s/|WORKGROUP|/$workgroup/g" /tmp/smb.conf
	sed -i "s/|DESCRIPTION|/$description/g" /tmp/smb.conf
}

# $1 - shareSecure, $2 - data of "folderX"
#				    $2 - data of "accountX"
smbcfg_data_parse()
{
	if [ -z "$2" ] ; then
		return
	fi

	#share mode
	if [ $1 -eq 1 ]; then
		cfg_enable=`echo "$2"  | cut -d ':' -f 1`
		cfg_name=`echo "$2"  | cut -d ':' -f 2`
		cfg_partition_idx=`echo "$2"  | cut -d ':' -f 3`
		cfg_path=`echo "$2"    | cut -d ':' -f 4`
		cfg_security=`echo "$2" | cut -d ':' -f 5`
		cfg_readpassword=`echo "$2" | cut -d ':' -f 6`	
		cfg_writepassword=`echo "$2" | cut -d ':' -f 7`	
		cfg_partition=`echo "$2" | cut -d ':' -f 8`

		#echo cfg_enable = $cfg_enable> /dev/console
		#echo cfg_name = $cfg_name> /dev/console
		#echo cfg_partition_idx = $cfg_partition_idx> /dev/console
		#echo cfg_path = $cfg_path> /dev/console
		#echo cfg_security= $cfg_security> /dev/console
		#echo cfg_readpassword= $cfg_readpassword> /dev/console
		#echo cfg_writepassword= $cfg_writepassword> /dev/console
		#echo cfg_partition= $cfg_partition> /dev/console
	
	#user mode	
	else
		cfg_enable=`echo "$2"  | cut -d ':' -f 1`
		cfg_online=`echo "$2"  | cut -d ':' -f 2`
		cfg_account=`echo "$2"    | cut -d ':' -f 3`
		cfg_password=`echo "$2" | cut -d ':' -f 4`
		cfg_name=`echo "$2"  | cut -d ':' -f 5`
		cfg_vendor=`echo "$2"  | cut -d ':' -f 6`
		cfg_model=`echo "$2"  | cut -d ':' -f 7`
		cfg_partition_idx=`echo "$2"  | cut -d ':' -f 8`
		cfg_path=`echo "$2"  | cut -d ':' -f 9`
		cfg_readonly=`echo "$2"  | cut -d ':' -f 10`
		cfg_devname=`echo "$2"  | cut -d ':' -f 11`
		cfg_partition=`echo "$2"  | cut -d ':' -f 12`
		
		#echo cfg_enable= $cfg_enable> /dev/console
		#echo cfg_online= $cfg_online> /dev/console
		#echo cfg_account = $cfg_account> /dev/console
		#echo cfg_password = $cfg_password> /dev/console
		#echo cfg_name = $cfg_name> /dev/console
		#echo cfg_vendor= $cfg_vendor> /dev/console
		#echo cfg_model= $cfg_model> /dev/console
		#echo cfg_partition_idx= $cfg_partition_idx> /dev/console
		#echo cfg_path = $cfg_path> /dev/console
		#echo cfg_readonly = $cfg_readonly> /dev/console
		#echo cfg_devname = $cfg_devname> /dev/console
		#echo cfg_partition = $cfg_partition> /dev/console
	fi                     
}

# $1 - mode, $2 - cfg_idx, $3 - share folder ID
#			 $2 - account ID
smbcfg_data_retrieve()
{
	if [ $1 -eq 1 ]; then
		DATA=`ccfg_cli get smb$2_folder$3@samba`
	else
		DATA=`ccfg_cli get smb_account$2@samba`
	fi
	
	if [ -z "$DATA" ]; then
		return
	fi

	smbcfg_data_parse $1 "$DATA"
}

smb_sharemode_add() {	
	local MAX_FOLNUM
	local FOLDER_ID=0
	local CFGID=0
	local CFGONLINE=0
	local dev_id
	local dev_name
	local mount_folder
	local ALLPATH

	echo "smb_sharemode_add" > /dev/console

	MAX_FOLDER_NUM=`ccfg_cli get max_folder_num@samba`

	MAX_CFG_KEEP=`ccfg_cli get max_cfg_keep@samba`

	CFGID=0

	while [ "${CFGID}" -le "${MAX_CFG_KEEP}" ]
	do
		FOLDER_ID=0

		DRV_DATA=`ccfg_cli get smb${CFGID}_drive@samba`
		CFGONLINE=`echo "$DRV_DATA"  | cut -d ':' -f 2`
		CFG_DEVNAME=`echo "$DRV_DATA"  | cut -d ':' -f 6`

		echo DRV_DATA = $DRV_DATA > /dev/console
			
		if [ "${CFGONLINE}" == "1" ]; then
			while [ "${FOLDER_ID}" -lt "${MAX_FOLDER_NUM}" ]
			do
				smbcfg_data_retrieve 1 $CFGID $FOLDER_ID

			dev_id=`ccfg_cli -f "$VOL_INFO_FILE" get ${CFG_DEVNAME}_id@volinfo`
			echo dev_id = $dev_id > /dev/console

			dev_name=`ccfg_cli -f "$VOL_INFO_FILE" get devName@disk${dev_id}_${cfg_partition_idx}`
			echo dev_name = $dev_name > /dev/console

			mount_folder=${dev_name:2}
			echo mount_folder = $mount_folder > /dev/console

			if [ "${cfg_path}" != "/" ]; then
				ALLPATH="/tmp/usb/"${mount_folder}${cfg_path}
			else
				ALLPATH="/tmp/usb/"${mount_folder}
			fi

			echo ALLPATH = $ALLPATH > /dev/console

			if [ -n "$DATA" ] && [ "${cfg_enable}" == "1" ]; then
				echo -e "\n[$cfg_name]\n\tpath = $ALLPATH" >> /tmp/smb.conf
				
#Read Only
				if [ "${cfg_security}" == "1" ]; then				
					echo -e "\twritable = no" >> /tmp/smb.conf
#Full Access
				else
					echo -e "\twritable = yes" >> /tmp/smb.conf
				fi
				
				echo -e "\tguest ok = yes" >> /tmp/smb.conf
				echo -e "\tbrowseable = yes" >> /tmp/smb.conf
				echo -e "\tcreate mask = 0777" >> /tmp/smb.conf
				echo -e "\tdirectory mask = 0777" >> /tmp/smb.conf
			fi

				let FOLDER_ID=$FOLDER_ID+1
			done
		fi
		let CFGID=$CFGID+1
	done
}

smb_usermode_add(){
	local MAX_ACCOUNT_NUM
	local ACCOUNT_ID=0
	local ONLINE=0
	local dev_id
	local dev_name
	local mount_folder
	local ALLPATH

	MAX_ACCOUNT_NUM=`ccfg_cli get max_account_num@samba`
	
	ACCOUNT_ID=0
	while [ "${ACCOUNT_ID}" -lt "${MAX_ACCOUNT_NUM}" ]
	do
		smbcfg_data_retrieve 2 $ACCOUNT_ID

		if [ -n "${DATA}" ] && [ "${cfg_enable}" == "1" ] && [ "${cfg_online}" == "1" ]; then
			dev_id=`ccfg_cli -f "$VOL_INFO_FILE" get ${cfg_devname}_id@volinfo`
			#echo dev_id = $dev_id > /dev/console

			dev_name=`ccfg_cli -f "$VOL_INFO_FILE" get devName@disk${dev_id}_${cfg_partition_idx}`
			#echo dev_name = $dev_name > /dev/console

			mount_folder=${dev_name:2}
			#echo mount_folder = $mount_folder > /dev/console

			ALLPATH="/tmp/usb/"${mount_folder}${cfg_path}
			#echo ALLPATH = $ALLPATH > /dev/console
		
			echo -e "\n[$cfg_name]\n\tpath = $ALLPATH" >> /tmp/smb.conf
			echo -e "\tguest ok = no" >> /tmp/smb.conf
			echo -e "\tvalid users = $cfg_account" >> /tmp/smb.conf
		
			if [ "${cfg_readonly}" == "0" ]; then
				echo -e "\twritable = no" >> /tmp/smb.conf
			else
				echo -e "\twritable = yes" >> /tmp/smb.conf
			fi

			echo -e "\tbrowseable = yes" >> /tmp/smb.conf
			echo -e "\tcreate mask = 0777" >> /tmp/smb.conf
			echo -e "\tdirectory mask = 0777" >> /tmp/smb.conf
		fi
		let ACCOUNT_ID=$ACCOUNT_ID+1
	done
}

#$1 - mode
smb_online_cfg_check(){
	local MODE
	local DRIVE_ID=1
	local ONLINE=0
	local ONLINE1=0
	local VENDOR1
	local MODEL1
	local ONLINE2=0
	local VENDOR2
	local MODEL2
	local MAX_ACCOUNT_NUM=0
	local ACCOUNT_ID=0
	local CFGID=0
	local VENDOR
	local MODEL
	local DRV_DATA

	MODE=`ccfg_cli get mode@samba`
	
	ONLINE1=`ccfg_cli -f "$DRV_STAT_FILE" get online1@drive`
	VENDOR1=`ccfg_cli -f "$DRV_STAT_FILE" get vendor1@drive`
	MODEL1=`ccfg_cli -f "$DRV_STAT_FILE" get model1@drive`
	DEVNAME1=`ccfg_cli -f "$DRV_STAT_FILE" get devname1@drive`

	ONLINE2=`ccfg_cli -f "$DRV_STAT_FILE" get online2@drive`
	VENDOR2=`ccfg_cli -f "$DRV_STAT_FILE" get vendor2@drive`
	MODEL2=`ccfg_cli -f "$DRV_STAT_FILE" get model2@drive`
	DEVNAME2=`ccfg_cli -f "$DRV_STAT_FILE" get devname2@drive`

	#echo $ONLINE1 $VENDOR1 $MODEL1 $DEVNAME1> /dev/console	
	#echo $ONLINE2 $VENDOR2 $MODEL2 $DEVNAME2> /dev/console	

	#share mode
	if [ $MODE -eq 0 ]; then
		#echo "share mode" > /dev/console		

		MAX_CFG_KEEP=`ccfg_cli get max_cfg_keep@samba`

		while [ "${CFGID}" -le "${MAX_CFG_KEEP}" ]
		do
			ONLINE=0

			DRV_DATA=`ccfg_cli get smb${CFGID}_drive@samba`

			#echo DRV_DATA = $DRV_DATA > /dev/console
			VAL=`echo "$DRV_DATA"  | cut -d ':' -f 1`
			CFGONLINE=`echo "$DRV_DATA"  | cut -d ':' -f 2`
			SEQ=`echo "$DRV_DATA"  | cut -d ':' -f 3`
			VENDOR=`echo "$DRV_DATA"  | cut -d ':' -f 4`
			MODEL=`echo "$DRV_DATA"  | cut -d ':' -f 5`

			if [ -n "$DRV_DATA" ]; then
				if [ "${ONLINE1}" == "1" ] && [ "${VENDOR}" == "${VENDOR1}" ] && [ "${MODEL}" == "${MODEL1}" ] ; then
					#echo DEVNAME1 = $DEVNAME1 > /dev/console
					ccfg_cli set smb${CFGID}_drive@samba="${VAL}:${ONLINE1}:${SEQ}:${VENDOR}:${MODEL}:${DEVNAME1}"
				elif [ "${ONLINE2}" == "1" ] && [ "${VENDOR}" == "${VENDOR2}" ] && [ "${MODEL}" == "${MODEL2}" ]; then
					#echo DEVNAME2 = $DEVNAME2 > /dev/console
					ccfg_cli set smb${CFGID}_drive@samba="${VAL}:${ONLINE2}:${SEQ}:${VENDOR}:${MODEL}:${DEVNAME2}"
				else
					ccfg_cli set smb${CFGID}_drive@samba="${VAL}:0:${SEQ}:${VENDOR}:${MODEL}:"
				fi
			fi
								
			let CFGID=$CFGID+1
		done

	#user mode
	else
		#echo "user mode" > /dev/console
	
		MAX_ACCOUNT_NUM=`ccfg_cli get max_account_num@samba`

		while [ "${ACCOUNT_ID}" -lt "${MAX_ACCOUNT_NUM}" ]
		do
			ONLINE=0

			smbcfg_data_retrieve 2 $ACCOUNT_ID
			
			if [ -n "$DATA" ]; then
				if [ "${ONLINE1}" == "1" ] && [ "${cfg_vendor}" == "${VENDOR1}" ] && [ "${cfg_model}" == "${MODEL1}" ]; then
					ONLINE=1
					cfg_devname=$DEVNAME1
					ccfg_cli set smb_account$ACCOUNT_ID@samba="${cfg_enable}:${ONLINE}:${cfg_account}:${cfg_password}:${cfg_name}:${cfg_vendor}:${cfg_model}:${cfg_partition_idx}:${cfg_path}:${cfg_readonly}:${cfg_devname}:${cfg_partition}"
				elif [ "${ONLINE2}" == "1" ] && [ "${cfg_vendor}" == "${VENDOR2}" ] && [ "${cfg_model}" == "${MODEL2}" ]; then
					ONLINE=1
					cfg_devname=$DEVNAME2
					ccfg_cli set smb_account$ACCOUNT_ID@samba="${cfg_enable}:${ONLINE}:${cfg_account}:${cfg_password}:${cfg_name}:${cfg_vendor}:${cfg_model}:${cfg_partition_idx}:${cfg_path}:${cfg_readonly}:${cfg_devname}:${cfg_partition}"
				fi		
			fi

			let ACCOUNT_ID=$ACCOUNT_ID+1
			done	
	fi
}


#$1 - drive_cfg_id (for share mode)
#arrange config after delete a account
smb_cfg_arrange(){
	local MAX_ACCOUNT_NUM
	local MAX_FOLDER_NUM
	local ACCOUNT_ID=0
	local ACCOUNT_DATA
	local ACCOUNT_DATA_NEXT
	local ACCOUNT_ID_NEXT
	local FOLDER_ID=0
	local FOLDER_DATA
	local FOLDER_DATA_NEXT
	local FOLDER_ID_NEXT
	
	local MODE

	MODE=`ccfg_cli get mode@samba`
	
	#echo driveID = $1 > /dev/console 
	#echo in cfg_arrange!!!!! > /dev/console

	#share mode
	if [ $MODE -eq 0 ]; then
		MAX_FOLDER_NUM=`ccfg_cli get max_folder_num@samba`

		FOLDER_ID=0

		while [ "${FOLDER_ID}" -lt "${MAX_FOLDER_NUM}" ]
		do
			
			FOLDER_DATA=`ccfg_cli get smb${1}_folder${FOLDER_ID}@samba`

			#echo FOLDER_DATA = $FOLDER_DATA >/dev/console

			let FOLDER_ID_NEXT=$FOLDER_ID+1

			if [ $FOLDER_ID_NEXT -ge 8 ]; then
				return
			fi

			FOLDER_DATA_NEXT=`ccfg_cli get smb${1}_folder${FOLDER_ID_NEXT}@samba`

			if [ -z "$FOLDER_DATA" ]; then
				ccfg_cli set smb${1}_folder${FOLDER_ID}@samba="$FOLDER_DATA_NEXT"
				ccfg_cli set smb${1}_folder${FOLDER_ID_NEXT}@samba=
			fi
			let FOLDER_ID=$FOLDER_ID+1
		done
	
	#user mode
	else
		MAX_ACCOUNT_NUM=`ccfg_cli get max_account_num@samba`

		ACCOUNT_ID=0

		while [ "${ACCOUNT_ID}" -lt "${MAX_ACCOUNT_NUM}" ]
		do
			ACCOUNT_DATA=`ccfg_cli get smb_account$ACCOUNT_ID@samba`

			let ACCOUNT_ID_NEXT=$ACCOUNT_ID+1

			if [ $ACCOUNT_ID_NEXT -ge 4 ]; then
				return
			fi

			ACCOUNT_DATA_NEXT=`ccfg_cli get smb_account$ACCOUNT_ID_NEXT@samba`

			if [ -z "$ACCOUNT_DATA" ]; then
				ccfg_cli set smb_account$ACCOUNT_ID@samba="$ACCOUNT_DATA_NEXT"
				ccfg_cli set smb_account$ACCOUNT_ID_NEXT@samba=
			fi
			let ACCOUNT_ID=$ACCOUNT_ID+1
		done
	fi
}

#only change [gloabol]
smb_global_cfg_set(){
	smb_global_add
}

#change [user1] [user2]...
smb_user_cfg_set(){
	cp /etc/samba/smb.conf.template /tmp/smb.conf

	smb_global_add

	mode=`ccfg_cli get mode@samba`
	#share mode
	if [ "$mode" == "0" -o  -z "$mode" ] ; then
		sed -i "s/|SHARE|/share/g" /tmp/smb.conf
		
		smb_online_cfg_check 

		smb_sharemode_add 
	#user mode
	else
		sed -i "s/|SHARE|/user/g" /tmp/smb.conf
		
		smb_online_cfg_check 

		smb_usermode_add 
	fi
}

case "$1" in
	"smb_global_cfg_set")		smb_global_cfg_set;;
	"smb_user_cfg_set")		    smb_user_cfg_set;;
	"smb_cfg_arrange")			smb_cfg_arrange $2;;	
	"smb_online_cfg_check")		smb_online_cfg_check;;
	"smb_sharemode_add")		smb_sharemode_add;;
	"smb_usermode_add")			smb_usermode_add;;
	*)
				echo $0 "smb_global_cfg_set  - Samba global config set function"
				echo $0 "smb_user_cfg_set - Samba user config arrange function"
				echo $0	"smb_cfg_arrange - Arrange samba account config after delete a account"
				echo $0 "smb_online_cfg_check  - Check every samba config is onlining or not"
				;;
esac