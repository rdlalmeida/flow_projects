import FLOAT from 0xFLOAT

transaction(eventAccount: Address, eventId: UInt64) {
    let userCollectionRef: &FLOAT.Collection
    let floatEventRef: &FLOAT.FLOATEvent{FLOAT.FLOATEventPublic}
    let floatEventsRef: &FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}
    prepare(signer: AuthAccount) {
        self.userCollectionRef = signer.getCapability<&FLOAT.Collection>(FLOAT.FLOATCollectionPublicPath).borrow() ?? 
            panic("Account ".concat(signer.address.toString()).concat(" does not have a proper Collection set up yet!"))

        // Retrieve a reference for the Collection of Events
        self.floatEventsRef = getAccount(eventAccount).getCapability<&FLOAT.FLOATEvents{FLOAT.FLOATEventsPublic}>(FLOAT.FLOATEventsPublicPath).borrow() ??
            panic("Account ".concat(eventAccount.toString()).concat(" does not have any FLOAT Events configured yet!"))

        // And from this one a reference to the Event in question
        self.floatEventRef = self.floatEventsRef.borrowPublicEventRef(eventId: eventId) ??
            panic("FLOAT Event with id ".concat(eventId.toString()).concat(" does not exists in account ".concat(eventAccount.toString()).concat(" FLOAT Events Collection")))
    }

    execute {
        self.floatEventRef.claim(recipient: self.userCollectionRef, params: {})
    }
}