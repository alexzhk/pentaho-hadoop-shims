str="";
NewLine=$'\n'
dir=$3;

# if [ -f $2 ] ; then
    # rm $2
# fi

mvn dependency:tree -DoutputFile=$1


while read p; do
#==================== begin loop

str=$(echo $p | sed 's/^.*\s//g')

if [ ${p:0:1} = "+" ] #------- begin 2 if
then

if [ $str = "" ]
then
continue
fi

#str=${str//:/$'\n'} 
echo "STR = " $str
IFS=':' read -ra GAV <<< "$str"

assemblyDir="${GAV[4]}"

artifact=$(sed -n '/'"${GAV[1]}"'/{p;q;}' ivy.xml);

echo $artifact

if [ "$artifact" != "" ]; then #--- begin if
transitiv=$artifact

artifact=$(echo $artifact | sed 's/.*transitive=\"true\".*/NaN/g')
artifact=$(echo $artifact | sed 's/.*transitive=\"false\".*/NoN/g')

echo $artifact
#-------------------------
case "$artifact" in
     NaN)      
          transitiveTrue="$transitiveTrue""<include>""${GAV[0]}"":""${GAV[1]}""</include>"${NewLine}
		  echo
		  echo "-----------------"
		  echo "Transitive TURE: " $transitiveTrue
		  echo "-----------------"
		  echo
          ;;
     NoN)      
          transitiveFalse="$transitiveFalse""<include>""${GAV[0]}"":""${GAV[1]}""</include>"${NewLine}		  
		  echo
		  echo "-----------------"
		  echo "Transitive FALSE: " $transitiveFalse
		  echo "-----------------"
		  echo
          ;;
     *)
          echo "BY DEF TRUE"
          transitiveTrue="$transitiveTrue""<include>""${GAV[0]}"":""${GAV[1]}""</include>"${NewLine}
		  echo
		  echo "-----------------"
		  echo "Transitive TURE: " $transitiveTrue
		  echo "-----------------"
		  echo
          ;;
esac
#-------------------------

fi #--- end if


else

comments="";

if [ "$mainArtifact" != "${GAV[1]}" ]; then
mainArtifact="${GAV[1]}"
comments="<!-- transitive dependencies for "${mainArtifact}" -->"
fi

#str=$(echo $p | sed 's/^.*[a-z]//g')

echo "subTransitive = " $str

IFS=':' read -ra subGAV <<< "$str"


if [ "$comments" != "" ]; then
subTransitive="$subTransitive""$comments"${NewLine}"<include>""${subGAV[0]}"":""${subGAV[1]}""</include>"${NewLine}
else
subTransitive="$subTransitive""<include>""${subGAV[0]}"":""${subGAV[1]}""</include>"${NewLine}
fi


echo
echo "----------------------"
echo "Sub Transitive Tag: "$subTransitive
echo "----------------------"
echo
fi #------- end 2 if


done <$1
#==================== end loop


if [ "$transitiveTrue" != "" ]
then

if [ "$transitiveFalse" != "" ]; then
result1="<dependencySet>"${NewLine}"<outputDirectory>/lib/"${assemblyDir}"</outputDirectory>"${NewLine}"<includes>"${NewLine}"$transitiveTrue""$subTransitive""<!-- Dependencies from ivy with transitive=false -->"${NewLine}"$transitiveFalse""</includes>"${NewLine}"</dependencySet>"
else
result1="<dependencySet>"${NewLine}"<outputDirectory>/lib/"${assemblyDir}"</outputDirectory>"${NewLine}"<useTransitiveDependencies>true</useTransitiveDependencies>"${NewLine}"<useTransitiveFiltering>true</useTransitiveFiltering>"${NewLine}"<includes>"${NewLine}"$transitiveTrue""$subTransitive""</includes>"${NewLine}"</dependencySet>"
fi

#result1="<dependencySet>"${NewLine}"<outputDirectory>/lib/"${assemblyDir}"</outputDirectory>"${NewLine}"<useTransitiveDependencies>true</useTransitiveDependencies>"${NewLine}"<useTransitiveFiltering>true</useTransitiveFiltering>"${NewLine}"<includes>"${NewLine}"$transitiveTrue""$subTransitive""</includes>"${NewLine}"</dependencySet>"
echo "$result1" >> $2
fi
  
# if [ "$transitiveFalse" != "" ]
# then
# result2="<dependencySet>"${NewLine}"<outputDirectory>/lib/"${assemblyDir}"</outputDirectory>"${NewLine}"<useTransitiveDependencies>false</useTransitiveDependencies>"${NewLine}"<useTransitiveFiltering>false</useTransitiveFiltering>"${NewLine}"<includes>"${NewLine}"$transitiveFalse""</includes>"${NewLine}"</dependencySet>"
# echo "$result2" >> $2
# fi 