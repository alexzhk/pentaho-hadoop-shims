#!/usr/bin/env bash

vendors=( cdh emr hdp mapr );


NewLine=$'\n';
rootDir=/d/mvn_shim3/;
metaFolder=/src/META-INF;
orgFolder=/src/org;
resourcesFolder=/package-res/*;
mavenTreeFile=tree.txt;
antTreeFile=antree.txt;
DependencyTagsFile=dependency.xml;
pluginFile=plugin.xml;
currDir=$(pwd);
#----------------------------------------
buildXML=common-shims-build.xml;

comment1='<!-- target begin -->'
comment2='<!-- target end -->'

target=${comment1}'\n<target name="transfer" depends="subfloor.resolve-default">\n<ivy:makepom ivyfile="${basedir}\/ivy.xml" pomfile="${basedir}\/pom.xml">\n<mapping conf="default" scope="compile"\/>\n<mapping conf="client" scope="compile"\/>\n<mapping conf="provided" scope="provided"\/>\n<mapping conf="pmr" scope="compile"\/>\n<mapping conf="test" scope="test"\/>\n<\/ivy:makepom>\n<\/target>\n'${comment2}'\n<\/project>';



_containsElement () {

	for (( i = 0; i < ${#mvnJars[@]}; i ++ ))
	do

		if [ "${antJars[j]}" = "${mvnJars[$i]}" ]; then
			echo "EQ: ""${antJars[j]}"
			break
		else
			if [ "$i" -eq $((${#mvnJars[@]} - 1)) ]; then
				echo "antNum = ""${antJars[$j]}""  ""$j"
			fi
		fi
	done
}

_getJars() {

	local __return=$2;
	local jars=( );

	local dir="";
	local unzipJars=( );

	echo "---- getJars ----"
	echo $1

	#add all artifactId`s from the directory (i.e. lib, client, pmr) to an array
	cd $1
	shopt -s nullglob
	unzipJars=( *.jar )
	echo "Jar[1]=" "${unzipJars[1]}"


	eval $__return='("${unzipJars[@]}")'

}

_compareJars() {

	echo "==== _compareJars ===="

	local __return=$4;
	local jars=( );

	local notFound=();

	local arrTree=( );
	local arrNum=( );

	local arrNum2=( );
	local arrTemp=( );

	local antNum=( );
	local otherVersionJars=();


	local arrNumShort=( );

	local antJars=( );
	local mvnJars=( );

	local antJars2=( );

	local dirName="";


	echo
	echo "GET JARS"
	echo $1
	echo $2

	_getJars $1 antJars
	_getJars $2 mvnJars

	# echo "+++++++++++++++++++++++++++++"
	# for (( i = 0; i < ${#antJars[@]}; i ++ ))
	# do
	# echo "$i""  ""${antJars[$i]}"
	# done
	# echo "################################"
	# for (( i = 0; i < ${#mvnJars[@]}; i ++ ))
	# do
	# echo "$i""  ""${mvnJars[$i]}"
	# done
	# echo "+++++++++++++++++++++++++++++"

	arrTree=$3[@]
	arrTree=( "${!arrTree}" )


	# echo "UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUU"
	# for (( i = 0; i < ${#arrTree[@]}; i ++ ))
	# do
	# echo "$i""  ""${arrTree[$i]}"
	# done
	# echo "RRRRRRRRRRRRRRRRRRRRRRRRRRRR"


	echo
	echo "((((((((( 2 CYCLE )))))))))))"
	for (( j = 0; j < ${#antJars[@]}; j ++ ))
	do


		for (( i = 0; i < ${#mvnJars[@]}; i ++ ))
		do

			if [ "${antJars[j]}" = "${mvnJars[$i]}" ]; then
				echo "EQ: ""${antJars[j]}"
				break
			else
				if [ "$i" -eq $((${#mvnJars[@]} - 1)) ]; then
					echo "otherVersionJars = ""${antJars[$j]}""  ""$j"
					otherVersionJars["${#otherVersionJars[@]}"]="${antJars[$j]}";
				fi
			fi

		done
	done

	##################### 1 cycle: get nums ant unzip jars in ant tree
	echo
	echo "((((((((( 1 CYCLE )))))))))))"
	for j in "${otherVersionJars[@]}"
	do
		for (( i = 0; i < ${#arrTree[@]}; i ++ ))
		do
			#echo "i = ""$i"
			if [ "$j" = "${arrTree[$i]}" ]; then
				arrNum["${#arrNum[@]}"]="$i"
				#echo "$i"
				break
			else
				#echo "fffffff " "$i" "  " $((${#arrTree[@]} - 1))
				if [ "$i" -eq $((${#arrTree[@]} - 1)) ]; then
					#echo "tttttt""$j"
					notFound["${#notFound[@]}"]="$j"
				#echo "$notFound"
				fi
			fi

		done
	done
	#####################
	echo "//////////////////////////////"
	echo "notFound:"
	for i in "${notFound[@]}"
	do
		echo "$i"
	done

	echo "\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\"
	echo "oooooooooooooooooooooooooooooooooooooooooo"
	for (( i = 0; i < ${#arrNum[@]}; i ++ ))
	do
		echo "$i" "${antTree["${arrNum[$i]}"]}"
	done


	############## ONLY FOR CLIENT #################
	# Remove jars from arrNum array that exist in lib folder
	dirCl=$(echo $1 | sed 's/\(.*\)\///')
	echo "dir client: "$dirCl

	if [ "$dirCl" = "client" ]; then


		for (( i = 0; i < ${#arrNum[@]}; i ++ ))
		do
			tmp="${antTree["${arrNum[$i]}"]}"
			IFS='#' read -ra GAV <<< "$tmp"
			arrTemp["${#arrTemp[@]}"]="${GAV[1]}"
		done

		echo "llllllllllllllllllllllllll"
		for (( i = 0; i < ${#arrTemp[@]}; i ++ ))
		do
			echo "--- ""${arrTemp[$i]}"
		done


		dirName=$(echo $1 | sed 's/\/client//g')
		echo "[[[[[[[[[[[[[[[[[[[[[ dir NAME"
		echo $dirName
		_getJars ${dirName} antJars2

		for (( i = 0; i < ${#arrTemp[@]}; i ++ ))
		do
			echo "--- ""${arrTemp[$i]}"
			for (( j = 0; j < ${#antJars2[@]}; j ++ ))
			do

				tmp=$(echo "${antJars2[$j]}" | sed 's/^'"${arrTemp[$i]}"'-[0-9].*//g')
				if [ "$tmp" = "" ]; then
					#arrNum2["${#arrNum2[@]}"]="$i"
					break
				else
					if [ "$j" -eq $((${#antJars2[@]} - 1)) ]; then
						arrNum2["${#arrNum2[@]}"]="${arrNum[$i]}"
						echo "wwwwwww"
						echo "${arrNum[$i]}"
					fi
				fi

			done
		done

		arrNum=( "${arrNum2[@]}" )

	fi





	eval $__return='("${arrNum[@]}")'

}


_compareAntAndMavenZips() {

	local __return=$1;
	local result="";


	local currDirectory=$(pwd);
	local antArchDir=$currDir/$dir/dist/$dir;
	local mvnArchDir=$rootDir$dir/target/$dir;
	#get folder`s tree from unzip archive (i.e. lib, client, pmr folders)
	local antFolderTree=( $(find ${antArchDir} -type d -print) );
	local mvnFolderTree=( $(find ${mvnArchDir} -type d -print) );
	local unzipAntJars=( );
	local unzipMavenJars=( );

	local arrAntTree=( );

	local addedJars=( );

	local resultDepJars=();

	local tmpArt="";

	#get ant Tree in array
	for el in "${antTree[@]}"
	do
		IFS='#' read -ra GAV <<< "$el"
		arrAntTree["${#arrAntTree[@]}"]="${GAV[1]}""-""${GAV[2]}"".jar"
	done

	echo "|||||||||||||||||||||| " "${arrAntTree[18]}"

	################################
	for((k=1; k<${#antFolderTree[@]}; k++))
	#for (( k = 1; k < 2; k ++ ))
	do
		echo "Directory: " "${antFolderTree[$k]}"
		#dirName="${antFolderTree[$k]}"
		#dirName=$(echo $dirName | sed 's/\(.*\)\///')
		#echo "dir name: "$dirName

		#if [ "$dirName" = "client" ]; then

		_compareJars "${antFolderTree[$k]}" "${mvnFolderTree[$k]}" arrAntTree addedJars

		resultDepJars=("${resultDepJars[@]}" "${addedJars[@]}")

	#fi

	#echo "${antTree[${addedJars[0]}]}"

	done
	################################


	resultDepJars=($(echo "${resultDepJars[@]}" | tr ' ' '\n' | sort -u | tr '\n' ' '))

	echo "TTTTTTTTTTTTTTTTTTTTTTTTTTT"
	echo "${resultDepJars[@]}"


	for (( i = 0; i < ${#resultDepJars[@]}; i ++ ))
	do
		echo "$i" "${antTree["${resultDepJars[$i]}"]}"
	done


	#-------------- Add Dependencies to POM -----------
	for i in "${resultDepJars[@]}"
	do
		tmpArt="${antTree[$i]}"
		IFS='#' read -ra GAV <<< "$tmpArt"
		result="$result""<dependency>\n<groupId>""${GAV[0]}""<\/groupId>\n<artifactId>""${GAV[1]}""<\/artifactId>\n<version>""${GAV[2]}""<\/version>\n<exclusions>\n<exclusion>\n<groupId>*<\/groupId>\n<artifactId>*<\/artifactId>\n<\/exclusion>\n<\/exclusions>\n<\/dependency>\n"
	done

	if [ "$result" != "" ]; then result="$result""<\/dependencies>\n"; fi;

	eval $__return="'$result'"

}



_containsFolder() {

	local __return=$2;
	local result="false";

	for vendor in "${vendors[@]}"
	do
		if [ $vendor = $1 ]
		then
			result="true";
			echo $vendor""$result
			break;
		fi
	done

	eval $__return="'$result'"

}


_makeDir() {

	mkdir -p $1

}


_copyFiles() {
	f=$1;
	local srcMeta="./"${f}${metaFolder};
	local srcOrg="./"${f}${orgFolder};
	local resources="./"${f}${resourcesFolder};
	local srcDest="$rootDir"${f}"/src/main/java";
	local resDest="$rootDir"${f}"/src/main/resources";

	cp -r ${srcMeta} ${srcDest}
	cp -r ${srcOrg} ${srcDest}
	cp -r ${resources} ${resDest}

}


#-----------------------------------
#1st param: root directory name (i.e. hdp25, cdh59)
#-----------------------------------
_createProject() {

	local _shimSrcDir="$rootDir"$1"/src/main/java";
	local _shimResourceDir="$rootDir"$1"/src/main/resources";
	local _shimAssemblyDir="$rootDir"$1"/src/main/assembly/descriptors";

	_makeDir "$_shimSrcDir"
	_makeDir "$_shimResourceDir"
	_makeDir "$_shimAssemblyDir"

	_copyFiles $1


}


_createXML() {

	local dir=$1;

	local doubleDeps="";

	#inject ant targets into build xml file
	sed -i 's/<\/project>/'"$target"'/' ${buildXML}

	cp tmp.sh ${dir}
	#run ant target
	cd ${dir}
	ant transfer
	ant clean-all
	ant resolve >> ${antTreeFile}
	sed '/found/!d' ${antTreeFile} >> temptree.txt
	rm -f ${antTreeFile}
	sed 's/^.*found\s//g;s/\s.*//g;s/\;/#/g' temptree.txt >> ${antTreeFile}
	rm -f temptree.txt

	shimDir=$(pwd)


	#buildSection="<build>\n<sourceDirectory>..\/<\/sourceDirectory>\n<plugins>\n<plugin>\n<groupId>org.apache.maven.plugins<\/groupId>\n<artifactId>maven-compiler-plugin<\/artifactId>\n<configuration>\n<includes>\n<include>common\/src\/**\/*.java<\/include>\n<include>common\/src-hadoop-shim-1.0\/**\/*.java<\/include>\n<include>common\/src-hbase-1.0\/**\/*.java<\/include>\n<include>common\/src-hbase-shim-1.1\/**\/*.java<\/include>\n<include>common\/src-mapred\/**\/*.java<\/include>\n<include>common\/src-modern\/**\/*.java<\/include>\n<include>common\/src-pig-shim-1.0\/**\/*.java<\/include>\n<include>"${dir}"\/src\/main\/java\/**\/*.java<\/include>\n<\/includes>\n<source>\${source.jdk.version}<\/source>\n<target>\${target.jdk.version}<\/target>\n<\/configuration>\n<\/plugin>\n<plugin>\n<artifactId>maven-assembly-plugin<\/artifactId>\n<version>2.6<\/version>\n<executions>\n<execution>\n<id>pkg<\/id>\n<phase>package<\/phase>\n<goals>\n<goal>single<\/goal>\n<\/goals>\n<\/execution>\n<\/executions>\n<configuration>\n<descriptor>\${basedir}\/src\/main\/assembly\/descriptors\/plugin.xml<\/descriptor>\n<appendAssemblyId>false<\/appendAssemblyId>\n<\/configuration>\n<\/plugin>\n<\/plugins>\n<\/build>\n<\/project>";

	#1----inject build section into pom xml file
	#sed -i 's/<\/project>/'"$buildSection"'/' pom.xml
	mvn dependency:tree -DoutputFile=${mavenTreeFile}
	sed 's/^.*\s//g' ${mavenTreeFile} >> temptree1.txt
	rm -f ${mavenTreeFile}
	cat temptree1.txt >> ${mavenTreeFile}
	rm -f temptree1.txt


	#sed '/<exclusions>/,/<\/exclusions>/d' pom.xml > OO.xml

	#do not forget pass file name as $1 parameter to get vmn dependency tree
	#IFS=$'\r\n' GLOBIGNORE='*' command eval  'tree=($(cat ${mavenTreeFile}))'

	#2------- BEGIN ANT DIST AND UNZIP SHIM ZIP ARCHIVE -------
	ant dist

	cp tmp.sh dist
	cp ${mavenTreeFile} dist
	cp ${antTreeFile} dist
	rm -f tmp.sh
	rm -f ${mavenTreeFile}
	rm -f ${antTreeFile}

	cd dist

	#get name from build.properties file [NEED TO PARSE IT!!!!!!!!]
	archName='pentaho-hadoop-shims-'${dir}'-package-7.1-SNAPSHOT.zip';

	unzip ${archName} -d .

	#------- END UNZIP SHIM ZIP ARCHIVE ----------------------




	#3------ Begin Generate assembly descriptor --------------------
	IFS=$'\r\n' GLOBIGNORE='*' command eval 'antTree=($(cat ${antTreeFile}))'

	#return to the shim`s folder
	#cd ..
	#./dependencySet.sh ${dir}
	./tmp.sh ${dir} ${mavenTreeFile} ${shimDir} ${DependencyTagsFile} ${pluginFile} ${antTreeFile}
	rm -f ${mavenTreeFile}
	rm -f tmp.sh
	#------ End Generate assembly descriptor -----------------------



	#------ Add new dependencies and build section to a pom file -----------------------
	cd ..
	sed -i 's/<\/dependencies>//' pom.xml
	sed -i 's/<\/project>//' pom.xml
	cat ${DependencyTagsFile} >> pom.xml
	echo "</dependencies>"${NewLine}"</project>" >> pom.xml

	buildSection="\n<build>\n<sourceDirectory>..\/<\/sourceDirectory>\n<plugins>\n<plugin>\n<groupId>org.apache.maven.plugins<\/groupId>\n<artifactId>maven-compiler-plugin<\/artifactId>\n<configuration>\n<includes>\n<include>common\/src\/**\/*.java<\/include>\n<include>common\/src-hadoop-shim-1.0\/**\/*.java<\/include>\n<include>common\/src-hbase-1.0\/**\/*.java<\/include>\n<include>common\/src-hbase-shim-1.1\/**\/*.java<\/include>\n<include>common\/src-mapred\/**\/*.java<\/include>\n<include>common\/src-modern\/**\/*.java<\/include>\n<include>common\/src-pig-shim-1.0\/**\/*.java<\/include>\n<include>"${dir}"\/src\/main\/java\/**\/*.java<\/include>\n<\/includes>\n<source>1.8<\/source>\n<target>1.8<\/target>\n<\/configuration>\n<\/plugin>\n<plugin>\n<artifactId>maven-assembly-plugin<\/artifactId>\n<version>2.6<\/version>\n<executions>\n<execution>\n<id>pkg<\/id>\n<phase>package<\/phase>\n<goals>\n<goal>single<\/goal>\n<\/goals>\n<\/execution>\n<\/executions>\n<configuration>\n<descriptor>\${basedir}\/src\/main\/assembly\/descriptors\/plugin.xml<\/descriptor>\n<appendAssemblyId>false<\/appendAssemblyId>\n<\/configuration>\n<\/plugin>\n<\/plugins>\n<\/build>\n<\/project>";

	#1----inject build section into a pom xml file
	sed -i 's/<\/project>/'"$buildSection"'/' pom.xml
	#------------------------------------------------------------------------------------


	#The rest of the actions
	cp ${pluginFile} ${rootDir}${dir}/src/main/assembly/descriptors
	cp pom.xml ${rootDir}${dir}
	rm -f pom.xml

	if [ -f ${DependencyTagsFile} ]; then
		rm -f ${DependencyTagsFile}
	fi

	if [ -f ${pluginFile} ]; then
		rm -f ${pluginFile}
	fi

	#cd ..

	cd $currDir
	sed -i '/'"$comment1"'/,/'"$comment2"'/ d' ${buildXML}



	######### Run maven commands to create archive #######
	cd ${rootDir}${dir}
	mvn clean install

	archName="pentaho-hadoop-shims-"${dir}"-7.1-SNAPSHOT.zip"

	unzip ./target/${archName} -d ./target

	#unzip ./target/pentaho-hadoop-shims-cdh57-7.1-SNAPSHOT.zip -d ./target

	echo
	echo "======== Get antTree value from array in main.sh"
	echo "${antTree[1]}"

	_compareAntAndMavenZips doubleDeps

	if [ "$doubleDeps" != "" ]; then
		#------ Update POM again --------------

		sed -i 's/<\/dependencies>/'"$doubleDeps"'/' ${rootDir}${dir}/pom.xml


		cd ${rootDir}${dir}
		mvn clean install
	fi




}


test() {

	IFS=$'\r\n' GLOBIGNORE='*' command eval 'antTree=($(cat tree.txt))'
	echo "TEST " "${antTree[1]}"

	_compareAntAndMavenZips doubleDeps

	echo "uuuuuuuuuu"
	echo "$doubleDeps"

	if [ "$doubleDeps" != "" ]; then
		sed -i 's/<\/dependencies>/'"$doubleDeps"'/' /d/mvn_shim3/cdh57/pom.xml
	fi


}


for d in */; do

	dir=${d%*/}
	#echo ${dir##*/}

	oozie=$(echo "$dir" | sed 's/[0-9]//g');

	_containsFolder $oozie res

	if [ "$res" = "true" ]; then
		_createProject $dir
		_createXML $dir
	#test $dir
	fi

done