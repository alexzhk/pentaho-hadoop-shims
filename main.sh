vendors=(cdh emr hdp mapr);

rootDir=/d/mvn_shim3/;
metaFolder=/src/META-INF;
orgFolder=/src/org;
resourcesFolder=/package-res/*;

#----------------------------------------
buildXML=common-shims-build.xml;

comment1='<!-- target begin -->'
comment2='<!-- target end -->'

target=${comment1}'\n<target name="transfer" depends="subfloor.resolve-default">\n<ivy:makepom ivyfile="${basedir}\/ivy.xml" pomfile="${basedir}\/pom.xml">\n<mapping conf="default" scope="compile"\/>\n<mapping conf="client" scope="compile"\/>\n<mapping conf="provided" scope="provided"\/>\n<mapping conf="pmr" scope="compile"\/>\n<mapping conf="test" scope="test"\/>\n<\/ivy:makepom>\n<\/target>\n'${comment2}'\n<\/project>';

#targets=${targetPOM}${targetAssembly};



_containsFolder () {

local __return=$2;
local result="false";

for vendor in "${vendors[@]}"
    do
 if [ $vendor = $1 ]
        then
            result="true";
			echo $vendor"  "$result
            break;
        fi
done

eval $__return="'$result'"

}


_makeDir () {

mkdir -p $1

}


_copyFiles () {
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
_createProject () {

local _shimSrcDir="$rootDir"$1"/src/main/java";
local _shimResourceDir="$rootDir"$1"/src/main/resources";
local _shimAssemblyDir="$rootDir"$1"/src/main/assembly/descriptors";

_makeDir "$_shimSrcDir"
_makeDir "$_shimResourceDir"
_makeDir "$_shimAssemblyDir"

_copyFiles $1


}


_createXML () {

local dir=$1;

#inject ant targets into build xml file
sed -i 's/<\/project>/'"$target"'/' ${buildXML}


#run ant target
cd ${dir}
ant transfer


buildSection="<build>\n<sourceDirectory>..\/<\/sourceDirectory>\n<plugins>\n<plugin>\n<groupId>org.apache.maven.plugins<\/groupId>\n<artifactId>maven-compiler-plugin<\/artifactId>\n<configuration>\n<includes>\n<include>common\/src\/**\/*.java<\/include>\n<include>common\/src-hadoop-shim-1.0\/**\/*.java<\/include>\n<include>common\/src-hbase-1.0\/**\/*.java<\/include>\n<include>common\/src-hbase-shim-1.1\/**\/*.java<\/include>\n<include>common\/src-mapred\/**\/*.java<\/include>\n<include>common\/src-modern\/**\/*.java<\/include>\n<include>common\/src-pig-shim-1.0\/**\/*.java<\/include>\n<include>"${dir}"\/src\/main\/java\/**\/*.java<\/include>\n<\/includes>\n<source>\${source.jdk.version}<\/source>\n<target>\${target.jdk.version}<\/target>\n<\/configuration>\n<\/plugin>\n<plugin>\n<artifactId>maven-assembly-plugin<\/artifactId>\n<version>2.6<\/version>\n<executions>\n<execution>\n<id>pkg<\/id>\n<phase>package<\/phase>\n<goals>\n<goal>single<\/goal>\n<\/goals>\n<\/execution>\n<\/executions>\n<configuration>\n<descriptor>\${basedir}\/src\/main\/assembly\/descriptors\/plugin.xml<\/descriptor>\n<appendAssemblyId>false<\/appendAssemblyId>\n<\/configuration>\n<\/plugin>\n<\/plugins>\n<\/build>\n<\/project>";

#1----inject build section into pom xml file
sed -i 's/<\/project>/'"$buildSection"'/' pom.xml


#2------- BEGIN ANT DIST AND UNZIP SHIM ZIP ARCHIVE -------
ant clean-all resolve dist
cd dist

#get name from build.properties file [NEED TO PARSE IT!!!!!!!!]
archName='pentaho-hadoop-shims-'${dir}'-7.0-SNAPSHOT.zip';

unzip ${archName} -d .

#------- END UNZIP SHIM ZIP ARCHIVE ----------------------




#3------ Begin Generate assembly descriptor --------------------
./assembly.sh ${dir}

#------ End Generate assembly descriptor -----------------------



#The rest of the actions
#cp pom.xml ${rootDir}${dir}
#rm -f pom.xml
#cd ..
#sed -i '/'"$comment1"'/,/'"$comment2"'/ d' common-shims-build.xml

}

for d in */ ; do
	
	dir=${d%*/}
    #echo ${dir##*/}
	
	oozie=$( echo "$dir" | sed 's/[0-9]//g');
	
	_containsFolder $oozie res

	if [ "$res" = "true" ]; then
	_createProject $dir
	_createXML $dir
	fi

done