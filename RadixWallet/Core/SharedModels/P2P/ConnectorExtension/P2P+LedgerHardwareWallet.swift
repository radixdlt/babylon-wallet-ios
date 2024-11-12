// MARK: - P2P.LedgerHardwareWallet
extension P2P {
	/// Just a namespace
	enum LedgerHardwareWallet {
		enum CodingKeys: String, CodingKey {
			case interactionID = "interactionId"
			case discriminator
			case success
			case error
		}

		typealias InteractionId = Tagged<Self, String>

		enum Discriminator: String, Sendable, Hashable, Codable {
			case getDeviceInfo
			case derivePublicKeys
			case signTransaction
			case signSubintentHash
			case signChallenge
			case deriveAndDisplayAddress
		}

		// N.B. these *might* have the exact same JSON representation as
		// `LedgerHardwareWalletFactorSource.Model` but in case we ever
		// change the JSON values for CAP21 or for Profile, we want them
		// to be **decoupled**.
		enum Model: String, Sendable, Hashable, Codable {
			case nanoS
			case nanoSPlus = "nanoS+"
			case nanoX
		}

		// N.B. these *might* have the exact same JSON representation as
		// `LedgerHardwareWalletFactorSource.Device` but in case we ever
		// change the JSON values for CAP21 or for Profile, we want them
		// to be **decoupled**.
		struct LedgerDevice: Sendable, Hashable, Codable {
			let name: NonEmptyString?

			/// `FactorSourceID`
			let id: String
			let model: Model

			init(name: NonEmptyString?, id: String, model: Model) {
				self.name = name
				self.id = id
				self.model = model
			}
		}

		struct KeyParameters: Sendable, Hashable, Codable {
			let curve: Curve
			let derivationPath: String
			enum Curve: String, Sendable, Hashable, Codable {
				case curve25519
				case secp256k1
			}

			init(curve: Curve, derivationPath: String) {
				self.curve = curve
				self.derivationPath = derivationPath
			}
		}
	}
}

extension P2P.LedgerHardwareWallet.InteractionId {
	/// Creates a new random interactionID using UUID
	static func random() -> Self {
		.init(rawValue: UUID().uuidString)
	}
}
