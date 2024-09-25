/*
    Transaction to create a Float Event. This event should correspond to a learning event for whose the FLOAT NFTs minted should be used as proof-of-conclusion,
    as well as getting a Shape upgraded.
    These events are creating using a FLOATEvents Collection that was created and linked to the Private Storage during the Shapes.cdc contract initialization
    The inputs for this transaction are the details of the Event to create and store in the corresponding FLOAT Events Collection, namely:
        name: String - The name of the event
        description: String -  Description of the event
        image: String - A String with the image encoded in base64 (assumed)
        url: String - URL of the event
        initialGroups: [String] - An array with the names of the groups to which the event belongs. For example, an Introduction event, abstracted as a FLOATEvent, can
            belong to several organizations that which to mint FLOATs for users to prove their attendance to that particular event.
            NOTE: The group must exist before attempting to create an Event under it. Use the createGroup transaction
        verifiers: [{IVerifier}] - An array of resources that follow the IVerifier interface, which is used to implement verifiable actions such as a time window to claim
            FLOATs in the Event, passwords, etc. Check the ../../float/src/cadence/float/FLOATVerifiers.cdc contract for details
        extraMetadata: {String: AnyStruct} - Any extra metadata to add to the Event.

    For simplicity, we assume that FLOATs for the events are can be claimed (claimable = true) and non-transferable (transferable = false) by default
*/

import FLOAT from "../../float/src/cadence/float/FLOAT.cdc"
import Shapes from "../contracts/Shapes.cdc"

transaction() {
    let floatEvents: &FLOAT.FLOATEvents
    
    prepare(signer: AuthAccount) {
        // Begin by loading the FloatEvents resource reference from private storage
        self.floatEvents = signer.getCapability<&FLOAT.FLOATEvents>(FLOAT.FLOATEventsPublicPath).borrow() ??
            panic("Account ".concat(signer.address.toString()).concat(" does not have a proper FLOATEvents collections set yet!"))

    }

    execute {
        // Create 5 Events into the FLOAT Events, one per learning level
        let eventNames: [String] = [
            "1.SuperEasy", 
            "2.Easy", 
            "3.Normal", 
            "4.Hard", 
            "5.Super Hard"]
        
        let eventDescriptions: [String] = [
            "Beginner learninglevel",
            "Intermediate learning level",
            "Entusiast learning level",
            "Professional learning level",
            "Flow Guru"
        ]

        let eventImages: [String] = [
            "https://ipfs.io/ipfs/QmVzNybHoGojH6t8GdcVSYgs7TvPGYP8LfEFPVYTGsW4W5?filename=n2f_l1.png",
            "https://ipfs.io/ipfs/QmRq47PLjsRHrRCEdTHMgXVLb4BKgekE7ZUjtAJaBxuTbG?filename=n2f_l2.png",
            "https://ipfs.io/ipfs/QmPLJH18WBavPDJ1BhTVWZfyH9HaT2NEAakrUeKMv14VTQ?filename=n2f_l3.png",
            "https://ipfs.io/ipfs/Qmepp9hpMdYMKSsk49My8HtiwjqYiHKaCWtfwGv4PuFRDD?filename=n2f_l4.png",
            "https://ipfs.io/ipfs/QmSdr6bjJxurvB8Visjr9Fxv6rQA8cYc13FnR9ot3t628h?filename=n2f_l5.png"
        ]

        var i: Int = 0

        while(i < eventNames.length) {
            // Create the events. NOTE: By some reason, providing the initialGroups as [groupName] does not work. We had much time to debug why thus is
            // but it turns out that if only one group exists in the FloatEvents, any FLOAT created under any of these events is associated to it
            let eventId: UInt64 = self.floatEvents.createEvent(
                claimable: true,
                description: eventDescriptions[i],
                image: eventImages[i],
                name: eventNames[i],
                transferrable: false,
                url: "www.noobs2flowstars.io",
                verifiers: [],
                {},
                initialGroups: []
            )

            // There's no need to emit an Event here since the FLOAT contract already does this

            i = i + 1
        }
    }
}