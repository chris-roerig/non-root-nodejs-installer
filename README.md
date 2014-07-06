non-root-nodejs-installer
=========================

A simple Ruby script that installs (from source) the most recent version of NodeJS for the current user. Root not required.

This is http://tnovelli.net/blog/blog.2011-08-27.node-npm-user-install.html distilled into a script. 

**Confirmed working on:**
* Ubuntu 14.04

Let me know if you find success on other versions/platforms.

##Usage


```
$ bundle
$ ruby install-node.rb
```

##Help

If your getting the error

```
Could not open library 'archive': archive: cannot open shared object file: No such file or directory. (LoadError)
Could not open library 'libarchive.so': libarchive.so: cannot open shared object file: No such file or directory
```

You need to install the libarchive library.

```
$ sudo apt-get install libarchive-dev
```

Feel free to add improvments. 
