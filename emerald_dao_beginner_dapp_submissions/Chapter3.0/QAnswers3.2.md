Q1. The function `changeGreeting` changes the value of the `greeting` variable, therefore, the script is attempting to change the state of the blockchain. In order to do that you need to pay gas costs and that can only happen in a transaction.

Q2. The `AuthAccount` Resource contains all the relevant information from the Account that signs this transaction, namely, the account address, balance, even Capabilities and such. This is an important "quirk" of transactions: by default, we need to understand that whoever signs a transaction, that person is also authorizing the transaction code to access his/hers account data.

Q3. The main difference is that `AuthAccount` is only accessible from within the `prepare` phase. Whatever manipulations and computations that need data from the signer's account need to happen in this step.

Q4. 

![image](https://user-images.githubusercontent.com/39467168/189494461-58f72e4a-81d5-4fcb-9156-ef2085a985a8.png)

![image](https://user-images.githubusercontent.com/39467168/189494612-437e8031-23a7-4899-b576-c4d2a4ea34a3.png)
