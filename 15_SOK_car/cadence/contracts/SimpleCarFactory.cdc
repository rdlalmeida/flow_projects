access(all) contract SimpleCarFactory {
    access(all) let garageStoragePath: StoragePath
    access(all) let garagePublicPath: PublicPath
    access(all) let factoryAdminStoragePath: StoragePath
    access(all) let factoryAdminPublicPath: PublicPath

    access(all) entitlement Admin

    access(all) event CarCreated(_carId: UInt64, _carOwner: Address, _licencePlate: String)
    access(all) event CarStarted(_carId: UInt64, _carOwner: Address, _licencePlate: String)
    access(all) event CarStopped(_carId: UInt64, _carOwner: Address, _licencePlate: String)
    access(all) event CarDestroyed(_carId: UInt64, _carOwner: Address, _licencePlate: String)

    access(all) resource Car {
        access(all) let carId: UInt64
        access(all) let color: String
        access(all) let licencePlate: String
        access(all) var running: Bool
        access(account) var insurancePolicy: String

        init(_color: String, _licencePlate: String, _insurancePolicy: String) {
            self.carId = self.uuid
            self.color = _color
            self.licencePlate = _licencePlate
            self.running = false
            self.insurancePolicy = _insurancePolicy
        }

        access(account) fun starCar(): Void {
            if (!self.running) {
                self.running = true
            }

            emit CarStarted(_carId: self.carId, _carOwner: self.owner!.address, _licencePlate: self.licencePlate)
        }

        access(account) fun stopCar(): Void {
            if (self.running) {
                self.running = false
            }

            emit CarStopped(_carId: self.carId, _carOwner: self.owner!.address, _licencePlate: self.licencePlate)
        }

        access(all) fun isCarRunning(): Bool {
            return self.running
        }
    }

    access(all) resource Garage {
        access(account) var storedCars: @{UInt64: SimpleCarFactory.Car}

        init () {
            self.storedCars <- {}
        }

        access(all) fun storeCar(carToStore: @SimpleCarFactory.Car): Void {
            let garageSlot: @AnyResource? <- self.storedCars[carToStore.carId] <- carToStore

            destroy garageSlot
        }

        access(account) fun getCar(carId: UInt64): @SimpleCarFactory.Car? {
            let storedCar: @SimpleCarFactory.Car? <- self.storedCars.remove(key: carId)
            return <- storedCar
        }

        access(all) fun destroyCar(oldCarId: UInt64): Void {
            // Grab the car to be destroyed from the garage collection, if it exists. Panic if not
            let carToDestroy: @SimpleCarFactory.Car <- self.storedCars.remove(key: oldCarId) ??
            panic(
                "The garage from account "
                .concat(self.owner!.address.toString())
                .concat(" does not have any cars with ID ")
                .concat(oldCarId.toString())
            )

            // The car to be destroyed exists in this garage and it was remove from the internal storage dictionary
            let oldCarOwner: Address = self.owner!.address
            let oldLicencePlate: String = carToDestroy.licencePlate

            // Destroy the car
            destroy carToDestroy

            // Finish with the proper event emit
            emit CarDestroyed(_carId: oldCarId, _carOwner: oldCarOwner, _licencePlate: oldLicencePlate)
        }
    }

    access(all) resource FactoryAdmin {
        access(Admin) fun createCar(
            newLicencePlate: String,
            newColor: String,
            newInsurancePolicy: String,
            newCarOwner: Address
            ): Void {
                // Create the car only if the owner provided has a valid Garage already set in his/her account to store the new Car
                // Check if the owner account is properly set
                let ownerAccount: &Account = getAccount(newCarOwner);
                let ownerGarageRef: &SimpleCarFactory.Garage = ownerAccount.capabilities.borrow<&SimpleCarFactory.Garage>(SimpleCarFactory.garagePublicPath) ??
                panic(
                    "Unable to retrieve a valid &SimpleCarFactory.Garage for account "
                    .concat(newCarOwner.toString())
                    .concat(". Cannot continue!")
                )

                // The newCarOwner has a valid Garage to store the new car into. Create the Car

                let newCar: @SimpleCarFactory.Car <- create SimpleCarFactory.Car(
                    _color: newColor,
                    _licencePlate: newLicencePlate,
                    _insurancePolicy: newInsurancePolicy
                )

                // Emit the CarCreated event
                emit CarCreated(_carId: newCar.carId, _carOwner: newCarOwner, _licencePlate: newLicencePlate)

                // Store the in the newCarOwner's Garage
                ownerGarageRef.storeCar(carToStore: <- newCar)
            }
    }

    init() {
        self.garageStoragePath = /storage/Garage
        self.garagePublicPath = /public/Garage
        self.factoryAdminStoragePath = /storage/FactoryAdmin
        self.factoryAdminPublicPath = /public/FactoryAdmin

        let oldFactoryAdmin: @AnyResource? <- self.account.storage.load<@AnyResource?>(from: self.factoryAdminStoragePath)

        destroy oldFactoryAdmin

        let oldFactoryAdminCap: Capability? = self.account.capabilities.unpublish(SimpleCarFactory.factoryAdminPublicPath)

        let newFactoryAdmin: @SimpleCarFactory.FactoryAdmin <- create SimpleCarFactory.FactoryAdmin()

        self.account.storage.save(<- newFactoryAdmin, to: SimpleCarFactory.factoryAdminStoragePath)

        let newFactoryAdminCap: Capability<&SimpleCarFactory.FactoryAdmin> = self.account.capabilities.storage.issue<&SimpleCarFactory.FactoryAdmin>(SimpleCarFactory.factoryAdminStoragePath)

        self.account.capabilities.publish(newFactoryAdminCap, at: SimpleCarFactory.factoryAdminPublicPath)
    }
}