import Foundation

public extension Profile {
    struct Account: Equatable {
        public let address: Address
        public let name: String?
        
        public init(
            address: Address,
            name: String? = nil
        ) {
            self.address = address
            self.name = name
        }
    }
}

public extension Profile.Account {
    typealias Address = String
}
