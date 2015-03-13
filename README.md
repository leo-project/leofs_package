leofs_rpm
=========

leofs_rpm is the leofs's configuration file for RPM(RedHat)/deb(Ubuntu)

###How to make RPM file

1. Prepare environment  
  * Install Git, rpmbuild, erlang  

2. Make working directories  
 ```
$ mkdir -p ~/rpm/{BUILD,RPMS,SOURCES,SPECS,SRPMS}
 ```

3. Copy spec file to 'SPECS' directory  
 ```
$ cp leofs.sh ~/rpm/SPECS  
$ cp leofs.spec ~/rpm/SPECS
 ```

4. Build RPM file  
 ```
$ cd ~/rpm/SPECS  
$ sh leofs.sh VERSION 
Example:  
$ sh leofs.sh 0.14.0  
 ``` 
  * RPM file is created in the 'RPMS' directory.

##How to make deb file

1. Prepare environment
  * Install Git, fakeroot, build-essential

2. Make working directories
 ```
$ mkdir {WORK_DIRECTORY}
 ```

3. Copy script file  
 ```
$ cp make_deb.sh {WORK_DIRECTORY}
 ```

4. Build deb file
 ```
$ cd {WORK_DIRECTORY}
$ ./make_deb.sh
 ```
