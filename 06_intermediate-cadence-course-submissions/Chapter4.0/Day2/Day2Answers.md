1. Using the same exact example as we did in the lesson, modify the code to allow the user to withdraw if it has been (submit a separate answer for each):
    a. 1 day

    ```cadence
    pub fun withdraw(): @FlowToken.Vault {
        pre {
            // 24h in a day, 60 minutes in an hour, 60 seconds in a minute
            getCurrentBlock().timestamp >= self.lastDeposited + 60*60*24: 
                "It has not been a day since you last deposited."
        }
        
        return <- vault.withdraw(amount: self.vault.balance) as! @FlowToken.Vault
    }
    ```

    b. 1 week

    ```cadence
    pub fun withdraw(): @FlowToken.Vault {
        pre {
            // 7 days in a week, 24h in a day, 60 minutes in an hour, 60 seconds in a minute
            getCurrentBlock().timestamp >= self.lastDeposited + 60*60*24*7: 
                "It has not been a week since you last deposited."
        }
        
        return <- vault.withdraw(amount: self.vault.balance) as! @FlowToken.Vault
    }
    ```

    c. 1 month

    ```cadence
    pub fun withdraw(): @FlowToken.Vault {
        pre {
            // Depends on the month, but lets round each month to 30 days, 24h in a day, 60 minutes in an hour, 60 seconds in a minute
            getCurrentBlock().timestamp >= self.lastDeposited + 60*60*24*30: 
                "It has not been a month since you last deposited."
        }
        
        return <- vault.withdraw(amount: self.vault.balance) as! @FlowToken.Vault
    }
    ```

    d. 1 year

    ```cadence
    pub fun withdraw(): @FlowToken.Vault {
        pre {
            // Again, in a normal, i.e, non-leap, there's 365 days in a year, 24h in a day, 60 minutes in an hour, 60 seconds in a minute
            getCurrentBlock().timestamp >= self.lastDeposited + 60*60*24*365: 
                "It has not been a year since you last deposited."
        }
        
        return <- vault.withdraw(amount: self.vault.balance) as! @FlowToken.Vault
    }
    ```

    e. 15 years, 8 months, 3 weeks, 1 day, 12 hours, 14 minutes, and 12 seconds (hahahahahhhahahahaha I'm so sorry)

    ```cadence
    pub fun withdraw(): @FlowToken.Vault {
        pre {
            // Its actually a matter of repeating the reasoning above, with some alterations to sum all elements reduced to seconds
            let minute: UFix64 = 60.0                   // Number of seconds in a minute
            let hour: UFix64 = minute*60                // Number of seconds in an hour
            let day: UFix64 = hour*24                   // Number of seconds in a day
            let week: UFix64 = day*7                    // Number of seconds in a week
            let month: UFix64 = day*30                  // Number of seconds in a 30 day month
            let year: UFix64 = day*365                  // Number of seconds in a non-leap year

            let waiting_time: UFix54 = (12 + 14*minute + 12*hour + day + 3*week + 15*year)

            getCurrentBlock().timestamp >= self.lastDeposited + waiting_time: 
                "You haven't suffered enough since you last deposited. You still need to wait ".concat((waiting_time - self.lastDeposited).toString()).concat(" seconds.")
        }
        
        return <- vault.withdraw(amount: self.vault.balance) as! @FlowToken.Vault
    }
    ```

2. How do you get the current unix timestamp in Cadence?

Use the instruction <code>getCurrentBlock().timestamp</code> to retrieve the number of seconds since January 1st 1970.

3. Is it possible to make a smart contract (on Flow) automatically execute code after a certain amount of time? Why or why not (using basic principles of smart contracts)?

As far as I've investigated, there isn't clear support from Flow in this regard, like a delegate Smart Contract call of some sort, which is understandable given how problem prone these types of calls tend to be. So, from the official stance from Flow, I'm inclined to say that no, it's not possible to automatically run a Smart Contract function after a certain elapsed time.
But one can do a bit of an hack in that regard. For example, lets consider a contract such as:

```cadence
pub contract DelayedContract {
    pub let elapsedTime: UFix64
    pub let deploymentTime: UFix64
    
    pub fun sayHello(): Void {
        log("Hello!")
    }

    init() {
        self.elapsedTime = <some_time_in_seconds>
        self.deploymentTime = getCurrentBlock().timestamp

        while(true) {
            if (getCurrentBlock().timestamp >= self.deploymentTime + self.elapsedTime) {
                self.sayHello()
                break
            }
            else {
                continue
            }
        }
    }
}
```

Theoretically, this contract implements an automatic execution after an elapsed time, though it is extremely inefficient and potentially requires a lot of gas (depending on the waiting time to configure) to achieve this effect. Essentially, once the contract is deployed, it gets "stuck" in a while loop in its init() function until the condition that allows it to get out of it is satisfied. This condition is a time based one, so, in a sense, we can delay the execution of a contract like this.
A more efficient way to achieve this is to use a frontend and a general purpose language, such as Python or Javascript, that does have support for these types of delayed calls, to implement a call to the contract using proper method and functions from these languages instead of stalling part of the Flow blockchain in a pointless waiting loop.