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
		let accounts: OrderedSet<OlympiaAccountToMigrate>
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
	public enum Separator: Sendable, Hashable, CaseIterable {
		static let inter = "~"
		static let intra = "|"
		static let headerEnd = "^"
		public static let allCases: [String] = [
			Self.inter, Self.inter, Self.headerEnd,
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
			public let accounts: OrderedSet<Account>
			public let rest: NonEmptyString?
		}

		public enum Account: Sendable, Hashable {
			case raw(Raw)
			case parsed(Olympia.Parsed.Account)
			public struct Raw: Sendable, Hashable, Codable {
				public let accountType: Olympia.AccountType
				public let publicKeyCompressedBase64: String
				public let addressIndex: Int
				public let name: String?
			}
		}
	}
}

// MARK: - Olympia.Export.Payload.Account + Codable
extension Olympia.Export.Payload.Account: Codable {
	public func encode(to encoder: Encoder) throws {
		switch self {
		case .parsed: fatalError()
		case let .raw(raw):
			try raw.encode(to: encoder)
		}
	}

	public init(from decoder: Decoder) throws {
		fatalError()
	}
}

// MARK: - Olympia.AccountType + Codable
extension Olympia.AccountType: Codable {}

// MARK: - TestVector
struct TestVector: Codable, Sendable, Hashable {
	let testID: Int
	let olympiaWallet: OlympiaWallet
	let payloadSizeThreshold: Int
	let payloads: [String]

	struct OlympiaWallet: Codable, Hashable {
		let mnemonic: String
		let accounts: [Olympia.Export.Payload.Account.Raw]
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
	}

	public static func deserializeHeader(payload: NonEmptyString) throws -> Olympia.Export.Payload.Header {
		try deserializeHeaderAndContent(payload: payload).header
	}

	private static func deserializeHeaderAndContent(
		payload payloadNonEmpty: NonEmptyString
	) throws -> (header: Olympia.Export.Payload.Header, content: NonEmptyString) {
		var payload = payloadNonEmpty.rawValue

		guard payload.contains(Olympia.Export.Separator.headerEnd) else {
			throw Error.failedToParseHeaderDoesNotContainEndSeparator
		}

		guard
			case let components = payload.split(
				separator: Olympia.Export.Separator.headerEnd
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
			case let headerComponents = headerComponent.split(separator: Olympia.Export.Separator.intra),
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
		let components = accountComponent.split(separator: Olympia.Export.Separator.intra)
		guard components.count == 4 else {
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

		let maybeName = NonEmptyString(rawValue: String(components[3]))

		let path = try LegacyOlympiaBIP44LikeDerivationPath(index: bip44LikeAddressIndex)

		let account = Olympia.Parsed.Account(
			accountType: accountType,
			publicKey: publicKey,
			displayName: maybeName,
			addressIndex: bip44LikeAddressIndex
		)

		return .account(account)
	}

	private static func deserialize(payload: NonEmptyString, rest maybeRest: NonEmptyString?) throws -> Olympia.Export.Payload {
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
				separator: Olympia.Export.Separator.inter
			),
			accountComponentsAndMaybeRest.allSatisfy({ !$0.isEmpty })
		else {
			throw Error.failedToParsePayloadDidNotContainHeaderAndContent
		}

		var accounts: OrderedSet<Olympia.Export.Payload.Account> = .init()
		var rest: NonEmptyString?
		for accountComponent in accountComponentsAndMaybeRest {
			guard let accountOrRest = try _deserializeAccount(accountComponent: String(accountComponent)) else {
				continue
			}
			switch accountOrRest {
			case let .account(account):
				accounts.append(.parsed(account))
			case let .rest(_rest):
				rest = _rest
			}
		}

		return .init(header: header, contents: .init(accounts: accounts, rest: rest))
	}

	public static func deserialize(payloads payloadStrings: NonEmpty<[NonEmptyString]>) throws -> Olympia.Parsed {
		var accounts: OrderedSet<OlympiaAccountToMigrate> = .init()
		var mnemonicWordCount: BIP39.WordCount?

		var rest: NonEmptyString?
		for payloadString in payloadStrings.rawValue {
			let payload = try Self.deserialize(payload: payloadString, rest: rest)
			if mnemonicWordCount == nil {
				mnemonicWordCount = BIP39.WordCount(wordCount: payload.header.mnemonicWordCount)!
			}
			rest = payload.contents.rest
		}

		return .init(
			mnemonicWordCount: mnemonicWordCount!,
			accounts: accounts
		)
	}

	public static func serialize(
		wordCount: Int,
		accounts: [Olympia.Export.Payload.Account.Raw],
		payloadSizeThreshold: Int
	) throws -> [String] {
		// 1. First serialize each account
		let serializedAccounts: [String] = accounts.map { (account: Olympia.Export.Payload.Account.Raw) -> String in

			let sanitizedAccountName = {
				if let name = account.name {
					var truncated = String(name.prefix(30))
					let forbiddenCharacters: [String] = Olympia.Export.Separator.allCases
					for forbiddenChar in forbiddenCharacters {
						truncated = truncated.replacingOccurrences(of: forbiddenChar, with: Olympia.Export.accountNameForbiddenCharReplacement)
					}
					return truncated
				} else {
					return ""
				}
			}()

			return [
				account.accountType.rawValue,
				account.publicKeyCompressedBase64,
				"\(account.addressIndex)",
				sanitizedAccountName,
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
		let payloads: [String] = contentsOfPayloads.enumerated().map { payloadIndex, payloadContent in
			//            let header = Olympia.Export.Payload.Header(
			//                payloadCount: payloadCount,
			//                payloadIndex: payloadIndex,
			//                mnemonicWordCount: wordCount
			//            )

			// Construct header, end it with `headerEnd` seperator
			let header: String = [payloadCount, payloadIndex, wordCount].map { "\($0)" }.joined(separator: Olympia.Export.Separator.inter) + Olympia.Export.Separator.headerEnd

			let payload: String = header + payloadContent
			return payload
		}

		// return payloads, being an array of "\(header)\(payloadContent)"
		return payloads
	}
}

// MARK: - ImportLegacyWalletClientTests
final class ImportLegacyWalletClientTests: TestCase {
	func test_generate_tests() throws {
		let numberOfTests = 6
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
			"OK +?-_,.\\)[]\\(!#$%&/*<>=OK",
			"Numbers are allowed 0123456789",
		]
		let numberOfAccounts = [1, 5, 10, 15, 30, 50, 100]
		let tests: [TestVector] = try (0 ..< numberOfTests).map { (testID: Int) -> TestVector in
			let wordCount = BIP39.WordCount.allCases[testID % BIP39.WordCount.allCases.count]
			let mnemonic = try Mnemonic.generate(wordCount: wordCount)
			let hdRoot = try mnemonic.hdRoot()
			let payloadSizeThreshold = payloadSizes[testID % payloadSizes.count]
			let numberOfAccounts = numberOfAccounts[testID % numberOfAccounts.count]

			let accounts: [Olympia.Export.Payload.Account.Raw] = try (0 ..< numberOfAccounts).map { (accountIndex: Int) -> Olympia.Export.Payload.Account.Raw in

				let accountRND = testID * accountIndex
				let name: String? = accountNames[accountIndex % accountNames.count]
				let accountType: Olympia.AccountType = (accountRND % 2) == 0 ? .software : .hardware
				let path = try LegacyOlympiaBIP44LikeDerivationPath(index: Profile.Network.NextDerivationIndices.Index(accountIndex))
				let publicKey = try hdRoot.derivePrivateKey(path: path.fullPath, curve: SECP256K1.self).publicKey
				let publicKeyCompressed = publicKey.compressedRepresentation
				assert(publicKeyCompressed.count == 33)
				assert(publicKeyCompressed[0] == 0x02 || publicKeyCompressed[0] == 0x03)
				return Olympia.Export.Payload.Account.Raw(
					accountType: accountType,
					publicKeyCompressedBase64: publicKeyCompressed.base64EncodedString(),
					addressIndex: accountIndex,
					name: name
				)
			}

			let payloads: [String] = try CAP33.serialize(
				wordCount: wordCount.rawValue,
				accounts: accounts,
				payloadSizeThreshold: payloadSizeThreshold
			)

			return .init(
				testID: testID, olympiaWallet: .init(
					mnemonic: mnemonic.phrase,
					accounts: accounts
				), payloadSizeThreshold: payloadSizeThreshold,
				payloads: payloads
			)
		}

		let jsonEncoder = JSONEncoder()
		jsonEncoder.outputFormatting = .prettyPrinted
		let testJSON = try jsonEncoder.encode(tests)
		print("🔮 generated #\(tests.count) tests:")
		print(String(data: testJSON, encoding: .utf8)!)
		print("✅ success")
	}
}
