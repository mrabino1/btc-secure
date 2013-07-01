#!/bin/bash

## USAGE: ./bts-secure.sh bulk.txt thresholdofshares numberofshares

## presently shortened at: http://goo.gl/HT72i
## presently at: https://dl.dropboxusercontent.com/s/dp9p1j22xr3xhem/btc-secure.sh

## Written by mrabino1@gmail.com
## BTC Donation appreciated but not required   1EVmqkggJxX3pHo1hzfW9nMcSDeFZMoruV

## Running Ubuntu: sudo apt-get install ssss curl bc openssl
## Goto: http://www.bitaddress.org and download the github zip
## which should be located at: https://github.com/pointbiz/bitaddress.org
## Remove the internet access completely for sanity
## View the bitaddress.html file in an ubuntu jar environment and request 1300 bulk addresses and store as bulk.txt
## When complete reboot machine without internet so nothing could have been externally stored

## Last updated: 25 June 2013
## Update: Included some YES confirmation requirements
## Update: Included clean-up code to remove excess directories
## Update: Ubuntu apt-get packages reference
## Update: Checking to see if bulk.txt is there and if threshold of shares is lower than number of shares
## Update: Adding option of including publickeyindex and encoded passphrase
## Update: Adding option of which Shares go in which vault
## Update: Adding Phonetic Structuring and vault export filtering
## Phonetic Alphabet (NATO): Alfa Bravo Charlie Delta Echo Foxtrot Golf Hotel India Juliett Kilo Lima Mike November Oscar Papa Quebec Romeo Sierra Tango Uniform Victor Whiskey Xray Yankee Zulu

clear
export YYYYMMDD=`date +%Y%m%d`
export YYYYMMDDMMSS=`date +%Y%m%d%H%M%S`
printme="PRINT"
DELTA=1
export BULKSIZE=`cat $1 | wc -l`
mkdir ${YYYYMMDDMMSS}

> ${YYYYMMDDMMSS}/alphabet
for i in Alfa Bravo Charlie Delta Echo Foxtrot Golf Hotel India Juliett Kilo Lima Mike November Oscar Papa Quebec Romeo Sierra Tango Uniform Victor Whiskey Xray Yankee Zulu
do
echo $i >> ${YYYYMMDDMMSS}/alphabet
clear
done

awk 'BEGIN{count=1}{if($0~/^$/){print}else{print count,$0;count++}}' ${YYYYMMDDMMSS}/alphabet > ${YYYYMMDDMMSS}/alphanumber

if [ "$1" = "" ] || [ "$2" = "" ] || [ "$3" = "" ]
then
echo "ERROR. Please re-run with the correct syntax."
echo ""
echo "USAGE: ./bts-secure.sh bulk.txt thresholdofshares numberofshares"
echo ""
exit 0 
fi

if [ $2 -eq $3 ] || [ $2 -gt $3 ]
then
echo "Threshold of shares must be lower than number of shares. Please re-run with the correct syntax."
echo ""
echo "USAGE: ./bts-secure.sh bulk.txt thresholdofshares numberofshares"
echo ""
exit 0 
fi

# clear
echo "BITCOIN bulk output encoder using OPENSSL and AES 256 CBC encryption"
echo "Your bulk file contains $BULKSIZE line entries."
echo ""
echo "Enter the Public Key Index Header (e.g. FirstNameLastName)"
echo ""
read INDEX
echo ""
echo "Enter your personal (not-shared) memorable passphrase."
echo "NOTE: This will be stored as a file; however, as this should ONLY be run in a JAR environment, it shouldn't matter."
echo ""
read PASSWORD
clear
echo "Please re-enter your password for confirmation"
read PASSWORDCONFIRM

if [ "$PASSWORD" != "$PASSWORDCONFIRM" ] 
then
clear
echo "ERROR. Passwords do not match. Please re-run script."
exit 0 
fi
clear

echo "Please advise how many blocks of 50 you would like. Please enter the number next to the corresponding Alphabet"
echo "Default is 1"
cat ${YYYYMMDDMMSS}/alphanumber
echo ""
read complexity
if [ "$complexity" == "" ]
then
complexity=1
fi


clear
echo "Processing... Be patient. Sometimes SSSS take a while per iteration for an unknown reason."
header=${YYYYMMDD}_${INDEX}
# mv $1 ${YYYYMMDDMMSS}/bulk_${header}.txt
# to be updated on production
cp $1 ${YYYYMMDDMMSS}/bulk_${header}.txt
cd ${YYYYMMDDMMSS}

for i in $(cat alphabet | head -n $complexity) 
do
mkdir $i
cat bulk_${header}.txt | tail -n +${DELTA} | head -n 50 > $i/bulk_${header}.txt
export DELTA=`echo "scale=0; $DELTA+50" | bc -l`
cd $i
## Next lets create a 48 char random passphrase
openssl rand 48 -base64 > actualpassphrase_${header}.txt

# This will remove the quotes and just print the index with the public key and remove the private key
cat bulk_${header}.txt  | awk -F, '{print $1","$2}' | tr -d '"' | sed 's/.*/'$header',&/' > publickeyindex_${header}.txt

# This will encode the bulk passphrase
openssl enc -aes-256-cbc -a -salt -pass pass:${PASSWORD} -in actualpassphrase_${header}.txt -out encodedpassphrase_${header}.txt

# This will encode the bulk with the passphrase and will remove quotes
cat bulk_${header}.txt | awk -F, '{print $1","$2","$3}' | tr -d '"' | sed 's/.*/'$INDEX',&/' | openssl enc -aes-256-cbc -a -salt -pass file:actualpassphrase_${header}.txt -out encodedbulk_${header}.txt

cat actualpassphrase_${header}.txt | ssss-split -Q -t $2 -n $3 -w ${header} > shares_${header}.txt

# Next lets break out each share to its own file
for k in $(seq 1 1 $3)
do
cat shares_${header}.txt | sed -n ''$k'p' > shares_${k}_${header}.txt
done

for l in $(seq 1 1 $3)
do
echo "ENCODED - ${i}_${l}_${header}" > ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
echo "NOTES: openssl enc -d -aes-256-cbc -a -salt" >> ${printme}_${l}_${header}.txt
echo "       sudo apt-get install ssss curl bc openssl" >> ${printme}_${l}_${header}.txt
echo "       SSSS threshold of $2 shares required" >> ${printme}_${l}_${header}.txt
echo "       ssss-combine -t $2" >> ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
echo "YOUR SHARE START" >> ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
cat shares_${l}_${header}.txt >> ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
echo "YOUR SHARE STOP" >> ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
echo "START ENCODED BULK" >> ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
cat encodedbulk_${header}.txt >> ${printme}_${l}_${header}.txt
echo "" >> ${printme}_${l}_${header}.txt
echo "END ENCODED BULK" >> ${printme}_${l}_${header}.txt
done

cp encodedbulk_${header}.txt bulk_${header}.txt
#rm bulk_${header}.txt
cp encodedbulk_${header}.txt privatekeyindex_${header}.txt
rm privatekeyindex_${header}.txt
cp encodedbulk_${header}.txt actualpassphrase_${header}.txt
rm actualpassphrase_${header}.txt
cp encodedbulk_${header}.txt shares_${header}.txt
rm shares_${header}.txt
rm shares_*_${header}.txt
rm encodedbulk_${header}.txt 
cd ..
done
## clear the password variable
echo "" | read PASSWORD
echo "" | read PASSWORDCONFIRM
clear

echo "How many Safe Deposit Boxes (Vaults) will you have?"
echo "Default: $3"
echo ""
read vaults
if [ "$vaults" == "" ]
then
vaults=$3
fi

for a in $(seq 1 1 $vaults)
do
mkdir zzz_USB_Vault_$a
clear
echo "Which share(s) would you like copied to the USB directory for Vault $a? Please put a space between each number"
echo "Default: ${a}"
echo ""
read whichshares
if [ "$whichshares" == "" ]
then
whichshares=$a
fi
echo ""
echo "Do you want to include the publickeyindex? Y/N? (default is No)"
echo ""
read includepublickeyindex
echo ""
echo "Do you want to include the encodedpassphrase? Y/N? (default is No)"
echo ""
read includeencodedpassphrase
echo ""
echo "Do you want to include an unsecured copy? YES/NO? (default is No)."
echo "WARNING: THIS COMPLETELY UNDERMINES THE ENTER PURPOSE OF THE ENTIRE SCRIPT"
echo "ARE YOU SURE YOU WANT TO PROCEED?"
echo ""
echo "IF SO, YOU MUST TYPE IN YES"
echo ""
read includerawbulk
echo ""
if [ "$includerawbulk" = "y" ] || [ "$includerawbulk" = "Y" ] || [ "$includerawbulk" = "Yes" ] || [ "$includerawbulk" = "YES" ] 
then
clear
echo "Please type YES for confirmation"
read includerawbulkonfirm
if [ "$includerawbulkonfirm" != "YES" ] 
then 
echo "SYNTAX ERROR. FAILURE TO CONFIRM. Exiting."
echo ""
exit 0
fi
fi

for m in $(cat alphabet | head -n $complexity) 
do
mkdir zzz_USB_Vault_$a/${m}
for n in $(echo ${whichshares})
do
if [ "$includepublickeyindex" = "y" ] || [ "$includepublickeyindex" = "Y" ] || [ "$includepublickeyindex" = "Yes" ] || [ "$includepublickeyindex" = "yes" ]  || [ "$includepublickeyindex" = "YES" ]
then
cat ${m}/publickeyindex_${header}.txt | sed 's/.*/'$m'_&/' > zzz_USB_Vault_$a/${m}/${m}_publickeyindex_${header}.txt
fi
if [ "$includeencodedpassphrase" = "y" ] || [ "$includeencodedpassphrase" = "Y" ] || [ "$includeencodedpassphrase" = "Yes" ] || [ "$includeencodedpassphrase" = "yes" ]  || [ "$includeencodedpassphrase" = "YES" ]
then
cp ${m}/encodedpassphrase_${header}.txt zzz_USB_Vault_$a/${m}/${m}_encodedpassphrase_${header}.txt
fi
if  [ "$includerawbulk" = "YES" ]
then
cp bulk_${header}.txt zzz_USB_Vault_$a/bulk_${header}.txt
fi
cp ${m}/${printme}_${n}_${header}.txt zzz_USB_Vault_$a/${m}/${m}_${printme}_${n}_${header}.txt
done
done
done

clear 
echo "Do you want to clean up $(cat alphabet | head -n $complexity)? (Default: no)"
echo "IMPORTANT! IF YOU HAVE NOT ALLOCATED SUFFICIENT SHARES FROM THE PREVIOUS STEPS OR INCLUDED THE ENCODED PASSPHRASE YOU MIGHT BE ABOUT TO DESTROY THE ONLY METHODS TO RECOVER YOUR DATA"
echo ""
read cleanup

clear
if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ] || [ "$cleanup" = "Yes" ] || [ "$cleanup" = "yes" ]  || [ "$cleanup" = "YES" ] 
then
echo "Please type YES for confirmation"
echo ""
read cleanupconfirm
if [ "$cleanupconfirm" != "YES" ] 
then 
echo "SYNTAX ERROR. FAILURE TO CONFIRM. Exiting."
echo ""
exit 0
fi
fi

if [ "$PASSWORD" != "$PASSWORDCONFIRM" ] 
then
clear
echo "ERROR. Passwords do not match. Please re-run script."
exit 0 
fi

if [ "$cleanup" = "y" ] || [ "$cleanup" = "Y" ] || [ "$cleanup" = "Yes" ] || [ "$cleanup" = "yes" ]  || [ "$cleanup" = "YES" ] 
then
for clean in $(cat alphabet | head -n $complexity)
do
rm -rf ${clean}
done
fi

clear
echo "DONE"
echo ""
echo "Next, you will need to insert the first USB flash drive and copy over the contents to that given drive and then repeat for all drives. PLEASE TAKE SPECIFIC CARE AND NOTICE TO THE DATA THAT IS IN THE JAR BY MAKING APPROPRIATE COPIES (EITHER PAPER OR ELECTRONIC). ONCE THE JAR IS REBOOTED ALL OF THE DATA WILL BE LOST AND WILL ONLY BE RECOVERABLE ON YOUR USB DRIVES."
echo ""
echo "IF YOU DO NOT UNDERSTAND THE ABOVE, PLEASE MAKE COPIES OF EVERYTHING AND TAKE THEM TO SOMEONE WHO KNOWS WHAT THE HELL THEY ARE DOING."
echo ""
rm bulk_${header}.txt

echo "If you found this script useful, please consider a BTC donation to support the author."
echo "Please send BTC donations to: 1EVmqkggJxX3pHo1hzfW9nMcSDeFZMoruV"
echo ""

rm alphabet
rm alphanumber
exit 0

