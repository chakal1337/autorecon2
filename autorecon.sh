#!/bin/bash
if [[ $# < 1 ]]; then
 echo "$0 <domain>";
fi
file_date=$1-$(date +"%D" | tr "/" "-");
if ! ls $file_date &>/dev/null; then
 echo making directory $file_date;
 mkdir $file_date;
else
 file_date_original=$file_date;
 for i in $(seq 1 100); do
  file_date=$file_date_original"-$i";
  if ! ls $file_date &>/dev/null; then
   mkdir $file_date;
   break;
  fi
 done
fi
echo $file_date;
cd $file_date;
if ! which assetfinder &>/dev/null; then
 echo "Trying to install assetfinder...";
 sudo apt install assetfinder;
fi
if ! which amass &>/dev/null; then
 echo "Trying to install amass...";
 sudo apt install amass;
fi
if ! which dnsmap &>/dev/null; then
 echo "Trying to install dnsmap...";
 sudo apt install dnsmap;
fi
if ! which whatweb &>/dev/null; then
 echo "Trying to install whatweb...";
 sudo apt install whatweb;
fi
if ! which httprobe &>/dev/null; then
 echo "Trying to install httprobe...";
 sudo apt install httprobe;
fi
if ! which getallurls &>/dev/null; then
 echo "Trying to install getallurls...";
 sudo apt install getallurls;
fi
rm assets.txt &>/dev/null;
rm wordlist.txt &>/dev/null;
rm hostsworking.txt &>/dev/null;
rm assetstemp.txt &>/dev/null;
rm wordlisttmp.txt &>/dev/null;
rm dnsmap.txt &>/dev/null;
rm probed.txt &>/dev/null;
assetfinder -subs-only $1 | tee assets.txt;
amass enum -d $1 -brute -alts -active | tee -a assets.txt;
cat assets.txt | sort -u | tee assetstemp.txt;
mv assetstemp.txt assets.txt;
echo > hostsworking.txt;
for i in $(cat assets.txt); do
 if host $i &>/dev/null; then
  echo $i >> hostsworking.txt;
 fi
done
mv hostsworking.txt assets.txt;
cat assets.txt | xargs -I{} -P 10 dnsmap {} -r dnsmap.txt;
cat dnsmap.txt | grep $1 | sort -u | tee -a assets.txt;
rm dnsmap.txt;
cat assets.txt | sort -u | tee assetstemp.txt;
mv assetstemp.txt assets.txt;
for i in $(seq 1 5); do
 cat assets.txt | cut -d "." -f $i | grep . | sort -u | tee -a wordlist.txt;
done
cat wordlist.txt | sort -u | tee wordlisttmp.txt;
mv wordlisttmp.txt wordlist.txt;
cat assets.txt | xargs -I{} -P 10 dnsmap {} -r dnsmap.txt -w wordlist.txt;
cat dnsmap.txt | grep $1 | sort -u | tee -a assets.txt;
rm dnsmap.txt;
cat assets.txt | sort -u | tee assetstemp.txt;
mv assetstemp.txt assets.txt;
cat assets.txt | httprobe -c 50 -prefer-https | tee probed.txt;
whatweb --color=never --input-file probed.txt | tee whatweb.txt;
echo "All done...check $file_date";
