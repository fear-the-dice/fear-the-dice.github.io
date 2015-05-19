#Lets Kill Things
A tool for helping manage combat in a turn based environment. Allowing DM's/GM's to control stats such as AC, HP, and damage taken for a group.

Below is a bit of general information for starting and running Lets Kill Things. Further information such as our todo list of features, bugs, and the tools we use can be found in the [wiki](https://github.com/obihann/lets-kill-things/wiki).

##Table of Contents
* [Getting Started](#getting-stated)
* [Wiki](https://github.com/obihann/lets-kill-things/wiki)
* [License](#license)

##Getting Started
Below is our getting started guide broken down by tool. In addition to this we have grouped the infomation together based on server, which you can access here:

* [API](/api)       - Drakov API server
* [Web](/web)       - Frontent HTTP server
* [Socket](/socket) - Socket.io server

###Node
We use Node for a lot of things from build tools to our socket server. To get this setup you will have to run the following commands.

* **Build tools:**
        
    ```
    $ cd web
    $ npm install
    ```

* **Socket server:**

    ```
    $ cd socket
    $ npm install
    ```

###Bower
We use Bower to manage packages such as jQuery and Backbone.

If you haven't used [Bower](http://bower.io/) before, be sure to check out the documentation, as it explains exactly what it does, and all its cool features. You can install Bower with the following command:

* **Installation:** 
    
    ```
    $ cd web
    $ npm install -g bower
    ```

* **Use:**
    > Once you have Bower installed you can run the following command in the "public" folder to setup all the requirements for this project:

    ```
    $ cd web
    $ bower install
    ```

###Grunt
We use Grunt to compile source, and also watch folders during development.
If you haven't used [Grunt](http://gruntjs.com/) before, be sure to check out the [Getting Started](http://gruntjs.com/getting-started) guide. You can install Grunt with the following command:

* **Installation:**

    ```
    $ npm install -g grunt-cli 
    ```

* **Use:**

    > Once you have Grunt installed you can run the following command to build the site (note grunt will automatically build into the "public" folder, as specificed in "Gruntfile.js"):

    ``` 
    $ cd web
    $ grunt 
    ```

###Drakov
We currently use a mock API server (Drakov), whhich reads in [API Blueprint](https://apiblueprint.org/) to generate a mock server.

* **Installation:**

    ```
    $ npm install -g drakov
    ```

* **Use:**

    ```
    $ cd api
    $ drakov -f api/server.MD
    ```

###Supervisor
Supervisor manages our various processes for us. If you don't already have it installed you can do so with the Python tool easy_install:

* **Installation: **

    ```
    $ easy_install supervisor
    ```

* **Setup:**

    > From your project folter, you are going to have to create a few folders for supervisor to use:

    ```
    $ mkdir logs
    $ mkdir tmp
    ```

* **Use:**
    > Once you have it installed you can go ahead and run supervisor, then feed it some commands:

    ```
    $ sudo supervisord -c supervisor/supervisord.conf
    $ supervisorctl
    api                     STOPPED   Not started
    web                     STOPPED   Not started
    socket                  STOPPED   Not started
    supervisor> start api
    api: started
    supervisor> start socket
    socket: started
    supervisor> start web
    web: started
    supervisor>
    ```

##License
This tool is protected by the [GNU General Public License v2](http://www.gnu.org/licenses/gpl-2.0.html).

Copyright [Jeffrey Hann](http://jeffreyhann.ca/) 2015
