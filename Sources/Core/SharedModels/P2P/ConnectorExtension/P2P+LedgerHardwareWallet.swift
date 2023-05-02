import Prelude

// MARK: - P2P.LedgerHardwareWallet
extension P2P {
	/// Just a namespace
	public enum LedgerHardwareWallet {
		enum CodingKeys: String, CodingKey {
			case interactionID = "interactionId"
			case discriminator
			case success
			case failure
		}

		public typealias InteractionId = Tagged<Self, String>

		public enum Discriminator: String, Sendable, Hashable, Codable {
			case getDeviceInfo
			case derivePublicKey
			case signTransaction
			case importOlympiaDevice
		}

		// N.B. these *might* have the exact same JSON representation as
		// `FactorSource.LedgerHardwareWallet.Model` but in case we ever
		// change the JSON values for CAP21 or for Profile, we want them
		// to be **decoupled**.
		public enum Model: String, Sendable, Hashable, Codable {
			case nanoS
			case nanoSPlus = "nanoS+"
			case nanoX
		}

		// N.B. these *might* have the exact same JSON representation as
		// `FactorSource.LedgerHardwareWallet.Device` but in case we ever
		// change the JSON values for CAP21 or for Profile, we want them
		// to be **decoupled**.
		public struct LedgerDevice: Sendable, Hashable, Codable {
			public let name: NonEmptyString?

			/// `FactorSource.ID`
			public let id: String
			public let model: Model

			public init(name: NonEmptyString?, id: String, model: Model) {
				self.name = name
				self.id = id
				self.model = model
			}
		}

		public struct KeyParameters: Sendable, Hashable, Codable {
			public let curve: Curve
			public let derivationPath: String
			public enum Curve: String, Sendable, Hashable, Codable {
				case curve25519
				case secp256k1
			}

			public init(curve: Curve, derivationPath: String) {
				self.curve = curve
				self.derivationPath = derivationPath
			}
		}
	}
}

extension P2P.LedgerHardwareWallet.InteractionId {
	/// Creates a new random interactionID using UUID
	public static func random() -> Self {
		.init(rawValue: UUID().uuidString)
	}
}
