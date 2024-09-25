import ApprovalVoting from "../contracts/ApprovalVoting.cdc"

// This script allows anyone to read the tallied votes for each proposal

pub fun main() {
    // This one is simple: run a for loop through the proposals array and print out the number of votes in each entry

    var i: Int = 0

    while (i < ApprovalVoting.proposals.length) {
        var message: String = 
            "Proposal #"
            .concat(i.toString())
            .concat(": ")
            .concat(ApprovalVoting.proposals[i])
            .concat(" - ")

        if (ApprovalVoting.votes[i]! == nil) {
            message = message.concat("0")
        }
        else {
            message = message.concat(ApprovalVoting.votes[i]!.toString())
        }

        log(
            message.concat(" votes!")
        )
        i = i + 1
    }
}
 