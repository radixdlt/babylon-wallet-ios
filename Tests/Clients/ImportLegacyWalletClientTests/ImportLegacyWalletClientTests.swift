import ClientTestingPrelude
import Cryptography
@testable import ImportLegacyWalletClient
import Profile

// MARK: - Olympia.AccountType + Codable
extension Olympia.AccountType: Codable {}

// MARK: - TestVector
struct TestVector: Codable, Sendable, Hashable {
	let testID: Int
	let olympiaWallet: OlympiaWallet
	let payloadSizeThreshold: Int
	let numberOfPayloads: Int
	let payloads: NonEmpty<OrderedSet<NonEmptyString>>
	init(testID: Int, olympiaWallet: OlympiaWallet, payloadSizeThreshold: Int, payloads: NonEmpty<OrderedSet<NonEmptyString>>) {
		self.testID = testID
		self.olympiaWallet = olympiaWallet
		self.payloadSizeThreshold = payloadSizeThreshold
		self.numberOfPayloads = payloads.count
		self.payloads = payloads
	}

	struct OlympiaWallet: Codable, Hashable {
		let mnemonic: String
		let accounts: [TestVector.OlympiaWallet.Account]
		struct Account: Sendable, Hashable, Codable {
			public let accountType: Olympia.AccountType
			public let publicKeyCompressedBase64: String
			enum CodingKeys: String, CodingKey {
				case accountType
				case name
				case addressIndex
				case publicKeyCompressedBase64 = "pubKey"
			}

			public let addressIndex: Int
			public let name: NonEmptyString?
		}
	}
}

extension CAP33 {
	static func serialize(
		wordCount: Int,
		accounts: [TestVector.OlympiaWallet.Account],
		payloadSizeThreshold: Int
	) throws -> NonEmpty<OrderedSet<NonEmptyString>> {
		// 1. First serialize each account
		let serializedAccounts: [String] = accounts.map { account -> String in
			[
				account.accountType.rawValue,
				account.publicKeyCompressedBase64,
				"\(account.addressIndex)",
				// Replace all characters matching RESERVED characters with `ACCOUNT_NAME_REPLACEMENT` character
				// Take first 30 characters of name only. Name can be empty. ALWAYS append `END_OF_ACCOUNT_NAME`.
				Self._sanitize(name: account.name) + Olympia.Export.Separator.accountNameEnd,
			].joined(separator: Olympia.Export.Separator.intra) // Join accounts with `INTRA_SEPARATOR` char
		}

		// 2. Join serialized accounts into a single big string, using `INTER_SEPARATOR`
		let accountsJoined = serializedAccounts.joined(
			separator: Olympia.Export.Separator.inter
		)

		// 3. Split `accountsJoined` into 'contentsOfPayloads' with bytecount 'payloadSizeThreshold'
		let contentsOfPayloads: [String] = accountsJoined.chunks(ofCount: payloadSizeThreshold).map { String($0) }

		// 4. Now we know payloadCount
		let payloadCount = contentsOfPayloads.count

		// 5. Prepend each "contentOfPayload| with a header, with a unique header specifying the index of the resulting payload
		let payloadsArray: [NonEmptyString] = contentsOfPayloads.enumerated().map { payloadIndex, payloadContent in

			// Construct header, being the tripple (payloadCount, payloadIndex, mnemonicWordCount)
			let header: String = [payloadCount, payloadIndex, wordCount]
				.map { "\($0)" } // stringify the three integers (base 10)
				.joined(separator: Olympia.Export.Separator.intra) // join with `INTRA_SEPARATOR` char
				+ Olympia.Export.Separator.headerEnd // end it with `headerEnd` seperator

			guard let payload = NonEmptyString(rawValue: header + payloadContent) else {
				fatalError("Failed to serialize payload")
			}
			return payload
		}

		let payloadsOrderedSet = OrderedSet<NonEmptyString>(uncheckedUniqueElements: payloadsArray)

		// 6. Return payloads, being an array of "\(header)\(payloadContent)"
		guard let nonEmpty = NonEmpty<OrderedSet<NonEmptyString>>(rawValue: payloadsOrderedSet) else {
			fatalError("Failed to create payloads")
		}
		return nonEmpty
	}
}

extension K1.PublicKey {
	var base64Encoded: String {
		let publicKeyCompressed = compressedRepresentation
		assert(publicKeyCompressed.count == 33)
		assert(publicKeyCompressed[0] == 0x02 || publicKeyCompressed[0] == 0x03)
		return publicKeyCompressed.base64EncodedString()
	}
}

private func generateTestVector(
	testID: Int,
	payloadSizeThreshold: Int,
	numberOfAccounts: Int,
	mnemonic: Mnemonic
) throws -> TestVector {
	let accountNames: [String?] = [
		String?.none,
		"",
		Olympia.Export.accountNameForbiddenCharReplacement,
		"Main account.",
		"Saving's account.",
		"Olympia is a small town in Elis on the Peloponnese peninsula in Greece, famous for the nearby archaeological site of the same name",
		"Alexandria is the second largest city in Egypt, and the largest city on the Mediterranean coast",
		"Forbidden \(Olympia.Export.Separator.allCases.joined(separator: "|"))",
		"OK +?-,.\\)[\\(!#$%{&/*<>=OK",
		"Numbers are allowed 0123456789",
	]

	let accounts: [TestVector.OlympiaWallet.Account] = try (0 ..< numberOfAccounts).map { (accountIndex: Int) -> TestVector.OlympiaWallet.Account in
		let detRND = accountIndex + testID
		let name: NonEmptyString? = accountNames[detRND % accountNames.count].map {
			NonEmptyString(rawValue: $0)
		} ?? nil
		let accountType: Olympia.AccountType = (detRND % 2) == 0 ? .software : .hardware
		let path = try LegacyOlympiaBIP44LikeDerivationPath(index: Profile.Network.NextDerivationIndices.Index(accountIndex))
		let publicKey = try mnemonic.hdRoot().derivePrivateKey(path: path.fullPath, curve: SECP256K1.self).publicKey

		return TestVector.OlympiaWallet.Account(
			accountType: accountType,
			publicKeyCompressedBase64: publicKey.base64Encoded,
			addressIndex: accountIndex,
			name: name
		)
	}

	let payloads = try CAP33.serialize(
		wordCount: mnemonic.wordCount.wordCount,
		accounts: accounts,
		payloadSizeThreshold: payloadSizeThreshold
	)

	let accountsWithSanitizedNames = accounts.map {
		$0.sanitizedName()
	}

	// Soundness check!
	let parsed = try CAP33.deserialize(payloads: payloads)
	XCTAssertEqual(parsed.mnemonicWordCount, mnemonic.wordCount)
	XCTAssertEqual(accounts.count, parsed.accounts.count)
	XCTAssertEqual(parsed.accounts.elements.map {
		$0.toTestVectorAccount()
	}, accountsWithSanitizedNames)

	return .init(
		testID: testID, olympiaWallet: .init(
			mnemonic: mnemonic.phrase,
			accounts: accountsWithSanitizedNames
		), payloadSizeThreshold: payloadSizeThreshold,
		payloads: payloads
	)
}

private func generateTestVectors() throws -> [TestVector] {
	// 8 chars per header
	// 73 chars per account excl account name, ~9 chars per name -> 82 chars per account
	// 8+82 = ~90 chars per payload
	//
	// Excluding error correction level, which will lower these estimates:
	let payloadAndNumberOfAccounts: OrderedDictionary<Int, [Int]> = [
		60: [1, 2, 3], // 0.66 accounts per payload
		1200: [13, 30], // 13  accounts
		1600: [17, 35], // 17  accounts
		1800: [30, 45], // 20 accounts
		2000: [25, 50, 100], // 22 accounts
	]

	var testID = 0

	let testVectors: [TestVector] = try payloadAndNumberOfAccounts.flatMap { payloadSizeThreshold, numberOfAccountsPossible in
		try [BIP39.WordCount.twelve, BIP39.WordCount.twentyFour].flatMap { wordCount in
			let mnemonic = try Mnemonic.generate(wordCount: wordCount)
			return try numberOfAccountsPossible.map { numberOfAccounts in
				defer { testID += 1 }
				return try generateTestVector(
					testID: testID,
					payloadSizeThreshold: payloadSizeThreshold,
					numberOfAccounts: numberOfAccounts,
					mnemonic: mnemonic
				)
			}
		}
	}

	return testVectors
}

extension TestVector.OlympiaWallet.Account {
	func sanitizedName() -> Self {
		.init(
			accountType: accountType,
			publicKeyCompressedBase64: publicKeyCompressedBase64,
			addressIndex: addressIndex,
			name: NonEmptyString(rawValue: CAP33._sanitize(name: name))
		)
	}
}

extension Olympia.Parsed.Account {
	func toTestVectorAccount() -> TestVector.OlympiaWallet.Account {
		.init(
			accountType: accountType,
			publicKeyCompressedBase64: publicKey.base64Encoded,
			addressIndex: Int(addressIndex),
			name: displayName
		)
	}
}

// MARK: - ImportLegacyWalletClientTests
final class ImportLegacyWalletClientTests: TestCase {
	func omit_test_generate_tests() throws {
		let testVectors = try generateTestVectors()
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = [.prettyPrinted, .withoutEscapingSlashes]
		let testJSON = try jsonEncoder.encode(testVectors)
		print(String(data: testJSON, encoding: .utf8)!)
	}

	func test_vectors() throws {
		func doTestDeserialize(_ vector: TestVector) throws {
			let mnemonic = try Mnemonic(phrase: vector.olympiaWallet.mnemonic, language: .english)
			let parsed = try CAP33.deserialize(payloads: vector.payloads)
			XCTAssertEqual(parsed.mnemonicWordCount, mnemonic.wordCount)
			XCTAssertEqual(parsed.accounts.elements.map { $0.toTestVectorAccount() }, vector.olympiaWallet.accounts)
		}

		func doSoundnessTestSerialize(_ vector: TestVector) throws {
			let mnemonic = try Mnemonic(phrase: vector.olympiaWallet.mnemonic, language: .english)

			let payloads = try CAP33.serialize(
				wordCount: mnemonic.wordCount.wordCount,
				accounts: vector.olympiaWallet.accounts,
				payloadSizeThreshold: vector.payloadSizeThreshold
			)

			XCTAssertEqual(payloads, vector.payloads)
		}

		try testFixture(
			bundle: .module,
			jsonName: "import_olympia_wallet_parse_test"
		) { (testVectors: [TestVector]) in

			for vector in testVectors {
				try doTestDeserialize(vector)
				// By default omit soundness check of serialize
				try doSoundnessTestSerialize(vector)
			}
		}
	}

	func test_cap33_example() throws {
		let expectedAccounts: [Olympia.Parsed.Account] = try [
			.init(
				accountType: .software,
				publicKey: K1.PublicKey(
					compressedRepresentation: Data(
						hex: "02f669a43024d90fde69351ccc53022c2f86708d9b3c42693640733c5778235da5"
					)),
				displayName: .init(rawValue: "With forbidden char in name"),
				addressIndex: 0
			),
			.init(
				accountType: .hardware,
				publicKey: K1.PublicKey(
					compressedRepresentation: Data(
						hex: "03f6332edc2aa0f035c3c54d74a3acec76d9b5985eaddcda995b97d4117705d7b3"
					)),
				displayName: nil,
				addressIndex: 1
			),
			.init(
				accountType: .hardware,
				publicKey: K1.PublicKey(
					compressedRepresentation: Data(
						hex: "0354938a7db217e2e610f5389996ab63a070fb4414664df9d15e275aea6fe497c6"
					)),
				displayName: .init(rawValue: "Third|account_ok"),
				addressIndex: 2
			),
		]

		func doTest(threshold: Int, payloadStrings: [String]) throws {
			let parsed = try CAP33._deserialize(payloadsStrings: payloadStrings)
			XCTAssertEqual(parsed.mnemonicWordCount, .twelve)
			let accounts = parsed.accounts
			XCTAssertEqual(accounts.count, expectedAccounts.count)
			for accountIndex in 0 ..< expectedAccounts.count {
				let lhs = accounts.elements[accountIndex]
				let rhs = expectedAccounts[accountIndex]
				XCTAssertEqual(lhs, rhs)
			}

			let serialized = try CAP33.serialize(
				wordCount: 12,
				accounts: expectedAccounts.map { $0.toTestVectorAccount() },
				payloadSizeThreshold: threshold
			)

			for payloadIndex in 0 ..< payloadStrings.count {
				XCTAssertNoDifference(payloadStrings[payloadIndex], serialized.rawValue.elements[payloadIndex].rawValue)
			}
		}

		try doTest(threshold: 125, payloadStrings: [
			"2^0^12]S^AvZppDAk2Q/eaTUczFMCLC+GcI2bPEJpNkBzPFd4I12l^0^With forbidden char in name}~H^A/YzLtwqoPA1w8VNdKOs7HbZtZherdzamVuX1BF3Bdez^",
			"2^1^12]1^}~H^A1STin2yF+LmEPU4mZarY6Bw+0QUZk350V4nWupv5JfG^2^Third|account_ok}",
		])

		try doTest(threshold: 60, payloadStrings: [
			"4^0^12]S^AvZppDAk2Q/eaTUczFMCLC+GcI2bPEJpNkBzPFd4I12l^0^With forbid",
			"4^1^12]den char in name}~H^A/YzLtwqoPA1w8VNdKOs7HbZtZherdzamVuX1BF3",
			"4^2^12]Bdez^1^}~H^A1STin2yF+LmEPU4mZarY6Bw+0QUZk350V4nWupv5JfG^2^Th",
			"4^3^12]ird|account_ok}",
		])
	}
}

// MARK: - K1.PublicKey + CustomDebugStringConvertible
extension K1.PublicKey: CustomDebugStringConvertible {
	public var debugDescription: String {
		compressedRepresentation.hex
	}
}

// MARK: - Olympia.AccountType + CustomDebugStringConvertible
extension Olympia.AccountType: CustomDebugStringConvertible {
	public var debugDescription: String {
		description
	}
}
