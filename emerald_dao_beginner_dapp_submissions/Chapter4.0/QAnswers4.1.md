Q1. Specifically it was trough the property 'user.addr'. In more detail, after a successful login, the 'user' variable is populated with all sort of info derived from this login. Since we are using a Flow based routine to do this and this login operation requires a wallet to do it (in web2 the usual was to use an email address. web3 seems to be evolving to use wallet addresses instead, since these are as unique as email addresses are.), it is expectable that the 'user' variable becomes populated with all sorts of wallet related info, including its address. The one thing I don't know at this point is if the 'user.addr' variable already exists but return NULL before a login or if it is created at runtime depending on the type of login used.

Q2. `fcl.authenticate` creates a login session for the user, if he/she did authenticate him/herself correctly. Essentially it populates the 'user' variable with all sorts of user-specific information derived from the login operation (like the wallet address mentioned above for example). `fcl.unauthenticate` reverts that, namely, closes that session by resetting the 'user' variable to a default (empty?) state.

Q3. In this particular case, the config was used to set the address of Flow testnet, thus pointing this module to the testnet instead, and also indicates where the code to perform the authentication should come from (I'm assuming that is where those Blocto screens, the buttons and such that appear in the pop up come from). As a curiosity, the testnet access node  (rest-testnet.onflow.org) resolves to the IP 104.18.6.53.
When the user clicks the 'Log In' button, the config file tells the  app where it should get all the remote code needed for that operation.

Q4. As it was mentioned before, by leaving the second argument of the function called inside the 'useEffect', that function is called every time the page is refreshed. Considering that the 'useEffect' subscribes the user every time this happens, the 'useEffect' in this case retains the user session, i.e., keeps the user logged in if he/she refreshes the page (this happens all the time in modern websites. Some throw you a pop up asking if you want to keep the logged session, others just keep it)

Q5. First we need to install the module, either locally in our app directory, or globally. To ensure that all is well, the project's package.json should have an "onflow" entry after this install. When not sure, navigate to the same directory where this file is and run the `npm install @onflow/fcl` command. After that, every module in that project can use the functions from it by importing it at the top of the module, either importing specific sub modules from the top one, as it happens in the config.js file:

```javascript
import { config } from "@onflow/fcl"
```
where only the 'config' sub module was loaded to use in that file, or more broadly, as it happens in the Nav.js file:
```javascript
import * as fcl from "@onflow/fcl"
```
In this case, we specify that we want to load everything in that module by indicating the '*' wildcard, and we want everything neatly bundled under a variable named 'fcl'. This is the variable that we need to use to access the module's functions as if it was a regular object. For example, the '@onflow/fcl' module as an 'authorize' function. To use it we do 'fcl.authorize()' because that function, as well as with a host of other things, is bundled inside the 'fcl' variable.

Q6. That instruction sets the current user for that page to the user indicated in the variable 'setUser'. Since this variable is updated after every successful login, the instruction indicated ensured that the session in use belongs to the logged user.