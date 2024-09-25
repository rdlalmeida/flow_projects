Q1.
Custom contract code for Chp3Day3.cdc:

```cadence
pub contract Chp3Day3 {
    pub var state: String
    pub var index: UInt64

    init() {
        self.state = "Chapter 3, Day 3"
        self.index = 1
    }

    pub fun changeState(newState: String) {
        self.state = newState
    }

    pub fun changeIndex(newIndex: UInt64) {
        self.index = newIndex
    }
}
```

Q2.

Code for Chp3Day3Checker.cdc:

```cadence
// import Chp3Day3 from "../contracts/Chp3Day3.cdc"
import Chp3Day3 from 0xb7fb1e0ae6485cf6

pub fun main(): String {
    return "Current state is "
        .concat(Chp3Day3.state)
        .concat(", current index is ")
        .concat(Chp3Day3.index.toString())
}
```
Result after
<code>flow scripts execute ../emerald-dapp/flow/cadence/scripts/Chp3Day3Checker.cdc --network testnet</code>

![image](https://user-images.githubusercontent.com/39467168/189541437-c8fc0186-9949-42c5-b5ca-25238157fde4.png)

Q3.

Code for Chp3Day3Changer.cdc:
```cadence
// import Chp3Day3 from "../contracts/Chp3Day3.cdc"
import Chp3Day3 from 0xb7fb1e0ae6485cf6

transaction(myNewState: String, myNewIndex: UInt64) {
    prepare(signer: AuthAccount) {
    
    }

    execute {
        Chp3Day3.changeState(newState: myNewState)
        Chp3Day3.changeIndex(newIndex: myNewIndex)
    }
}
```

Changing the variables:

![image](https://user-images.githubusercontent.com/39467168/189541760-0e8f7f6e-d3c1-4b70-8623-ed8342b74d1a.png)

Q4.

Running the script from Q2 again:

![image](https://user-images.githubusercontent.com/39467168/189541806-f6a3b5d0-7b5f-4644-9054-2ff0a6d7d4d6.png)

Q5.

Contract deployed under my testnet account at:
https://flow-view-source.com/testnet/account/0xb7fb1e0ae6485cf6/contract/Chp3Day3

![image](https://user-images.githubusercontent.com/39467168/189541871-9a8e0eb1-6817-446c-9410-ea061795d9c7.png)
