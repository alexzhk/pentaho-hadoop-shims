artifactArr="";
versionArr="";
artifactIdDep=0;
versionDep=0;

if [ -z "$1" ]
then
    echo
    echo "missing command"
    echo "type output file name (i.e. out.xml)"
    echo
    exit
fi

while read p || [ -n "$p" ]; do

artifactId=$(echo $p | sed 's/.*<artifactId>.*/A/g')

if [ "$artifactId" = "A" ]
then
    artifactIdFull=$(echo $p | sed 's/<artifactId>//g;s/<\/artifactId>//g')
    artifactId=$(echo $p | sed 's/<artifactId>//g;s/<\/artifactId>//g' | sed 's/-.*//g')
    
    check=1;
    
    if [[ ${#artifactId} -gt 1 && "$artifactIdDep" -ne 0 ]]
    echo "artifactId="$artifactId
    then
        #======================================
        if [ "${artifactArr[0]}" = "" ]
        then
            artifactArr[0]="$artifactId"
            
        else
            for el in "${artifactArr[@]}"
            do
                if [ "$el" = "$artifactId" ]
                then
                    check=0
                    break;
                fi
            done
            
            if [ "$check" -eq 1 ]; then artifactArr[${#artifactArr[@]}]="$artifactId"; fi;
            
        fi
        
        continue
    fi
    
    #==================
fi
artifactIdDep=1;

version=$(echo $p | sed 's/.*<version>.*/V/g')

if [ "$version" = "V" ]
then
    version=$(echo $p | sed 's/<version>//g;s/<\/version>//g')
    
    if [ "${versionArr[0]}" = "" ]
    then
        if [ "$versionDep" -ne 0 ]; then versionArr[0]="$version"; fi;
        versionDep=1;
    else
        if [ ${#artifactArr[@]} -gt ${#versionArr[@]} ]
        then
            
            if [ "$version" != "" ]
            then
                versionArr[${#versionArr[@]}]="$version"
                echo
                echo "version="$version
            else
                unset artifactArr[${#artifactArr[@]}-1]
            fi
            
        fi
    fi
    
    continue
    
else
    if [ ${#artifactArr[@]} -gt ${#versionArr[@]} ]; then unset artifactArr[${#artifactArr[@]}-1]; fi;
    
fi

done <pom.xml

echo "Artifact list:"
echo ${artifactArr[@]:0}
echo
echo "Version list:"
echo ${versionArr[@]:0}
echo

NewLine=$'\n';
properties="";
index=0;

for i in "${artifactArr[@]}"
do
properties="$properties""<"$i".version>"${versionArr[$index]}"</"$i".version>"${NewLine}
index=$((index+1))
done

#----------------------------------
artifactIdDep=0;
versionDep=0;

if [ -f $1 ] ; then
rm $1
fi

prop=$(sed -n '/<properties>.*/{p;q;}' pom.xml | sed 's/^\s*//g');
check=0;
if [ "$prop" != "<properties>" ]
then
properties="<properties>"${NewLine}"$properties""</properties>"
fi

echo "PROPERTIES:"
echo $properties
echo

if [ "$prop" = "<properties>" ]
then
check=1;
properties="$properties"
fi

while read p || [ -n "$p" ]; do

echo $p

props=$(echo $p | sed 's/.*<properties>.*/P/g')
if [ "$props" = "P" ]
then
properties="${properties::-1}"
p=$p${NewLine}"$properties"
fi

deps=$(echo $p | sed 's/.*<dependencies>.*/D/g')
if [[ "$deps" = "D"  && "$check" -eq 0 ]]
then
p="$properties"${NewLine}$p
fi

artifactId=$(echo $p | sed 's/.*<artifactId>.*/A/g')

if [ "$artifactId" = "A" ]
then
artifactId=$(echo $p | sed 's/<artifactId>//g;s/<\/artifactId>//g' | sed 's/-.*//g')

if [[ ${#artifactId} -gt 1  && "$artifactIdDep" -ne 0 ]]
then
for (( c=0; c<${#artifactArr[@]}; c++ ))
do
    if [ "$artifactId" = ${artifactArr[$c]} ]
    then
        artifactIdDep="$artifactId"
        p=$p${NewLine}"<version>\${"${artifactArr[$c]}".version}</version>"
        echo "PPP"=$p
        break;
    fi
done
fi
artifactIdDep=1;
fi

version=$(echo $p | sed 's/.*<version>.*/V/g')

if [ "$version" = "V" ]
then
version=$(echo $p | sed 's/>.*/>/g')
fi

if [ "$version" != "<version>" ]
then
echo "$p">> $1
else
if [ "$versionDep" -eq 0 ]
then
echo "$p">> $1
versionDep=1;
fi
fi

done <pom.xml
