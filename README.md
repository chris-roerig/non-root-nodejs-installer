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

**Note:**
On my i7 machine it takes **~6 minutes to complete** the installation.
Be patient.


##Help

* If you are getting the error

```
Could not open library 'archive': archive: cannot open shared object file: No such file or directory. (LoadError)
Could not open library 'libarchive.so': libarchive.so: cannot open shared object file: No such file or directory
```

You need to install the libarchive library.

```
$ sudo apt-get install libarchive-dev
```

* If the installer finishes but you see the message

```
The script finished but it looks like there might have been trouble. Try again
```

First, in your terminal run:
```
$ export PATH=$HOME/.local/bin:$PATH
```

and then do
```
$ which npm
```

if you see something like

```
$ /home/chris/.local/bin/npm
```

then you just need to update your profile

```
$ echo "export PATH=$HOME/.local/bin:$PATH" >> ~/.profile
```


**Additions and suggestions welcome.**
