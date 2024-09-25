import ApprovalVoting from "../contracts/ApprovalVoting.cdc"

/*
    Simple script that scans all the configured accounts and checks theirs storage for Ballots
*/

pub fun main(): Void {
    let emulatorAddresses: [Address] = [0xf8d6e0586b0a20c7, 0x01cf0e2f2f715450, 0x179b6b1cb6755e31, 0xf3fcd2c1a78f5eee, 0xe03daebed8ca0615]

    for address in emulatorAddresses {
        let ballotReference: &ApprovalVoting.Ballot? = getAccount(address).getCapability<&ApprovalVoting.Ballot>(ApprovalVoting.ballotPublic).borrow()

        if (ballotReference == nil) {
            log(
                "Account "
                .concat(address.toString())
                .concat(" does not have a ballot yet")
            )
        }
        else {
            log(
                "Account "
                .concat(address.toString())
                .concat(" contains one valid ballot already!")
            )
        }
    }
}