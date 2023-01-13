@testable import Cryptography
import TestingPrelude

// MARK: - TestVectorsTests
final class TestVectorsTests: XCTestCase {
	override func setUp() {
		super.setUp()
		continueAfterFailure = false
	}

	func testVectors10() throws {
		try orFail {
			try testFixture(
				bundle: .module,
				jsonName: "slip10_tests_#10"
			) { (testFile: TestFile) in
				try orFail {
					try doTestFile(
						testFile: testFile
					)
				}
			}
		}
	}

	// With optimization flag takes ~3 sec on a Mac Studio.
	func testVectors1K() throws {
		try orFail {
			try testFixture(
				bundle: .module,
				jsonName: "slip10_tests_#1000"
			) { (testFile: TestFile) in
				try orFail {
					try doTestFile(
						testFile: testFile
					)
				}
			}
		}
	}
}

private extension TestVectorsTests {
	func doTestFile(
		testFile: TestFile,
		file: StaticString = #file, line: UInt = #line
	) throws {
		print("✨ Testing group with #\(testFile.testGroups.reduce(0) { $0 + $1.testCases.map(\.childKeys.count).reduce(0, +) }) test cases", terminator: "")
		for group in testFile.testGroups {
			try orFail {
				try doTestGroup(
					group: group,
					file: file, line: line
				)
			}
		}
		print(" - PASSED ✅")
	}

	func doTestGroup(
		group: TestGroup,
		file: StaticString = #file, line: UInt = #line
	) throws {
		let mnemonic = try Mnemonic(phrase: group.mnemonicPhrase, language: .english)

		XCTAssertEqual(
			mnemonic.entropy().data,
			group.entropy,
			"Entropy mismatch",
			file: file, line: line
		)

		let root = try HD.Root(mnemonic: mnemonic, passphrase: group.passphrase)

		XCTAssertEqual(
			root.seed,
			group.seed,
			"Seed mismatch",
			file: file, line: line
		)

		for expectedMasterKey in group.masterKeys {
			let masterKey = try root.deriveMasterKey(curve: expectedMasterKey.curve)

			XCTAssertKeysEqual(
				masterKey, expected: expectedMasterKey,
				"Masterkey in group=\(group.groupId)",
				file: file, line: line
			)
		}

		for (testCaseIndex, testCase) in group.testCases.enumerated() {
			try orFail {
				try doTestCase(root: root, testCase: testCase, groupId: group.groupId, testCaseIndex: testCaseIndex)
			}
		}
	}

	func doTestCase(
		root: HD.Root,
		testCase: TestCase,
		groupId: Int,
		testCaseIndex: Int,
		file: StaticString = #file, line: UInt = #line
	) throws {
		for expectedChildKey in testCase.childKeys {
			let childKey = try root.deriveAnyPrivateKey(
				path: testCase.path,
				curve: expectedChildKey.curve
			)
			XCTAssertKeysEqual(
				childKey, expected: expectedChildKey,
				"ChildKey in groupId=\(groupId) case=\(testCaseIndex) path\(testCase.path)",
				file: file, line: line
			)
		}
	}

	func XCTAssertKeysEqual(
		_ actual: ExtendedKey,
		expected: ExtendedKey,
		_ prefix: String? = nil,
		file: StaticString = #file, line: UInt = #line
	) {
		func reason(_ reasonString: String) -> String {
			let curveString = "(Curve=\(expected.curve)"
			guard let reasonPrefix = prefix else { return "\(curveString) - \(reasonString)" }
			return "\(curveString) - \(reasonPrefix): \(reasonString)"
		}

		XCTAssertEqual(
			actual.curve, expected.curve,
			reason("curve mismatch"),
			file: file, line: line
		)

		XCTAssertEqual(
			actual.chainCode, expected.chainCode,
			reason("chainCode mismatch"),
			file: file, line: line
		)

		XCTAssertEqual(
			actual.privateKey, expected.privateKey,
			reason("Private key mismatch"),
			file: file, line: line
		)

		XCTAssertEqual(
			actual.publicKey, expected.publicKey,
			reason("Public key mismatch, expected: <\(expected.publicKey.hex())> but got: <\(actual.publicKey.hex())>"),
			file: file, line: line
		)

		XCTAssertEqual(
			actual.fingerprint, expected.fingerprint,
			reason("Fingerprint mismatch"),
			file: file, line: line
		)

		XCTAssertEqual(
			actual.xpub, expected.xpub,
			reason("xpub mismatch"),
			file: file, line: line
		)

		XCTAssertEqual(
			actual.xprv, expected.xprv,
			reason("xprv mismatch"),
			file: file, line: line
		)
	}
}

// MARK: - HD.Path.Full + CustomStringConvertible
extension HD.Path.Full: CustomStringConvertible {
	public var description: String {
		self.toString()
	}
}

// MARK: - Slip10Curve
enum Slip10Curve: String, Decodable, Hashable {
	case secp256k1

	/// nist256p1
	case p256 = "nist256p1"

	/// ed25519
	case curve25519 = "ed25519"

	init(curveType: Slip10CurveType) {
		if #available(macOS 13, *) {
			switch curveType {
			case .secp256k1: self = .secp256k1
			case .p256: self = .p256
			case .curve25519: self = .curve25519
			default: fatalError("Unsupported curve")
			}
		} else {
			switch curveType {
			case .secp256k1: self = .secp256k1
			case .curve25519: self = .curve25519
			default: fatalError("Unsupported curve")
			}
		}
	}

	var curveType: Slip10CurveType {
		switch self {
		case .curve25519: return .curve25519
		case .secp256k1: return .secp256k1
		case .p256: if #available(macOS 13, *) {
				return .p256
			} else {
				fatalError("unsupported")
			}
		}
	}
}

extension HD.Root {
	func deriveMasterKey(curve: Slip10Curve) throws -> ExtendedKey {
		try deriveAnyPrivateKey(
			path: HD.Path.Full(string: "m"),
			curve: curve
		)
	}

	func deriveAnyPrivateKey(
		path: HD.Path.Full,
		curve: Slip10Curve
	) throws -> ExtendedKey {
		switch curve {
		case .curve25519:
			return try .init(
				concrete: derivePrivateKey(
					path: path,
					curve: Curve25519.self
				)
			)

		case .secp256k1:
			return try .init(
				concrete: derivePrivateKey(
					path: path,
					curve: SECP256K1.self
				)
			)

		case .p256:
			if #available(macOS 13, *) {
				return try .init(
					concrete: derivePrivateKey(
						path: path,
						curve: P256.self
					)
				)
			} else {
				fatalError("unsupported")
			}
		}
	}
}

// MARK: - ExtendedKey
struct ExtendedKey: Decodable, Equatable {
	let curve: Slip10Curve

	let chainCode: ChainCode
	let privateKey: Data
	let publicKey: Data
	let fingerprint: Fingerprint
	let xpub: String
	let xprv: String
}

extension ExtendedKey {
	init<C>(concrete key: HD.ExtendedKey<C>) throws {
		guard let privateKey = key.privateKey else {
			throw Error.expectedPrivateKey
		}
		let curve = Slip10Curve(curveType: C.slip10Curve)
		self.curve = curve
		self.chainCode = key.chainCode
		self.privateKey = privateKey.rawRepresentation
		let pubKeyPrefix = curve == .curve25519 ? Data([0x00]) : Data()
		self.publicKey = pubKeyPrefix + key.publicKey.compressedRepresentation
		self.fingerprint = key.fingerprint
		self.xpub = try key.xpub()
		self.xprv = try key.xprv()
	}
}

extension ExtendedKey {
	enum CodingKeys: String, CodingKey {
		case curve, chainCode, privateKey, publicKey, fingerprint

		case xpub
		case xprv
	}

	enum Error: Swift.Error {
		case unrecognizedCurveName(String)
		case expectedPrivateKey
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let curveRaw = try container.decode(String.self, forKey: .curve)
		guard let curve = Slip10Curve(rawValue: curveRaw) else {
			throw Error.unrecognizedCurveName(curveRaw)
		}
		self.curve = curve

		let chainCodeHex = try container.decode(String.self, forKey: .chainCode)
		let chainCodeData = try Data(hex: chainCodeHex)
		self.chainCode = try ChainCode(data: chainCodeData)

		let privateKeyHex = try container.decode(String.self, forKey: .privateKey)
		self.privateKey = try Data(hex: privateKeyHex)

		let publicKeyHex = try container.decode(String.self, forKey: .publicKey)
		self.publicKey = try Data(hex: publicKeyHex)

		let fingerprintHex = try container.decode(String.self, forKey: .fingerprint)
		let fingerprintData = try Data(hex: fingerprintHex)
		self.fingerprint = try Fingerprint(data: fingerprintData)

		self.xpub = try container.decode(String.self, forKey: .xpub)
		self.xprv = try container.decode(String.self, forKey: .xprv)
	}
}

// MARK: - TestCase
struct TestCase: Decodable, Equatable {
	let path: HD.Path.Full
	let childKeys: [ExtendedKey]

	enum CodingKeys: String, CodingKey {
		case childKeys, path
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let pathString = try container.decode(String.self, forKey: .path)
		self.path = try HD.Path.Full(string: pathString)

		self.childKeys = try container.decode([ExtendedKey].self, forKey: .childKeys)
	}
}

// MARK: - TestGroup
struct TestGroup: Decodable, Equatable {
	let groupId: Int
	let entropy: Data
	let seed: Data
	let mnemonicPhrase: String
	let passphrase: String
	let masterKeys: [ExtendedKey]
	let testCases: [TestCase]

	enum CodingKeys: String, CodingKey {
		case groupId, seed, mnemonicPhrase, entropy, passphrase, masterKeys, testCases
	}

	init(from decoder: Decoder) throws {
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let entropyHex = try container.decode(String.self, forKey: .entropy)
		self.entropy = try Data(hex: entropyHex)

		let seedHex = try container.decode(String.self, forKey: .seed)
		self.seed = try Data(hex: seedHex)

		self.masterKeys = try container.decode([ExtendedKey].self, forKey: .masterKeys)
		self.groupId = try container.decode(Int.self, forKey: .groupId)
		self.mnemonicPhrase = try container.decode(String.self, forKey: .mnemonicPhrase)
		self.passphrase = try container.decode(String.self, forKey: .passphrase)
		self.testCases = try container.decode([TestCase].self, forKey: .testCases)
	}
}

// MARK: - TestFile
struct TestFile: Decodable, Equatable {
	let createdOn: String
	let author: String
	let info: String
	let contact: String
	let testGroups: [TestGroup]
}
