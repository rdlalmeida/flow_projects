import Head from 'next/head'
import styles from "../styles/Home.module.css"
import Nav from '../components/Nav.jsx'
import { useState, useEffect } from 'react';
import * as fcl from "@onflow/fcl"

export default function Home() {
  const [newGreeting, setNewGreeting] = useState('');
  // const [greeting, setGreeting] = useState('');
  const [txStatus, setTxStatus] = useState('Run Transaction');

  async function runTransaction() {
    const transactionId = await fcl.mutate({
      cadence: `
      import HelloWorld from 0xb7fb1e0ae6485cf6

      transaction(myNewGreeting: String) {
        prepare(signer: AuthAccount){

        }

        execute {
          HelloWorld.changeGreeting(newGreeting: myNewGreeting)
        }
      }
      `,
      args: (arg, t) => [
        arg(newGreeting, t.String)
      ],
      proposer: fcl.authz,
      payer: fcl.authz,
      authorizations: [fcl.authz],
      limit: 999
    })

    console.log("Here is the transactionId: " + transactionId);
    fcl.tx(transactionId).subscribe(res => {
      console.log(res);

      if (res.status === 0 || res.status === 1) {
        setTxStatus('Pending...');
      }
      else if (res.status === 2) {
        setTxStatus('Finalized...');
      }
      else if (res.status === 3) {
        setTxStatus('Executed...');
      }
      else if (res.status === 4) {
        setTxStatus('Sealed!');
        setTimeout(() => setTxStatus('Run Transaction'), 2000);
      }
    })

    await fcl.tx(transactionId).onceSealed();
    executeScript();
  }

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


  async function executeScript() {
    const response = await fcl.query({
      cadence: `
      import HelloWorld from 0xb7fb1e0ae6485cf6

      pub fun main(): String {
        return HelloWorld.greeting
      }
      `,
      args: (arg, t) => []
    })

    console.log("Response from our script: " + response)
    // setGreeting(response);
  }

  async function testTypes() {

    // Set the inputs to test
    const a = '25'
    const b = 'Does this work at all?'
    const c = '14.33'
    const d = '0xb7fb1e0ae6485cf6'
    const e = false
    const f = null
    const g = ['5', '4', '9']
    const h = [
      {key: 'Blocto', value: '0x82dd07b1bcafd968'},
      {key: 'Dapper', value: '0x37f3f5b3e0eaf6ca'}
    ]

    const inputArray = [a, b, c, d, e, f, g, h]

    const randomIndex = Math.floor(Math.random() * inputArray.length).toString();

    const response = await fcl.query({
      cadence: `
      pub fun main(
        a: Int,
        b: String,
        c: UFix64,
        d: Address,
        e: Bool,
        f: String?,
        g: [Int],
        h: {String: Address},
        index: Int
      ): AnyStruct {
        // Start by assembling every input into a single array
        let input_array: [AnyStruct] = [a, b, c, d, e, f, g, h]

        // Check the validity of the index provided:
        if (index < 0 || index >= input_array.length) {
          panic(
            "Invalid index provided: "
            .concat(index.toString())
            .concat(". Please provide an integer between 0 and ")
            .concat((input_array.length - 1).toString())
            .concat(" to continue")
            )
        }

        // Return the element whose index was provided as the last argument
        return input_array[index]
      }
      `,
      args: (arg, t) => [
        arg(a, t.Int),
        arg(b, t.String),
        arg(c, t.UFix64),
        arg(d, t.Address),
        arg(e, t.Bool),
        arg(f, t.Optional(t.String)),
        arg(g, t.Array(t.Int)),
        arg(h, t.Dictionary({key: t.String, value: t.Address})),
        arg(randomIndex, t.Int)
      ]
    })

    // Print out whatever was returned as a response
    console.log("The " + randomIndex.toString() + "-th element of the type array is " + response)
  }

  useEffect(() => {
    // executeScript()
    // readSimpleTest()
    testTypes()
  }, [])

  function printGoodbye() {
    console.log("Goodbye cruel, horrible world!")
  }


  /*
    <div className={styles.flex}>
      <button onClick={readSimpleTest}>Read Simple Test</button>
    </div>

    <main className={styles.main}>
      <h1 className={styles.title}>
        Welcome to my <a href="https://academy.ecdao.org" target="_blank">Emerald DApp!</a>
      </h1>
      <p>This is a DApp created by Ricardo, the Unlucky</p>

      <div className={styles.flex}>
        <button onClick={runTransaction}>Run Transaction</button>
        <input onChange={(e) => setNewGreeting(e.target.value)} placeholder="Hello, Idiots!" /> 
      </div>
      <div>
      <p> Current greeting is: {newGreeting} </p>
      </div>
      <div className={styles.flex}>
        <button onClick={updateNumber}>UpdateNumber</button>
        <input onChange={(f) => setNewNumber(f.target.value)} placeholder="New Number?" />
      </div>
    </main>
  */
  
  let html_page = (
  <div>
    <Head>
      <title>Emerald DApp</title>
      <meta name="description" content="Created by Ricardo, the Emerald Academy instructor!"/>
      <link rel="icon" href="https://i.imgur.com/hvNtbgD.png" />
    </Head>

    <Nav />

    <div className={styles.welcome}>
      <h1 className={styles.title}>
        Welcome to my <a href="https://academy.ecdao.org" target="_blank" rel="noreferrer">Emerald DApp!</a>
      </h1>
      <p>This is a DApp created by Ricardo Almeida, the unluckiest piece of shit in this freakin planet! (<i>ricardo.a#0803</i>).</p>
    </div>

    <main className={styles.main}>
      <p>{newGreeting}</p>
      <div className={styles.flex}>
        <input onChange={(e) => setNewGreeting(e.target.value)} placeholder="Hello, Idiots!" />
        <button onClick={runTransaction}>{txStatus}</button>
      </div>
    </main>

  </div>
  )
  
  return html_page
}