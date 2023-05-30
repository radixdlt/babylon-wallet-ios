import Prelude

// MARK: - BabylonDeviceFactorSource
/// This is NOT a `Codable` factor source, this is never saved anywhere, just in memory.
/// It acts a a convenience in code to not have to assert that `kind == .device` and
/// try to access `entityCreatingStorage` which is optional also asserting `cryptoParameters` to
/// only declare `curve25519` and `cap26` derivation path.
public struct BabylonDeviceFactorSource: _EntityCreatingFactorSourceProtocol, Identifiable {
	public var kind: FactorSourceKind {
		deviceFactorSource.kind
	}

	public var common: FactorSource.Common {
		get { deviceFactorSource.common }
		set { fatalError("should not be used") }
	}

	public typealias ID = FactorSourceID
	public var id: ID {
		deviceFactorSource.id
	}

	public static let assertedKind: FactorSourceKind? = .device
	public static let assertedParameters: FactorSource.CryptoParameters? = .babylon

	public let deviceFactorSource: DeviceFactorSource
	public let nextDerivationIndicesPerNetwork: NextDerivationIndicesPerNetwork

	public init(factorSource: FactorSource) throws {
		let deviceFactorSource = try factorSource.extract(as: DeviceFactorSource.self)

//		self.factorSource = try Self.validating(factorSource: factorSource)
//		guard let deviceFactorSource = factorSource as? DeviceFactorSource else {
//			throw DisrepancyFactorSourceWrongKind(expected: .device, actual: factorSource.kind)
//		}
		guard let nextDerivationIndicesPerNetwork = deviceFactorSource.nextDerivationIndicesPerNetwork else {
			throw ExpectedNextDerivationIndicesPerNetwork()
		}
		self.nextDerivationIndicesPerNetwork = nextDerivationIndicesPerNetwork
		self.deviceFactorSource = deviceFactorSource
	}
}

// MARK: - ExpectedNextDerivationIndicesPerNetwork
struct ExpectedNextDerivationIndicesPerNetwork: Swift.Error {}

// #if DEBUG
// extension BabylonDeviceFactorSource {
//	public static let previewValue: Self = try! Self(factorSource: .previewValueDevice)
// }
// #endif // DEBUG
