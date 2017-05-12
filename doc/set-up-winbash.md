# **Experimental** : Set up GDK on Windows 10 Bash

## Setting up GDK on WSL (Linux Bash on Windows, Ubuntu 16.04 Base)

This is a step-by-step guide on how to get the GDK working under the current `Windows 10 Bash (Creators Update / April 2017)`. Due to the overlapping of directories between Windows and the Linux subsystem, you will need a little bit of a workaround to get it working, so that you can also edit files from Window but let it run under the Linux subsystem. If you would install it only in the `mnt` directory you would run into permission errors (especially with sockets).

1. Create a non root User or use an existing one

2. Prepare your machine based on this [guide for WSL](./prepare.md#experimental-windows-10-using-the-wsl-windows-subsystem-for-linux) 

3. Install GDK normally in the users home directory (~) with [gdk install](./set-up-gdk.md)

4. Run it with `gdk run` (Can take quite a while until it starts, refresh multiple times in browser 'localhost:3000') , after some time (~30 minutes) it will come up and show the `users/sign_in` page (couple of 502 / EOF errors before it starts correctly, restarting the whole machine also helps)

5. So now you should have a fully running GDK instance , try it out by logging in on [http://localhost:3000](http://localhost:3000) and browse. Only problem is you can’t really edit those files from the Windows machine (permission problems , etc. MS even states don’t edit Linux files with Windows applications)

6. What we will do is now do a second installation in your `/mnt/…` directory which is setup with your Windows hard drive. So I will create a directory on `C:/` with the name `tzwsl` (as an example)

7. Run in your bash `cd /mnt/c/tzwsl`

8. Run here again `gdk init`

9. Change to the created directory `cd gitlab-development-kit`

10. Run `gdk install`

11. Rund `gdk run` -> Now you will get multiple errors as WSL has a problem to create .socket files in mnt due to permission problems . Solution reconfigure GDK to use the directory in `/home/…` for creating the sockets

12. **./Procfile** changes :

    1. Get Redis running : 
Change in **./Procfile** the line :   
`redis: exec redis-server /mnt/c/tzwsl/gitlab-development-kit/redis/redis.conf`  
To the path of your /home installation  
`redis: exec redis-server /home/tz/gitlab-development-kit/redis/redis.conf`

    2. Get Postgres Running : 
Change that line  
`postgresql: exec support/postgresql-signal-wrapper /usr/lib/postgresql/9.5/bin/postgres -D /mnt/c/tzwsl/gitlab-development-kit/postgresql/data -k /mnt/c/tzwsl/gitlab-development-kit/postgresql -h ''`  
Again pointing at your /home/ installation  
`postgresql: exec support/postgresql-signal-wrapper /usr/lib/postgresql/9.5/bin/postgres -D /home/tz/gitlab-development-kit/postgresql/data -k /home/tz/gitlab-development-kit/postgresql -h ''`

    3. Point gitlab-workhorse to your home directory (only for socket) :   
Change :   
`gitlab-workhorse: exec /usr/bin/env PATH="/mnt/c/tzwsl/gitlab-development-kit/gitlab-workhorse/bin:$PATH" gitlab-workhorse -authSocket /mnt/c/tzwsl/gitlab-development-kit/gitlab.socket -listenAddr $host:$port -documentRoot /mnt/c/tzwsl/gitlab-development-kit/gitlab/public -developmentMode -secretPath /mnt/c/tzwsl/gitlab-development-kit/gitlab/.gitlab_workhorse_secret -config /mnt/c/tzwsl/gitlab-development-kit/gitlab-workhorse/config.toml`  
To :   
`gitlab-workhorse: exec /usr/bin/env PATH="/mnt/c/tzwsl/gitlab-development-kit/gitlab-workhorse/bin:$PATH" gitlab-workhorse -authSocket /home/tz/gitlab-development-kit/gitlab.socket -listenAddr $host:$port -documentRoot /mnt/c/tzwsl/gitlab-development-kit/gitlab/public -developmentMode -secretPath /mnt/c/tzwsl/gitlab-development-kit/gitlab/.gitlab_workhorse_secret -config /mnt/c/tzwsl/gitlab-development-kit/gitlab-workhorse/config.toml`

13. Run `gdk install` again, then it finished for me also with cloning gitaly, etc.

14. Configure gitaly (if you retry gdk run after this , it shouldn’t stop anymore with gitaly problems) :   
Go to **/gitaly/config.toml** , change from :   
`socket_path = "/mnt/c/tzwsl/gitlab-development-kit/gitaly.socket"`  
To Using Sockets (-> overrides the socket creation problem)  
`socket_path = ""`  
`listen_addr = "localhost:1234"`

15. Get the Rails Application working :   
Change in **\gitlab\config\unicorn.rb** the configuration :   
`listen '/mnt/c/tzwsl/gitlab-development-kit/gitlab.socket'`  
To   
`listen '/home/tz/gitlab-development-kit/gitlab.socket'`

16. Change the Redis.socket Path in **/gitlab/config/resque.yml** :   
`development: unix:/mnt/c/tzwsl/gitlab-development-kit/redis/redis.socket`  
`test: unix:/mnt/c/tzwsl/gitlab-development-kit/redis/redis.socket`  
To   
`development: unix:/home/tz/gitlab-development-kit/redis/redis.socket`  
`test: unix:/home/tz/gitlab-development-kit/redis/redis.socket`  

17. Fix the GItlab Workhorse Config to the new Redis Path :   
Change in **/gitlab-workhorse/config.toml** the line :   
`URL = "unix:///mnt/c/tzwsl/gitlab-development-kit/redis/redis.socket"`  
To the /home Path :   
`URL = "unix:///home/tz/gitlab-development-kit/redis/redis.socket"`  

18. Update the Database Socket in **/gitlab/config/database.yml** :   
CHange the 2 host paths :   
`host: /mnt/c/tzwsl/gitlab-development-kit/postgresql`  
To using your home path :   
`host: /home/tz/gitlab-development-kit/postgresql`

19. Update the Path to the example repositories (somehow it is not possible to pull them in the /mnt/ directory with the default installation) :   
Go to the **/gitlab/config/gitlab.yml** and change :   
`path: /mnt/c/tzwsl/gitlab-development-kit/repositories/`  
To   
`path: /home/tz/gitlab-development-kit/repositories/`  
Also Update the gitaly url in the line below from :   
`gitaly_address: unix:/mnt/c/tzwsl/gitlab-development-kit/gitaly.socket`  
To the TCP Address :   
`gitaly_address: tcp://localhost:1234`

20. Run it again `gdk run`

21. You should have now a GDK instance running on `localhost:3000` in your browser which is taking the Source files from the `/mnt/` installation but simply saves some of the needed connection parts in the `/home/` installation
