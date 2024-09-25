* Q1.Contents of index.js:

```javascript
import Head from 'next/head'
import styles from "../styles/Home.module.css"
import Nav from '../components/Nav.jsx'
import { useState, useEffect } from 'react';
import * as fcl from "@onflow/fcl"

export default function Home() {
  const [newGreeting, setNewGreeting] = useState('');

  const [greeting, setGreeting] = useState('');

  function runTransaction() {
    console.log("Running transaction!");
    console.log("Hi there! The current Greeting is ".concat(newGreeting))
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

    // console.log("Response from out script: " + response)
    setGreeting(response);
  }

  useEffect(() => {
    executeScript()
  }, [])

  function printGoodbye() {
    console.log("Goodbye cruel, horrible world!")
  }

  return (
    <div>
      <Head>
        <title>Emerald DApp</title>
        <meta name="description" content="Created by Ricardo, the Emerald Academy instructor!"/>
        <link rel="icon" href="https://i.imgur.com/hvNtbgD.png" />
      </Head>

      <Nav />

      <main className={styles.main}>
        <h1 className={styles.title}>
          Welcome to my <a href="https://academy.ecdao.org" target="_blank">Emerald DApp!</a>
        </h1>
        <p>This is a DApp created by Ricardo, the Unlucky</p>

        <div className={styles.flex}>
          <button onClick={runTransaction}>Run Transaction</button>
          <input onChange={(e) => setNewGreeting(e.target.value)} placeholder="Hello, Idiots!" />
        </div>
        <p> {greeting} </p>
      </main>
    </div>
  )
}
```

Output:

![image](https://user-images.githubusercontent.com/39467168/189763095-4e7267aa-6f17-489a-8183-90cccd867141.png)

* Q2a. Function to read the SimpleTest number variable:

```javascript
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
Code for the button that runs the script:

```html
<div className={styles.flex}>
  <button onClick={readSimpleTest}>Read Simple Test</button>
</div>
```

Output:

![image](https://user-images.githubusercontent.com/39467168/189764581-3c19f233-ba31-46ef-8294-c797a0a10d55.png)

* Q2b.

This one is quite simple: replace the 'executeScript()' instruction for 'readSimpleTest()' in the 'useEffect' setup (check the image bellow) and voilá:

![image](https://user-images.githubusercontent.com/39467168/189765434-fbaf5a0f-9b70-4d2f-ad9f-6cbec3f64810.png)
