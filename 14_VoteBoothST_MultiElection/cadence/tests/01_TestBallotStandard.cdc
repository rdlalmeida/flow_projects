import Test
import BlockchainHelpers
import "BallotStandard"

access(all) let deployer: Test.TestAccount = Test.getAccount(0x0000000000000008)
access(all) let account01: Test.TestAccount = Test.createAccount()
access(all) let account02: Test.TestAccount = Test.createAccount()
access(all) let account03: Test.TestAccount = Test.createAccount()
access(all) let account04: Test.TestAccount = Test.createAccount()
access(all) let account05: Test.TestAccount = Test.createAccount()

access(all) let accounts: [Test.TestAccount] = [account01, account02, account03, account04, account05]

access(all) let addresses: [Address] = [account01.address, account02.address, account03.address, account04.address, account05.address]

// CUSTOM EVENT TYPES
access(all) let BallotBurnedEventType: Type = Type<BallotStandard.BallotBurned>()