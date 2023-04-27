import EngineToolkitModels

extension SpecificAddress: Codable {
        // MARK: CodingKeys
        private enum CodingKeys: String, CodingKey {
                case address
        }

        // MARK: Codable
        public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(address, forKey: .address)
        }

        public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                let address = try container.decode(String.self, forKey: .address)
                


                try self.init(
                        address: container.decode(String.self, forKey: .address)
                )
        }

        public enum ConversionError: Error {
                case failedCreating(kind: SpecificAddressKind.Type)
                case addressKindMismatch(desired: SpecificAddressKind.Type, actual: SpecificAddressKind.Type)
        }
}

extension SpecificAddress {
        init(validatingAddress address: String) throws {
                let decodedType = try EngineToolkit().decodeAddressRequest(request: .init(address: address)).get().entityType
                if Kind.type.contains(decodedType) {
                        throw InternalDecodingFailure.addressDiscriminatorMismatch(expected: Kind.type, butGot: decodedType)
                }
                self.init(address: address)
        }
}
