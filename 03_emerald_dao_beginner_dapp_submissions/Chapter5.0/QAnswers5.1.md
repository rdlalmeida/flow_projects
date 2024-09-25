Q1. According to the Flow documentation, once submitted a transactions can have the following status:
* Status code = 0 (Unknown): This is a fallout state that, hopefully, no transaction should end here if all goes well. But the Flow state machine does include this state, so the assumption is that it can be reached by a transaction at some point.
* Status code = 1 (Pending): The transaction is waiting for its parameters to be validated.
* Status code = 2 (Finalized): The transaction was deemed viable and can proceed for execution.
* Status code = 3 (Executed): All the logic within the transaction code was executed without any errors. But at this point its permanent effects in the blockchain aren't set yet.
* Status code = 4 (Sealed): The last state of a successful transaction. All the logic in it was correctly executed and the blockchain state has been changed accordingly too.
* Status code = 5 (Expired): If by some reason the transaction was not able to execute and remained in the nether, this state allows to signal invalid transactions.

Q2a. The `setTimeout` instruction takes two arguments. The first one is another instruction (function call, screen print, log write, etc) and the second in the amount of time the system has to wait to executed it, expressed in milliseconds. This instruction allows for delayed executions of other instructions.

Q2b. Changing the value of the 2nd argument should suffice, namely changing what already exists to:
```javascript
// Update the txStatus variable after 5 seconds have elapsed
setTimeout(() => setTxStatus('Run Transactions'), 5000)
```

Q3. The subscribe function allows us to connect the state change of an object (the submitted transaction in this case) to a variable (`res` in this case also) so that the variable gets updated whenever the object changes too. This allows for a more close following of a remote process by mirroring the state changes of a remote object into a local variable.

Q4. 

* 1. Changing the background to bright pink, because I like it when the eyes begin to burn after a second or two:

![image](https://user-images.githubusercontent.com/39467168/190481456-50e29ffb-b239-4710-ac54-b537e34e24e8.png)

* 2. Changing the font size in the button to the larger value that does not spill out of the button limits, because I don't like to wear spectacles:

![image](https://user-images.githubusercontent.com/39467168/190481973-07a3bd3e-c512-410e-ab83-f591b76f7b49.png)

* Changing the color of the welcome message to bright yellow to keep up with the Miami Vice theme that I have going on:

![image](https://user-images.githubusercontent.com/39467168/190482958-9e44aeb7-632e-484a-8061-850052488e3f.png)
