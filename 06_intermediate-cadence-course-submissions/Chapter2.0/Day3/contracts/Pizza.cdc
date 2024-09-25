import IPizza from "./IPizza.cdc"

pub contract Pizza: IPizza {
    pub var size: UInt64
    pub var toppings: [String]

    pub fun addTopping(ingredient: String): Void {
        self.toppings.append(ingredient)
    }

    pub fun removeTopping(): String {
        return self.toppings.removeLast()
    }

    pub fun getToppings(): [String] {
        return self.toppings
    }

    pub fun setSize(size: UInt64): Void {
        self.size = size
    }

    pub fun getSize(): UInt64 {
        return self.size
    }

    init() {
        // Initiate a simple medium size Hawaian pizza
        self.size = 12
        self.toppings = ["TomatoSauce", "Cheese", "Ham", "Pineapple"]
    }
}