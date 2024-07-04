/*
    Simple contract interface that defines a bunch of Resource Interfaces itself
*/
pub contract interface ResourceInterface{

    pub resource interface ResourceInterface01 {
        pub var message01: String
        pub var index01: Int

        pub fun changeMessage(newMessage: String): Void {
            post{
                before(self.message01) != self.message01: "The inner message was not changed!" 
            }
        }

        pub fun getMessage(): String

        pub fun changeIndex(newIndex: Int): Void {
            pre {
                newIndex > 0: "Please use positive values only"
            }

            post{
                before(self.index01) != self.index01: "The index remained unchanged!"
            }
        }

        pub fun getIndex(): Int

    }

    pub resource interface ResourceInterface02 {
        pub var flag01: Bool
        pub var quantity01: UFix64

        pub fun changeFlag(newFlag:Bool): Void {
            post{
                before(self.flag01) != self.flag01
            }
        }

        pub fun getFlag(): Bool

        pub fun changeQuantity(newQuantity: UFix64): Void{
            pre{
                newQuantity > 0.0: "Please use a positive quantity!"
            }

            post {
                before(self.quantity01) != self.quantity01: "The quantity remains unchanged"
            }
        }

        pub fun getQuantity(): UFix64
    }
}