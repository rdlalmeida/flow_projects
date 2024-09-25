Q1. Javascript code to define and deploy the transaction:

```javascript
// Set the variable to use for the update to updated on any change in the input field
const [newNumber, setNewNumber] = useState('')

async function updateNumber() {
  const transactionId = await fcl.mutate({
    cadence: `
    import SimpleTest from 0x6c0d53c676256e8c

    transaction(myNewNumber: Int) {
      prepare (signer: AuthAccount) {

      }

      execute {
        // Run the updateNumber routing with the value currently set in newNumber (passed as argument bellow)
        SimpleTest.updateNumber(newNumber: myNewNumber)
      }
    }
    `,
    args: (arg, t) => [
      arg(newNumber, t.Int)
    ],
    proposer: fcl.authz,
    payer: fcl.authz,
    authorizations: [fcl.authz],
    limit: 999
  })

  // Inform about the tx id attributed to this operation
  console.log("Transaction submitted with ID: " + transactionId)

  // Wait for the confirmation from the transaction
  await fcl.tx(transactionId).onceSealed();

  // Run the script to read the new number in the contract
  readSimpleTest()
}

async function readSimpleTest() {
  const response = await fcl.query({
    cadence: `
    import SimpleTest from 0x6c0d53c676256e8c

    // The script returns an Int but I'm setting the script to return a String on purpose
    pub fun main(): String {
      return "Got this from the SimpleTest contract: ".concat(SimpleTest.number.toString())
    }
    `,
    args: (arg, t) => []
  })

  // Output the script results the console:
  console.log(response)
}
```

HTML code to define the button and the input field:

```html
    <div className={styles.flex}>
      <button onClick={updateNumber}>UpdateNumber</button>
      <input onChange={(f) => setNewNumber(f.target.value)} placeholder="New Number?" />
    </div>
```

Result output:

![image](https://user-images.githubusercontent.com/39467168/190015470-f7f62cb3-7ee1-4664-a884-2509b5499779.png)

And on Flow Block explorer:

![image](https://user-images.githubusercontent.com/39467168/190015651-28ef3334-4271-4eca-bce5-535e653d0f2f.png)
