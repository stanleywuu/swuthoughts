---
title: Dabbling into the world of VS Code Extension
---
I've always wanted to make games since highschool days, and my friend was all "Why don't you make a mod?"
To which, I would dismiss with a sneer: "Mods are for weaklings."

Inevitably, I was not able to make anything worthwhile in the 10 something years that has passed.

Funnily enough, I discovered VS code extensions not too long ago, and I really enjoy it for the following reason:
1. It uses Javascript, for someone who does not use Javascript for a living, it is refreshing to do all my development inside VS Code. Which, despite it being an Electron App, is still a lot lighter than Visual Studio.
2. It's easy to get started. Yeoman, and npm, that that's all the dependencies needed.
3. The documentation for VS Code API is actually pretty decent. Literally the one thing that convinced me to do it was the documentation. It didn't look too hard.
* [Getting Started](https://code.visualstudio.com/api/get-started/your-first-extension)
* [Extension Samples](https://code.visualstudio.com/api/extension-guides/overview) grouped by the major exensibility tasks available.
4. Reading actual implementations of VS code extensions on github makes me feel like a pro
5. Great way to customize VS Code for yourself
6. The syntax is very clean and well-isolated
* All aspects of the extensions are broken up
7. Easy to Debug, simply press F5 and you are good to go

My favourite part about this all
* This is so cool, this is absolutely so cool!
* I can use VS code, press F5 to start debugging the extension I'm working on
* On the newly opened window being debugged, guess what?
  * **I can open another Extension and work on that!**
  * **Press F5, BOOM! I can debug that, too! This is the coolest!**

So here we go, I will be documenting my journey on this blog.