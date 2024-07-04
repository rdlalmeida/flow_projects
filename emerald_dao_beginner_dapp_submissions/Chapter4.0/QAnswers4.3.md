Q1. Code for the function that establishes a function call with several data types and retunrs a random element from the set:

```javascript
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
```

Output from this code:

![image](https://user-images.githubusercontent.com/39467168/190004482-067c6bff-c7a7-4786-90c7-5ce5d7daeb31.png)
