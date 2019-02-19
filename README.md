# RxStateManagment
A code lab for learning state management with RxSwift

# Background
I was inspired by Jake Wharton's talk on "Managing State with RxJava" https://jakewharton.com/the-state-of-managing-state-with-rxjava/.  If you haven't watched it, I recommend starting there.  Afterward, clone the repo and work through the code lab.

# Checkpoints
* _Checkpoint 1 - Managing state starting point_.
  * This is the starting point of the code lab:
    * We have a simple `CreateAccountViewController` that is presented when the user taps on the `Create Account` button.
    * Inside the implementation of the `CreateAccountViewController` you will find familiar Rx code that you'd might write.  In Jake Wharton's talk, he discusses the _so-called_ bad practices of *side effects* (aka. `.do(onNext()` and `leaving the monad`) that we typically write when we get started with Rx.
     * In the talk, he identifies several red lines:
       * In the `flatMap` we reach into the UI and get the text out of the two `UITextField`s.
       * Before and after the network calls, we use a `do(onNext())` to disable/enable the `createAccountButton` and to show/hide the `processingView`.
      * Let's see if we can improve this!


# Identify UI States

