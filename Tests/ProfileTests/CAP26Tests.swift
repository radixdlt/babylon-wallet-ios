import Cryptography
import EngineToolkit
@testable import Profile
import RadixConnectModels
import SharedTestingModels
import TestingPrelude

extension SLIP10CurveProtocol {
	static var curveName: String {
		Self.curve.rawValue
	}
}

// MARK: - CAP26Tests
final class CAP26Tests: TestCase {
	func test_curve25519_vectors() throws {
		try testFixture(
			bundle: .module,
			jsonName: "cap26_curve25519"
		) { (testGroup: TestGroup) in
			try doTestCAP26(
				group: testGroup,
				curve: Curve25519.self
			)
		}
	}

	func test_secp256k1_vectors() throws {
		try testFixture(
			bundle: .module,
			jsonName: "cap26_secp256k1"
		) { (testGroup: TestGroup) in
			try doTestCAP26(
				group: testGroup,
				curve: SECP256K1.self
			)
		}
	}

	private func doTestCAP26<Curve>(
		group testGroup: TestGroup,
		curve: Curve.Type
	) throws where Curve: SLIP10CurveProtocol {
		guard curve.curveName == testGroup.curve else {
			XCTFail("Wrong curve specified as generic argument.")
			return
		}
		let mnemonic = try Mnemonic(phrase: testGroup.mnemonic, language: .english)
		let hdRoot = try mnemonic.hdRoot()
		let networkID = try XCTUnwrap(NetworkID(rawValue: UInt8(testGroup.network.networkIDDecimal)))
		func doTest(vector: TestGroup.Test) throws {
			let path = try HD.Path.Full(string: vector.path)
			let keyPair = try hdRoot.derivePrivateKey(path: path, curve: Curve.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey

			XCTAssertEqual(privateKey.rawRepresentation.hex, vector.privateKey)
			XCTAssertEqual(publicKey.compressedRepresentation.hex, vector.publicKey)

			let index = vector.entityIndex
			let entityKind = try XCTUnwrap(EntityKind(rawValue: vector.entityKind))
			let keyKind = try XCTUnwrap(KeyKind(rawValue: vector.keyKind))
			let entityPath: any EntityDerivationPathProtocol = try {
				switch entityKind {
				case .account:
					return try AccountHierarchicalDeterministicDerivationPath(
						networkID: networkID,
						index: index,
						keyKind: keyKind
					)
				case .identity:
					return try IdentityHierarchicalDeterministicDerivationPath(
						networkID: networkID,
						index: index,
						keyKind: keyKind
					)
				}
			}()

			XCTAssertEqual(entityPath.networkID, networkID)
			XCTAssertEqual(entityPath.entityKind, entityKind)
			XCTAssertEqual(entityPath.keyKind, keyKind)
			XCTAssertEqual(entityPath.index, index)
		}

		try testGroup.tests.forEach(doTest(vector:))
	}

	func omit_test_generate_cap26_testvectors() throws {
		print(String(repeating: "#", count: 100))
		print("🚀 CAP26 derivation paths 🚀")
		let mnemonicPhrase = "equip will roof matter pink blind book anxiety banner elbow sun young"
		let mnemonic = try Mnemonic(phrase: mnemonicPhrase, language: .english)
		let network = Radix.Network.kisharnet
		print("📚 mnemonic: \(mnemonicPhrase)")
		print("🛰️ network: \(network.name) (\(network.id.rawValue))")

		func doTest<P: EntityDerivationPathProtocol & Equatable, Curve: SLIP10CurveProtocol>(
			keyKind: KeyKind,
			entityKind: EntityKind,
			index: HD.Path.Component.Child.Value,
			hdPathType: P.Type,
			curve: Curve.Type
		) throws -> TestGroup.Test {
			let hdRoot = try mnemonic.hdRoot()
			let typedPath = try P(networkID: network.id, index: index, keyKind: keyKind)
			let path = typedPath.fullPath
			try XCTAssertEqual(P(derivationPath: path.toString()), typedPath)
			try XCTAssertEqual(P(fullPath: path), typedPath)
			try XCTAssertEqual(P(fullPath: path).fullPath, path)
			XCTAssertEqual(typedPath.networkID, network.id)
			XCTAssertEqual(typedPath.entityKind, entityKind)
			XCTAssertEqual(typedPath.keyKind, keyKind)
			XCTAssertEqual(typedPath.index, index)

			let keyPair = try hdRoot.derivePrivateKey(path: path, curve: Curve.self)
			let privateKey = try XCTUnwrap(keyPair.privateKey)
			let publicKey = privateKey.publicKey

			print("🔮 Derivation Path: \(path.toString())")
			print("🔑 🔐  Private Key (\(curve.curveName)): \(privateKey.rawRepresentation.hex)")
			print("🔑 🔓  Public Key (\(curve.curveName)): \(publicKey.compressedRepresentation.hex)")
			print("")
			let test = TestGroup.Test(
				path: path.toString(),
				privateKey: privateKey.rawRepresentation.hex,
				publicKey: publicKey.compressedRepresentation.hex,
				entityKind: entityKind.rawValue,
				keyKind: keyKind.rawValue,
				entityIndex: index
			)
			return test
		}

		func doDoTest<P: EntityDerivationPathProtocol & Equatable, Curve: SLIP10CurveProtocol>(
			hdPathType: P.Type,
			curve: Curve.Type
		) throws -> TestGroup {
			let entityKind = hdPathType.Entity.entityKind

			print("\n\n~~~~~ \(entityKind.emoji) ENTITY_TYPE: \(entityKind.name) (\(entityKind.rawValue)) \(entityKind.emoji) ~~~~~")
			let tests = try KeyKind.allCases.flatMap { keyKind in
				print("\n🗝️ \(keyKind.emoji) KEY_TYPE: \(keyKind.asciiSource) (\(keyKind.rawValue))")
				return try (HD.Path.Component.Child.Value(0) ..< 4).map { index in
					try doTest(
						keyKind: keyKind,
						entityKind: entityKind,
						index: index,
						hdPathType: hdPathType,
						curve: Curve.self
					)
				}
			}
			return .init(
				mnemonic: mnemonicPhrase,
				network: .init(name: network.name.rawValue, networkIDDecimal: network.id.rawValue),
				curve: curve.curveName,
				tests: tests
			)
		}

		let curve25519Accounts = try doDoTest(hdPathType: AccountHierarchicalDeterministicDerivationPath.self, curve: Curve25519.self)
		print(String(repeating: "*", count: 80))
		let curve25519Identities = try doDoTest(hdPathType: IdentityHierarchicalDeterministicDerivationPath.self, curve: Curve25519.self)
		print(String(repeating: "*", count: 80))
		print(String(repeating: "*", count: 80))
		print(String(repeating: "*", count: 80))
		let secp256k1Accounts = try doDoTest(hdPathType: AccountHierarchicalDeterministicDerivationPath.self, curve: SECP256K1.self)
		print(String(repeating: "*", count: 80))
		let secp256k1Identities = try doDoTest(hdPathType: IdentityHierarchicalDeterministicDerivationPath.self, curve: SECP256K1.self)

		let allCurve25519Tests = [curve25519Accounts, curve25519Identities].flatMap(\.tests)
		let curve25519TestGroup = TestGroup(
			mnemonic: mnemonicPhrase,
			network: curve25519Accounts.network,
			curve: curve25519Accounts.curve,
			tests: allCurve25519Tests
		)

		let allSecp256k1Tests = [secp256k1Accounts, secp256k1Identities].flatMap(\.tests)
		let secp256k1TestGroup = TestGroup(
			mnemonic: mnemonicPhrase,
			network: secp256k1Accounts.network,
			curve: secp256k1Accounts.curve,
			tests: allSecp256k1Tests
		)

		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
		try print(String(data: jsonEncoder.encode(curve25519TestGroup), encoding: .utf8)!)
//		try print(String(data: jsonEncoder.encode(secp256k1TestGroup), encoding: .utf8)!)

		print(String(repeating: "#", count: 100))
	}
}

extension EntityKind {
	var name: String {
		switch self {
		case .account: return "ACCOUNT"
		case .identity: return "IDENTITY"
		}
	}

	var emoji: String {
		switch self {
		case .account: return "💸"
		case .identity: return "🎭"
		}
	}
}

extension KeyKind {
	var emoji: String {
		switch self {
		case .transactionSigningKey: return "✍️"
		case .authenticationSigningKey: return "🛂"
		case .messageEncryptionKey: return "📨"
		}
	}
}

// MARK: - TestGroup
struct TestGroup: Sendable, Hashable, Codable {
	let mnemonic: String
	let network: Network
	let curve: String
	struct Network: Sendable, Hashable, Codable {
		let name: String
		let networkIDDecimal: UInt8
	}

	let tests: [Test]
	public struct Test: Sendable, Hashable, Codable {
		let path: String
		let privateKey: String
		let publicKey: String

		let entityKind: UInt32
		let keyKind: UInt32
		let entityIndex: UInt32
	}
}
