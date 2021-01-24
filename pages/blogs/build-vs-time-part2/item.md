---
title: vs code Extension series: Let's build vstime - Part 2 
---
This is the second post of the series of [building vs code extensions](../build-vs-time) where I will go through the process of the creation of the extensions that I make for vs code.

There will be stories, there will be knowledge and there will be discussions. 

vstime

vstime is the my first **published** extension, it is a simple extension for keeping track of what you are working on and the time breakdown of each files you interact with inside of vscode.

See [vs-time](../vstime-a-vs-code-extension-to-keep-track){:target="_blank"} to see a short description.
Here is a quick demo of what it does
![](../../../../../../../../vstime/images/demo.gif)

Part 2 of the series will is about the main functionality of the extension: Time tracking.

I made the extension on one assumption:
*"This sounds like it would be easy, I could cook it up in one night"*

So, I started building the tracker.

Naively, I thought this was going to be the **only** thing I'd need to implement. Therefore, I named the file, very creatively.
"implementation.ts"

Here is my [First Commit](https://github.com/stanleywuu/vscode-timetracker/commit/2e4ddf74e998f299d46fc26ce91cd97597f9914b#diff-25a6634263c1b1f6fc4697a04e2b9904ea4b042a89af59dc93ec1f5d44848a26) in its full glory.

But we don't care about this,

I defined four commands
- "Start Tracking"
- "Stop Tracking"
- "Resume Tracking"
- "End Tracking"

For each of the commands,our implementation has to perform the following
- Track status of the timer
- Update time spent in each tab
- Keep logs updated for diagnostics
- Update the status item

Each of the four commands corresponds to its own command
- startTracker()
- pauseTracker()
- resumeTracker()
- stopTracker()
  
## startTracker
1. Ask user what a they are going to work on
2. Log start
3. Start the timer

```javascript
   async startTracker(){
        this.comment = await vscode.window.showInputBox({ prompt:'What are you working on?' } );
        this.logs.push(`started at : ${Date.now()}`);
        this.start();
    }
```
```this.start()``` is the method that kicks off a timer.
It sets the tracking state to be ```true```,
then we update the status Item so that when a user clicks on it it triggers the ```pause``` command.
Also start tracking time on the current tabl
Start timer, the timer is set up to refresh every second.

```javascript
  private start() {
    this.isTracking = true;
    this.trackCurrentFile();

    this.current.resume();
    this.statusItem.command = "vstime.pause";

    this.timerId = setInterval(() => {
      const now = Date.now();
      const total = this.current.update();
      this.statusItem.text = `${formatTime(total)}`;
    }, 1000);
  }

}
```

## A tengent on how changes are tracked
There are two items in play here ```current.resume()``` and ```trackCurrentFile()```
- ```current``` is an ```TrackerValue``` object used to track the time spent in the session
- ```trackCurrentFile``` is used to track the time spent in the current tab

  
```javascript
trackChanges(file: string) {
    if (!this.isTracking) {
      return;
    }

    const lastTracker =
      this.trackedFiles[this.currentFile] ?? new TrackerValue();
    // if deactivating, update lastTime.update
    // if activating, call resume
    this.logs.push(`stopped at ${Date.now()}`);
    lastTracker.update();
    this.trackedFiles[this.currentFile] = lastTracker;

    const tracker = this.trackedFiles[file] ?? new TrackerValue();
    this.trackedFiles[file] = tracker;

    this.logs.push(`working with ${file} at ${Date.now()}`);
    this.currentFile = file;
    tracker.resume();
  }
```

## Back to the high level tracker implementation

Resuming the timer and restarting the timer are essentially the same.

```javascript
    resumeTracker(){
        this.logs.push(`resumed at : ${Date.now()}`);
        this.start();
    }
```

Pausing was set up a little different resume, because I was stupid. I am only realizing this as I type up this blog.
It is not set up consistently as ```resumeTracker()```
pauseTracker() maintains the state of ```isTracking``` whereas the ```resumeTrcker()``` delegated that work to start()

```javascript
    pauseTracker(){
        this.isTracking = false;
        this.statusItem.command = 'vstime.resume';
        this.statusItem.text = 'Timer Paused';

        this.logs.push(`paused at : ${Date.now()}`);

        if (this.timerId) {
            clearInterval(this.timerId);
        }
    }
```

Stop tracking, stop the timer
- Ask for comments
- Update status
- Prepare the logs

Here is the implementation in its full glory.
  
```javascript
    async stopTracker(){
        this.isTracking = false;

        if (this.timerId){
            clearInterval(this.timerId);
        }

        const finalComment = await vscode.window.showInputBox({ prompt:'Thoughts, comments, notes' } );
        this.logs.push(`stopped at : ${Date.now()}`);

        this.statusItem.command = 'vstime.start';
        this.statusItem.text = 'Timer Off';
    }
```

## TrackerValue Object
The TrackerValue object is responsible for doing the actual tracking, there are only three operations in the class.
- update
  - Add the time that has been elasped to the total time recorded
- resume
  - Reume timer with the current time
- reset
  - Restart tracking


```javascript
export class TrackerValue{
    total: number;
    lastTrackedAt: number;

    constructor(){
        this.total = -1;
        this.lastTrackedAt = Date.now();
    }

    update() : number {
        const now = Date.now();
        const difference = now - this.lastTrackedAt;
        this.total += difference;
        this.lastTrackedAt = now;

        return this.total;
    }
    
    resume(){
        this.lastTrackedAt = Date.now();
    }

    reset(){
        this.total = -1;
        this.lastTrackedAt = -1;
    }
};
```

The above was how the tracking functionality was implemented... and here's how they are connected.
I create the status bar, pass it in to the tracker, and register the commands.

```javascript
function initializeTracker(context: vscode.ExtensionContext) : impl.Tracker{
    const statusBar = initializeStatusBar(context);
    const tracker = new impl.Tracker(statusBar);

    let trackStart = vscode.commands.registerCommand('vstime.start', ((p)=> {tracker.startTracker();}));
    let trackStop = vscode.commands.registerCommand('vstime.stop', (async ()=> {
        const results = await tracker.stopTracker();
        await impl.save(results);
        tracker.reset();
    }));

    let trackResume = vscode.commands.registerCommand('vstime.resume', (()=> {tracker.resumeTracker();}));
    let trackPause = vscode.commands.registerCommand('vstime.pause', (()=> {tracker.pauseTracker();}));
    
    context.subscriptions.push(trackStart);
    context.subscriptions.push(trackStop);
    context.subscriptions.push(trackResume);
    context.subscriptions.push(trackPause);

    context.subscriptions.push(vscode.window.onDidChangeActiveTextEditor((editor) => { 
        if (editor && editor === vscode.window.activeTextEditor){
        tracker.trackChanges(editor?.document.uri.path ?? 'Untitled');}
    }));

    return tracker;
}
```

## Conclusion
The vstime project was an extension that I saw value in making because work was trending to ask us to track time.
It was a good exercise in organizing javascript code, blog writing, maintianing and publishing a vscode extension.

Well worth it.