#**
#* Ccoffee Build tool, manual build, alpha-v1.
#*
#* @author pavl_g.
#*#
#!/bin/sh

# export all locales as "en_US.UTF-8" for the gcc compiler 
export LC_ALL="en_US.UTF-8"

canonical_link=`readlink -f ${0}`
assemble_dir=`dirname $canonical_link`

source "${assemble_dir}/variables.sh"
source "${assemble_dir}/generate-docs.sh"

function makeDir() {
    local folder=$1
    
    if [[ ! -d $folder ]]; then
        if [[ ! `mkdir $folder` -eq 0 ]]; then
            errors=$(( $errors + 1 ))
        fi
    fi
    return $errors
}

#**
#* Makes an output directory at the output location.
#
#* @return the number of errors.
#**
function makeOutputDir() {
    local errors
    cd $javabuild_directory
    
    makeDir $jar_folder

    return $errors
}

#**
#* Creates a Manifest.mf file for the jar main class designation and dependencies inclusion.
#
#* @return the number of errors, 0 if no errors, 1 or 2 if there are errors.
#**
function createManifest() {
    local errors=0
    cd $jar_tmp
    if [[ ! `echo $manifest > Manifest.mf` -eq 0 ]]; then
        errors=$(( $errors + 1 ))
    fi
    if [[ ! `echo $mainclass >> Manifest.mf` -eq 0 ]]; then
        errors=$(( $errors + 1 ))
    fi
    if [[ ! `echo $api_name >> Manifest.mf` -eq 0 ]]; then
        errors=$(( $errors + 1 ))
    fi
    if [[ ! `echo $version >> Manifest.mf` -eq 0 ]]; then
        errors=$(( $errors + 1 ))
    fi
    return $errors
}

#**
#* Adds the android native dependencies (the .so native object files) as a jar dependency 
#* at the output/Arithmos/dependencies relative path. 
#
#* @return the number of errors, 0 if no errors, 1 or 2 if there are errors.
#**
function addAndroidNativeDependencies() {
    local errors=0
    # get the object files to link them
    cd $shared_root_dir
    if [[ ! `zip -r $android_natives_jar . -i "lib/*"` -eq 0 ]]; then
        errors=$(( $errors + 1 ))
    fi
    
    android_jar=$shared_root_dir"/$android_natives_jar"
    if [[ $android_jar ]]; then
        # copy the object file to the build dir
        if [[ ! `mv $android_jar $jar_tmp` -eq 0 ]]; then
            errors=$(( $errors + 1 ))
        fi 
    fi
    return $errors
}

#**
#* Adds the linux native dependencies (the .so native object files)
#* at the output/Arithmos relative path. 
#*
#* @return the number of errors, 0 if no errors, 1 or 2 if there are errors.
#**
function addDesktopNativeDependencies() {
    local errors=0
    cd $shared_root_dir
	
    if [[ $shared_root_dir ]]; then
        # copy the object file to the build dir
        if [[ ! `cp -r $shared_root_dir'/native' $jar_tmp` -eq 0 ]]; then
            errors=$(( $errors + 1 ))
        fi   
    fi   
    return $errors
}

function addAssets() {
    local errors=1 
    if [[ -f $assets ]]; then
        if [[ ! `mkdir $jar_tmp'/assets'` -eq 0 ]]; then
            errors=$(( $errors + 1 ))
        fi
        # copy to an asset folder
        cp -r $assets $jar_tmp'/assets'
        cd $jar_tmp
        # zip the assets into a jar file
        if [[ ! `zip -r assets.jar . -i 'assets/*'` -eq 0 ]]; then
            errors=$(( $errors + 1 ))
        fi
        # remove the assets folder
        rm -rf 'assets'
    else 
        errors=$(( $errors + 1 ))
    fi
    return $errors
}

function createDocsJar() {
    # get the manifest file to link it
    cd "${project_root}/docs/$java_docs_folder" && $java_jar --create --file $java_docs_jar --manifest $manifest_file "./"
	
    # move the jar to its respective output folder
    mv $java_docs_jar $jar_tmp && cd "${project_root}"
    
	return $?
}

function createJar() {
    local errors=0
    # get the manifest file to link it
    cd $javabuild_directory
    # get the class files ready
    bytecode=`find -name "*.class"`
    # command and output a jar file with linked manifest, java class files and object files
    if [[ ! `$java_jar --create --file $jar --manifest $manifest_file $bytecode -C $jar_tmp './native'` -eq 0 ]]; then 
        errors=$(( $errors + 1 ))
    fi
	
    # move the jar to its respective output folder
    mv $jar $jar_tmp

	rm -r $jar_tmp'/native/'

    return $errors
}

function createOutput() {
    # move the jar directory containing the jar and the assets to the output directory
    mv $jar_tmp $project_root'/output'
}

function removeManifest() {
    # remove the residual manifest file
    cd $project_root'/output/'$jar_folder
    rm 'Manifest.mf'
}
