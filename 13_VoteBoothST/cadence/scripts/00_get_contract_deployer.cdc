import "VoteBoothST"

access(all) fun main() {
    let deployerAddress: Address = VoteBoothST.getContractDeployer();

    log(
        "VoteBoothST contract is currently deployed at address: "
        .concat(deployerAddress.toString())
    )
}