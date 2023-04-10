import ClientTestingPrelude
import Cryptography
@testable import ImportLegacyWalletClient

// MARK: - Olympia
public enum Olympia {}

// MARK: Olympia.AccountType
extension Olympia {
	public enum AccountType: String, Sendable, Hashable, CustomStringConvertible {
		case software = "S"
		case hardware = "H"
		public var description: String {
			switch self {
			case .software: return "software"
			case .hardware: return "hardware"
			}
		}
	}
}

extension Olympia {
	public enum Export {}
	public struct Parsed: Sendable, Hashable {
		let mnemonicWordCount: BIP39.WordCount
		let accounts: OrderedSet<Olympia.Parsed.Account>
		public struct Account: Sendable, Hashable {
			public let accountType: Olympia.AccountType
			public let publicKey: K1.PublicKey
			public let displayName: NonEmptyString?
			/// the non hardened value of the path
			public let addressIndex: HD.Path.Component.Child.Value
		}
	}
}

extension Olympia.Export {
	public static let accountNameForbiddenCharReplacement = " "
	public static let accountNameMaxLength = 30 // sync with profile!
	public enum Separator: Sendable, Hashable, CaseIterable {
		static let inter = "~"
		static let intra = "|"
		static let headerEnd = "^"
		static let accountNameEnd = "}"
		public static let allCases: [String] = [
			Self.inter, Self.intra, Self.headerEnd, Self.accountNameEnd,
		]
	}

	public struct Payload: Sendable, Hashable {
		public let header: Header
		public let contents: Contents

		public struct Header: Sendable, Hashable {
			public let payloadCount: Int
			public let payloadIndex: Int
			public let mnemonicWordCount: Int
		}

		public struct Contents: Sendable, Hashable {
			public let accounts: OrderedSet<Olympia.Parsed.Account>
			public let rest: NonEmptyString?
		}
	}
}

// MARK: - Olympia.AccountType + Codable
extension Olympia.AccountType: Codable {}

// MARK: - TestVector
struct TestVector: Codable, Sendable, Hashable {
	let testID: Int
	let olympiaWallet: OlympiaWallet
	let payloadSizeThreshold: Int
	let payloads: NonEmpty<OrderedSet<NonEmptyString>>

	struct OlympiaWallet: Codable, Hashable {
		let mnemonic: String
		let accounts: [TestVector.OlympiaWallet.Account]
		struct Account: Sendable, Hashable, Codable {
			public let accountType: Olympia.AccountType
			public let publicKeyCompressedBase64: String
			public let addressIndex: Int
			public let name: NonEmptyString?
		}
	}
}

// MARK: - CAP33
enum CAP33 {
	enum Error: Swift.Error {
		case failedToParseHeaderDoesNotContainEndSeparator
		case failedToParsePayloadDidNotContainHeaderAndContent
		case failedToParseHeaderCannotBeEmpty
		case failedToParseHeaderContentCannotBeEmpty
		case failedToParseHeaderDoesNotContainThreeComponents
		case failedToParseHeaderDoesNotContainPayloadCount
		case failedToParseHeaderDoesNotContainPayloadIndex
		case failedToParseHeaderDoesNotContainMnemonicWordCount
		case failedToParsePayloadsFoundDuplicates
		case failedToParseAccountBadAccountTypeValue
		case failedToParseAccountPublicKeyInvalidBase64String
		case failedToParseAccountPublicKeyInvalidByteCount
		case failedToParseAccountPublicKeyInvalidSecp256k1PublicKey
		case failedToParseAccountAddressIndex
		case failedToParseAccountNameDidNotEndWithExpectedSeparatorfailedToParseAccountNameDidNotEndWithExpectedSeparator
	}

	public static func deserializeHeader(payload: NonEmptyString) throws -> Olympia.Export.Payload.Header {
		try deserializeHeaderAndContent(payload: payload).header
	}

	private static func deserializeHeaderAndContent(
		payload payloadNonEmpty: NonEmptyString
	) throws -> (header: Olympia.Export.Payload.Header, content: NonEmptyString) {
		let payload = payloadNonEmpty.rawValue

		guard payload.contains(Olympia.Export.Separator.headerEnd) else {
			throw Error.failedToParseHeaderDoesNotContainEndSeparator
		}

		guard
			case let components = payload.split(
				separator: Olympia.Export.Separator.headerEnd,
				omittingEmptySubsequences: true
			),
			components.count == 2,
			components.allSatisfy({ !$0.isEmpty }),
			case let headerComponent = components[0],
			let content = NonEmptyString(rawValue: String(components[1]))
		else {
			throw Error.failedToParsePayloadDidNotContainHeaderAndContent
		}
		guard
			!headerComponent.isEmpty
		else {
			throw Error.failedToParseHeaderCannotBeEmpty
		}

		guard
			!components[1].isEmpty
		else {
			throw Error.failedToParseHeaderContentCannotBeEmpty
		}

		guard
			case let headerComponents = headerComponent.split(
				separator: Olympia.Export.Separator.intra,
				omittingEmptySubsequences: true
			),
			headerComponents.count == 3,
			headerComponents.allSatisfy({ !$0.isEmpty })
		else {
			throw Error.failedToParseHeaderDoesNotContainThreeComponents
		}
		guard let payloadCount = Int(headerComponents[0]) else {
			throw Error.failedToParseHeaderDoesNotContainPayloadCount
		}
		guard let payloadIndex = Int(headerComponents[1]) else {
			throw Error.failedToParseHeaderDoesNotContainPayloadIndex
		}
		guard let mnemonicWordCount = Int(headerComponents[2]) else {
			throw Error.failedToParseHeaderDoesNotContainMnemonicWordCount
		}
		let header = Olympia.Export.Payload.Header(
			payloadCount: payloadCount,
			payloadIndex: payloadIndex,
			mnemonicWordCount: mnemonicWordCount
		)

		return (header: header, content: content)
	}

	enum AccountOrRest {
		case account(Olympia.Parsed.Account)
		case rest(NonEmptyString)
	}

	private static func _deserializeAccount(
		accountComponent: String
	) throws -> AccountOrRest? {
		let components = accountComponent.split(
			separator: Olympia.Export.Separator.intra,
			omittingEmptySubsequences: true // account name is always suffix with an `accountNameEnd`
		)

		guard components.count == 4, components[3].hasSuffix(Olympia.Export.Separator.accountNameEnd) else {
			if let rest = NonEmptyString(rawValue: accountComponent) {
				return .rest(rest)
			} else {
				debugPrint("Empty rest found in account component")
				return nil
			}
		}

		guard components[0].count == 1, let accountType = Olympia.AccountType(rawValue: String(components[0])) else {
			throw Error.failedToParseAccountBadAccountTypeValue
		}
		guard
			case let publicKeyCompressedBase64 = String(components[1]),
			let publicKeyData = Data(base64Encoded: publicKeyCompressedBase64)
		else {
			throw Error.failedToParseAccountPublicKeyInvalidBase64String
		}

		guard publicKeyData.count == 33 else {
			throw Error.failedToParseAccountPublicKeyInvalidByteCount
		}

		let publicKey: K1.PublicKey
		do {
			publicKey = try K1.PublicKey(compressedRepresentation: publicKeyData)
		} catch {
			throw Error.failedToParseAccountPublicKeyInvalidSecp256k1PublicKey
		}

		guard let bip44LikeAddressIndex = HD.Path.Component.Child.Value(components[2]) else {
			throw Error.failedToParseAccountAddressIndex
		}

		guard
			case var accountName = String(components[3]),
			accountName.hasSuffix(Olympia.Export.Separator.accountNameEnd)
		else {
			throw Error.failedToParseAccountNameDidNotEndWithExpectedSeparatorfailedToParseAccountNameDidNotEndWithExpectedSeparator
		}
		accountName.removeLast()

		let maybeName = NonEmptyString(rawValue: accountName)

		let account = Olympia.Parsed.Account(
			accountType: accountType,
			publicKey: publicKey,
			displayName: maybeName,
			addressIndex: bip44LikeAddressIndex
		)

		return .account(account)
	}

	private static func deserialize(
		payload: NonEmptyString,
		rest maybeRest: NonEmptyString?
	) throws -> Olympia.Export.Payload {
		let (header, contentNonEmpty) = try deserializeHeaderAndContent(payload: payload)
		let contentSuffix = contentNonEmpty.rawValue
		let content: String = {
			if let rest = maybeRest {
				// Prepend rest from last payload if any
				return rest + contentSuffix
			} else {
				return contentSuffix
			}
		}()

		guard
			case let accountComponentsAndMaybeRest = content.split(
				separator: Olympia.Export.Separator.inter,
				omittingEmptySubsequences: true
			),
			accountComponentsAndMaybeRest.allSatisfy({ !$0.isEmpty })
		else {
			throw Error.failedToParsePayloadDidNotContainHeaderAndContent
		}

		var accounts: OrderedSet<Olympia.Parsed.Account> = .init()
		var rest: NonEmptyString?
		for accountComponent in accountComponentsAndMaybeRest {
			guard let accountOrRest = try _deserializeAccount(accountComponent: String(accountComponent)) else {
				continue
			}
			switch accountOrRest {
			case let .account(account):
				accounts.append(account)
			case let .rest(_rest):
				rest = _rest
			}
		}
		return .init(header: header, contents: .init(accounts: accounts, rest: rest))
	}

	internal static func _deserialize(payloadsStrings: [String]) throws -> Olympia.Parsed {
		try Self.deserialize(
			payloads: .init(rawValue: OrderedSet(
				uncheckedUniqueElements: payloadsStrings.compactMap { NonEmptyString(rawValue: $0) }
			))!
		)
	}

	public static func deserialize(
		payloads payloadStrings: NonEmpty<OrderedSet<NonEmptyString>>
	) throws -> Olympia.Parsed {
		var accounts: OrderedSet<Olympia.Parsed.Account> = .init()
		var mnemonicWordCount: BIP39.WordCount?

		var rest: NonEmptyString?
		for payloadString in payloadStrings.rawValue.elements {
			let payload = try Self.deserialize(payload: payloadString, rest: rest)
			if mnemonicWordCount == nil {
				mnemonicWordCount = BIP39.WordCount(wordCount: payload.header.mnemonicWordCount)!
			}
			accounts.append(contentsOf: payload.contents.accounts)
			rest = payload.contents.rest
		}

		return .init(
			mnemonicWordCount: mnemonicWordCount!,
			accounts: accounts
		)
	}

	internal static func _sanitize(name: NonEmptyString?) -> String {
		guard let name = name else { return "" }
		var truncated = String(name.rawValue.prefix(30))
		let forbiddenCharacters: [String] = Olympia.Export.Separator.allCases
		for forbiddenChar in forbiddenCharacters {
			truncated = truncated.replacingOccurrences(of: forbiddenChar, with: Olympia.Export.accountNameForbiddenCharReplacement)
		}
		return truncated
	}

	public static func serialize(
		wordCount: Int,
		accounts: [TestVector.OlympiaWallet.Account],
		payloadSizeThreshold: Int
	) throws -> NonEmpty<OrderedSet<NonEmptyString>> {
		// 1. First serialize each account
		let serializedAccounts: [String] = accounts.map { (account: TestVector.OlympiaWallet.Account) -> String in

			[
				account.accountType.rawValue,
				account.publicKeyCompressedBase64,
				"\(account.addressIndex)",
				Self._sanitize(name: account.name) + Olympia.Export.Separator.accountNameEnd, // mark end of account name (that might be empty)

			].joined(separator: Olympia.Export.Separator.intra)
		}

		// 2. Join serialized accounts into a single big string, using `INTER_SEPARATOR`
		let accountsJoined = serializedAccounts.joined(
			separator: Olympia.Export.Separator.inter
		)
		// 3. Split big string into 'contentsOfPayloads' with bytecount 'payloadSizeThreshold'
		let contentsOfPayloads: [String] = accountsJoined.chunks(ofCount: payloadSizeThreshold).map { String($0) }

		// 4. Now we know payloadCount
		let payloadCount = contentsOfPayloads.count

		// 5. Prepend each "contentOfPayload| with a header, with a unique header specifying the index of the resulting payload
		let payloadsArray: [NonEmptyString] = contentsOfPayloads.enumerated().map { payloadIndex, payloadContent in
			// Construct header, end it with `headerEnd` seperator
			let header: String = [payloadCount, payloadIndex, wordCount].map { "\($0)" }.joined(separator: Olympia.Export.Separator.intra) + Olympia.Export.Separator.headerEnd

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

private func generateTestVectors(numberOfTestVectors: Int = 6) throws -> [TestVector] {
	let payloadSizes: [Int] = .init(stride(from: 300, to: 3000, by: 100))
	let accountNames: [String?] = [
		String?.none,
		"",
		Olympia.Export.accountNameForbiddenCharReplacement,
		"Main account.",
		"Saving's account.",
		"Olympia is a small town in Elis on the Peloponnese peninsula in Greece, famous for the nearby archaeological site of the same name",
		"Alexandria is the second largest city in Egypt, and the largest city on the Mediterranean coast",
		"Forbidden \(Olympia.Export.Separator.allCases.joined(separator: "-"))",
		"OK +?-_,.\\)[]\\(!#$%}&/*<>=OK",
		"Numbers are allowed 0123456789",
	]
	let numberOfAccounts = [1, 5, 10, 15, 30, 50, 100]

	let testVectors: [TestVector] = try (0 ..< numberOfTestVectors).map { (testID: Int) -> TestVector in
		let wordCount = BIP39.WordCount.allCases[testID % BIP39.WordCount.allCases.count]
		let mnemonic = try Mnemonic.generate(wordCount: wordCount)
		let hdRoot = try mnemonic.hdRoot()
		let payloadSizeThreshold = payloadSizes[testID % payloadSizes.count]
		let numberOfAccounts = numberOfAccounts[testID % numberOfAccounts.count]

		let accounts: [TestVector.OlympiaWallet.Account] = try (0 ..< numberOfAccounts).map { (accountIndex: Int) -> TestVector.OlympiaWallet.Account in

			let accountRND = testID * accountIndex
			let name: NonEmptyString? = accountNames[accountIndex % accountNames.count].map {
				NonEmptyString(rawValue: $0)
			} ?? nil
			let accountType: Olympia.AccountType = (accountRND % 2) == 0 ? .software : .hardware
			let path = try LegacyOlympiaBIP44LikeDerivationPath(index: Profile.Network.NextDerivationIndices.Index(accountIndex))
			let publicKey = try hdRoot.derivePrivateKey(path: path.fullPath, curve: SECP256K1.self).publicKey

			return TestVector.OlympiaWallet.Account(
				accountType: accountType,
				publicKeyCompressedBase64: publicKey.base64Encoded,
				addressIndex: accountIndex,
				name: name
			)
		}

		let payloads = try CAP33.serialize(
			wordCount: wordCount.rawValue,
			accounts: accounts,
			payloadSizeThreshold: payloadSizeThreshold
		)

		let accountsWithSanitizedNames = accounts.map {
			$0.sanitizedName()
		}

		// Soundness check!
		let parsed = try CAP33.deserialize(payloads: payloads)
		XCTAssertEqual(parsed.mnemonicWordCount, wordCount)
		XCTAssertEqual(accounts.count, parsed.accounts.count)
		XCTAssertEqual(parsed.accounts.elements.map {
			$0.toTestVectorAccount()
		}, accountsWithSanitizedNames)
//		for index in 0 ..< accounts.count {
//			let lhs = accounts[index].sanitizedName()
//			let rhs = parsed.accounts.elements[index].toTestVectorAccount()
//			XCTAssertEqual(lhs.name, rhs.name, "Name mismatch, unserialized: '\(String(describing: accounts[index].name))', parsed: \(String(describing: parsed.accounts.elements[index].displayName))")
//		}

		return .init(
			testID: testID, olympiaWallet: .init(
				mnemonic: mnemonic.phrase,
				accounts: accountsWithSanitizedNames
			), payloadSizeThreshold: payloadSizeThreshold,
			payloads: payloads
		)
	}

	assert(testVectors.count == numberOfTestVectors)

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
	func test_generate_tests() throws {
		let testVectors = try generateTestVectors(numberOfTestVectors: 100)
		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = .prettyPrinted
		let testJSON = try jsonEncoder.encode(testVectors)
//		print("🔮 generated #\(testVectors.count) tests:")
		print(String(data: testJSON, encoding: .utf8)!)
//		print("✅ success")
	}

	func test_vectors() throws {
		try testFixture(
			bundle: .module,
			jsonName: "import_olympia_wallet_parse_test"
		) { (testVectors: [TestVector]) in

			for vector in testVectors {
				let mnemonic = try Mnemonic(phrase: vector.olympiaWallet.mnemonic, language: .english)
				let parsed = try CAP33.deserialize(payloads: vector.payloads)
				XCTAssertEqual(parsed.mnemonicWordCount, mnemonic.wordCount)

				XCTAssertEqual(parsed.accounts.count, vector.olympiaWallet.accounts.count)

				for accountIndex in 0 ..< vector.olympiaWallet.accounts.count {
					let expected = vector.olympiaWallet.accounts[accountIndex]
					let actual = parsed.accounts.elements[accountIndex]
					XCTAssertEqual(
						expected,
						actual.toTestVectorAccount()
					)
				}
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
				displayName: .init(rawValue: "Third account"),
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
			"2|0|12^S|AvZppDAk2Q/eaTUczFMCLC+GcI2bPEJpNkBzPFd4I12l|0|With forbidden char in name}~H|A/YzLtwqoPA1w8VNdKOs7HbZtZherdzamVuX1BF3Bdez|",
			"2|1|12^1|}~H|A1STin2yF+LmEPU4mZarY6Bw+0QUZk350V4nWupv5JfG|2|Third account}",
		])

		try doTest(threshold: 60, payloadStrings: [
			"4|0|12^S|AvZppDAk2Q/eaTUczFMCLC+GcI2bPEJpNkBzPFd4I12l|0|With forbid",
			"4|1|12^den char in name}~H|A/YzLtwqoPA1w8VNdKOs7HbZtZherdzamVuX1BF3",
			"4|2|12^Bdez|1|}~H|A1STin2yF+LmEPU4mZarY6Bw+0QUZk350V4nWupv5JfG|2|Th",
			"4|3|12^ird account}",
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
