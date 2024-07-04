import { config } from "@onflow/fcl"

config()
    .put("accessNode.api", "https://rest-testnet.onflow.org")
    .put("discovery.wallet", "https://fcl-discovery.onflow.org/testnet/authn/")
    .put("app.detail.title", "Noobs to Flowstars DApp")
    .put("app.detail.icon", "https://i.postimg.cc/44bH00zL/noobs2flowstars-logo.png")
    .put("0xShapes", "0xb7fb1e0ae6485cf6")
    .put("0xFLOAT", "0x0afe396ebc8eee65")
    .put("0xFlowToken", "0x7e60df042a9c0868")
    .put("0xFungibleToken", "0x9a0766d93b6608b7")