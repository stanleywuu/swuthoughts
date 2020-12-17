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

So the implementation had to do these four things, nothing too fancy
Ask myself what I am working on before I start tracking time.

Built up a string of array to log the current session.

```javascript
   async startTracker(){
        this.comment = await vscode.window.showInputBox({ prompt:'What are you working on?' } );
        this.logs.push(`started at : ${Date.now()}`);
        this.start();
    }
```

Both resume and start basically starts the timer
```javascript
    resumeTracker(){
        this.logs.push(`resumed at : ${Date.now()}`);
        this.start();
    }
```

I guess I forgot to mention I also built the statusItem :_) It's not important, we can get to that later

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
Ask for comments
Update status
Prepare the logs
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
        // log to file
        const values = Object.keys(this.trackedFiles).map((k) =>{
            return {key: path.parse(k).name, value: this.trackedFiles[k]};
        });

        const final = {
            comment: this.comment,
            total: this.current,
            breakdowns: values,
            logs : this.logs,
        };

        console.log(final);
    }
```

Glory of the implementation, current is an object that keeps track of the last updated time, so we can determine what the difference was and add on to our total.

```javascript
    private start() {
        this.isTracking = true;
        this.currentFile = vscode.window.activeTextEditor?.document.uri.path ?? '';

        this.current.resume();
        this.statusItem.command = 'vstime.pause';

        this.timerId = setInterval((() => {
            const now = Date.now();
            /////////////////////////////////////
            const total = this.current.update();
            /////////////////////////////////////
            this.statusItem.text = `${total / 1000} seconds`;
        }), 1000);
    }
```

It sounds like I lied, the bulk of the work wasn't in this file, in fact, it was in what I called a ```trackerValue```
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

Again, relatively simple. It does only one thing: Keep track of the difference in time. With the ability to start, update and reset.
Reading this code, I see that I might be off by a second. You must all be wondering: "why don't you start from 0? Why -1?"
You know what? That's a great question! I think I made a mistake :)

See kids? That's why you blog, you discover your mistakes, question your past decisions, and wonder where you have gone wrong.

Not too bad, but I didn't like how the isTracking flag is seems to live in different functions for no reason.
My functions had no consistency, why don't I have a private method for pausing and stopping for example.

It doesn't make sense that I do ```setInterval``` in stop and pause while startTimer simply delegates that work to the start() method.

I will not dive further into how I got to this state, but eventually I got to a state that I felt happy about.
The [First commit](https://github.com/stanleywuu/vscode-timetracker/commit/b55d41ef814776fc687ba20cdcff4e5b4afb932f#diff-b289dc7d8f7d450e9b8a58427eb9873e1d12be5ad8b03484f671f06c7e848892) after I corrected the filename.

```javascript
  async startTracker() {
    this.comment = await vscode.window.showInputBox({
      prompt: "What are you working on?",
    });
    this.reset();
    this.start();
    this.trackCurrentFile();
  }

  resumeTracker() {
    this.logs.push(`resumed at : ${Date.now()}`);
    const currentFile = vscode.window.activeTextEditor?.document.uri.path ?? 'Untitled';
    this.trackChanges(currentFile);
    this.start();
  }

  pauseTracker() {
    this.isTracking = false;
    this.statusItem.command = "vstime.resume";
    this.statusItem.text = "Timer Paused";

    this.logs.push(`paused at : ${Date.now()}`);

    this.stopTimer();
  }


  reset(){
      this.isTracking = false;
      this.current = new TrackerValue();
      this.trackedFiles = {};
  }

 async stopTracker(): Promise<TimeTrackingResultItem> {

    this.stopTimer();

    this.isTracking = false;
    const finalComment = await vscode.window.showInputBox({
      prompt: "Thoughts, comments, notes",
    });
    this.logs.push(`stopped at : ${Date.now()}`);

    this.statusItem.command = "vstime.start";
    this.statusItem.text = "Timer Off";
    // log to file
    const values = this.getBreakdownInfo();

    const final: TimeTrackingResultItem = {
      date: getToday().getTime(),
      comment: this.comment,
      notes: finalComment,
      total: this.current,
      breakdowns: values,
      logs: this.logs,
    };

    console.log(final);

    return final;
  }
  ```

Nice and simple.
Now I have introduced function to track changes among other things, it was easy to introduce per file tracks as user opens a new tab.

It's as simple as creating a Key value Map as such
```javascript
interface KeyValuePair {
  [key: string]: TrackerValue;
}
```

```javascript
export class Tracker {
  ...
  private trackedFiles: KeyValuePair;
  ...
  ...
}

```

Implementation of track changes is as simple as accessing the tracker from the map, and calling the ```update``` and ```resume``` methods.

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

Here is an overview of how I built the tracker, now... and here's how they are connected.
I create the status bar, pass it in to the tracker, and register the commands

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

It's interesting, my intention was to explain more about 