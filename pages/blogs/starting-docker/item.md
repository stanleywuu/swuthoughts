---
title: Starting Docker: Lessons learned from first week of using docker
---

So we have been looking into using containers for a while now, but that has mostly been my manager's job, because
*Who's got time for that?*

Until recently I got transferred to another project, where my new supervisor is **passionate**, and I mean **PASSIONATE** about containers.

He would proudly tell us how much containers speeds up his development, how he could check something in and it'll deploy in a few minutes. I on the other hand, while understand the benefits of docker, don't quite share his enthuisiasm.

We can do that, too, and without using containers for that matter. Although admittedly, it is a Pain in the butt to maintain.

But then he got me started on docker-compose.

### Holy mother of God, what can you do now?
* A lot of companies now offer docker images that you can host locally.
* From a user's point of view, I'm not sure whether this is easier:
  * We used to be able to do the same using an Installer on Windows, or shell scripts on Linux/Mac machines.
  * Now if we need to use a utility: docker run image {tool}, that's kinda cool, I guess.
* But in all honesty, being able to spin up a whole server, without configuring IIS, without opening firewalls is pretty great.

### Learning backwards is hard
* With so many years of experience googling a problem and finding a solution, I thought learning backwards wouldn't be so hard.
* docker is just like any other tool, right? I never know what the parameters to tar should be, a simple DuckDuckGo search would get me what I want. **WRONG**
* You actually do need to learn the concepts, maybe not in its entirety, especially when I started using *docker-compose* instead of *docker*
* It's easy to underestimate the complexity with docker when you look at what other people have done. It's very likely they are simply building upon an existing image, but getting there actually takes quite some time.

### Learn to use docker-compose early
* Before I wrote my own docker-compose file, my experience with docker had been the following:
  * docker build -t {name} .
  * docker run --{containername} {name}
  * Well, it didn't work, press up up and build again.
  * **What do you mean I can't use the same name?**
  * So because I'm a Windows user, I pull up Docker Desktop, delete the container from UI, run ```docker image prune``` **then** build.
  * and the process repeated over and over again
* It was totally worth making a docker-compose file, why?
* With ```docker-compose```, I can simply execute ```docker-compose up --build``` to rebuild the image.

### Gotchas with docker-compose
* Generally, if you can, use a Mac or Linux machine, there were so many times where I've done things and asked myself: "Did I get path wrong because...you know, Windows?" Once you are familiar with it enough, you can move back to Windows if you'd like. Me? I fought through it this whole week, I'm not about to change now.
* Use context if the Dockerfile resides in a subdirectory.
  * We are not mature enough in docker land yet, nobody feels confident enough to push their image up in a repository. So for now, we are building Dockerfile s locally in our folder
  * So our docker-compose file looks something like
```yaml
   service:
      build: .
      ports:
        - "8080:80"
```
  * And it didn't work, "files does not exist"....
  * It works when I use ```docker run``` on the image though, why?
  * The answer is actually ... of course **relative paths**
  * You can specify ```working_dir``` all you want, and it's not going to make a difference.
  * What you really need is [context](https://docs.docker.com/compose/compose-file/compose-file-v3/#build)

### Volumes are useful, but make sure you understand it first
* If you are reading this, I assume you are looking for quick ways to jump into docker, which means you probably know as little as volume as I started.
* Basically, volume allows you to update the contents of the container by editing the contents inside directly.
* It's like shared storage between your host and the container. For example, say I have a volume set up at ```C:\Docker\Test\``` for my web app, once my container gets built, its content will show up in that directory.
* Now I can edit my HTML pages on the volume without having to rebuild my docker. Pretty convenient, but there's a caveat.
* **Warning!** Do not use volume until you understand what it is
  * Once I learned how to set up volume (Persistent storage), I thought it was so cool and useful so I set it up in docker-compose, and went on building a compose file for a real project that we wish to containerize.
  * Everything works, I built the image, I can use docker-run. But every time I use docker-compose, it simply refuses to start the webserver.
  * **What the heck? I'm sure the files are copied over, it worked without using docker-compose. Why?**
  * No it's not because I have a docker ignore file, I didn't even know what that was at the time.
  * After a day of exploration, I figured out why. **volume**, I created the directory of my volume a.k.a ```C:\Docker\Test\``` manually, somehow its empty content is constantly being pushed on to the container. *Maybe if I pruned volumes before I recreated my images, things might have gone better*

### Learn how to use docker run -it, or docker-compose run sh
* Before learning about these commands, I was at a loss, how can I troubleshoot if I don't know what is going on inside? It was going to be purely an exercies in trial and error.
* Eventually I started looking at how to ssh into a container, *then* I came to a point where I started searching for how to interact with the container shell.
* The one thing I noticed is that help for docker is out there, but getting there is not as straight forward. You really have to use the right keyword. For example, **interactive** and **shell** were a game changer for me. And they brought a game changer in terms of troubleshooting my docker-compose.
* Using ```docker run --it {image}``` starts a new interactive container with the image, in there you can inspect the contents of your container.
* If you are using ```docker-compose```, that's ```docker-commpose run {service} sh``` (if you are using a Linux image that is)
* **Total**, **Game**, **Changer**
* My productivity shot right up after learning about this, everything becomes *solvable*

### A note for .net core developers
* When building your container, I would recommend starting off with the sdk images, they are a bit bulky, but it makes troubleshooting so much easier. You can always change it back to use the core images when you are done.
* For example, I could use wget inside my container to see whether a connection with the API server works.

### Once you get the hang of it, it won't be that hard
This has been my geniune experience with docker and docker compose this week. I still have a lot to learn, but I'm bored, and I feel like not playing video games tonight, and nobody reads this anyway. TADA! I did something productive today, yay!