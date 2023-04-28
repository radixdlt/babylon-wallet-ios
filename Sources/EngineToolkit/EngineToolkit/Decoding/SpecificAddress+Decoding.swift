import EngineToolkitModels

// extension SpecificAddress: Codable {
//        // MARK: CodingKeys
//        private enum CodingKeys: String, CodingKey {
//                case address
//        }
//
//        // MARK: Codable
//        public func encode(to encoder: Encoder) throws {
//                var container = encoder.container(keyedBy: CodingKeys.self)
//                try container.encode(address, forKey: .address)
//        }
//
//        public init(from decoder: Decoder) throws {
//                let container = try decoder.container(keyedBy: CodingKeys.self)
//                try self.init(
//                        validatingAddress: container.decode(String.self, forKey: .address)
//                )
//        }
//
//        public enum ConversionError: Error {
//                case failedCreating(kind: SpecificAddressKind.Type)
//                case addressKindMismatch(desired: SpecificAddressKind.Type, actual: SpecificAddressKind.Type)
//        }
// }
//
// extension SpecificAddress {
//        public init(validatingAddress address: String) throws {
//                let decodedKind = try EngineToolkit().decodeAddressRequest(request: .init(address: address)).get().entityType
//                guard Kind.addressSpace.contains(decodedKind) else {
//                        throw InternalDecodingFailure.addressDiscriminatorMismatch(expectedAnyOf: Kind.addressSpace, butGot: decodedKind)
//                }
//                try self.init(address: address, kind: decodedKind)
//        }
// }
