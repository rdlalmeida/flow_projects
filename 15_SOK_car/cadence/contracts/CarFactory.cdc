import "Burner"

access(all) contract CarFactory {
    access(all) event CarCreated(carId: UInt64)
    access(all) event CarStarted(carId: UInt64)
    access(all) event CarStopped(carId: UInt64)
    access(all) event CarSold(carId: UInt64, newOwner: Address)
    access(all) event CarDestroyed(carId: UInt64)

    access(all) entitlement Admin

    access(all) resource Car: Burner.Burnable {
        access(all) let carId: UInt64
        access(all) let licence: String
        access(all) let buildDate: String
        access(all) let passengerCapacity: UInt8
        access(all) var color: String
        access(all) var running: Bool
        access(all) let power: UInt64
        access(all) let fuelType: UInt8
        access(account) var odometer: UInt64
        access(account) var price: UFix64
        access(account) var insurancePolicy: String

        access(account) fun startCar(): Void {
            if (!self.running) {
                self.running = true
            }
        }

        access(account) fun stopCar(): Void {
            if (self.running) {
                self.running = false
            }

        }

        access(contract) fun burnCallback() {

            emit CarDestroyed(carId: self.carId)
        }

        init(
            _licence: String, 
            _buildDate: String, 
            _passengerCapacity: UInt8,
            _color: String,
            _power: UInt64,
            _fuelType: UInt8,
            _price: UFix64,
            _insurancePolicy: String
            ) {
                self.carId = self.uuid
                self.licence = _licence
                self.buildDate = _buildDate
                self.passengerCapacity = _passengerCapacity
                self.color = _color
                self.running = false
                self.power = _power
                self.fuelType = _fuelType
                self.odometer = 0
                self.price = _price
                self.insurancePolicy = _insurancePolicy

        }
        
    }

    access(all) resource FactoryAdmin {
        access(all) fun createCar(
            newLicence: String,
            newBuildDate: String,
            newPassengerCapacity: UInt8,
            newColor: String,
            newPower: UInt64,
            newFuelType: UInt8,
            newPrice: UFix64,
            newInsurancePolicy: String
        ): @CarFactory.Car {
            let newCar: @CarFactory.Car <- create CarFactory.Car(
                _licence: newLicence,
                _buildDate: newBuildDate,
                _passengerCapacity: newPassengerCapacity,
                _color: newColor,
                _power: newPower,
                _fuelType: newFuelType,
                _price: newPrice,
                _insurancePolicy: newInsurancePolicy
            )

            emit CarCreated(carId: newCar.carId)

            return <- newCar
        }

        access(all) fun destroyCar(oldCar: @CarFactory.Car): Void {
            Burner.burn(<- oldCar)
        }
    }
}

// TODO: How to implement a sellCar function?