leofs_rpm
=========

leofs_rpm is the leofs's configuration file for RPM

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
