pub contract interface IPizza {
    pub var size: UInt64
    pub var toppings: [String]

    pub fun addTopping(ingredient: String): Void
    pub fun removeTopping(): String
    pub fun getToppings(): [String]

    pub fun setSize(size: UInt64): Void
    pub fun getSize(): UInt64
}
