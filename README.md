# RxStateManagment
A code lab for learning state management with RxSwift

# Background
I was inspired by Jake Wharton's talk on "Managing State with RxJava" https://jakewharton.com/the-state-of-managing-state-with-rxjava/.  If you haven't watched it, I recommend starting there.  Afterward, clone the repo and work through the code lab.

# Checkpoints
* _Checkpoint 1 - Managing state starting point_.
  * This is the starting point of the code lab:
  * We have a simple `CreateAccountViewController` that is presented when the user taps on the `Create Account` button.
  * Inside the implementation of the `CreateAccountViewController` you will find your familiar RxSwift code with the _so-called_ bad practices of *side effects* (aka. `.do(onNext()` and `leaving the monad`).
