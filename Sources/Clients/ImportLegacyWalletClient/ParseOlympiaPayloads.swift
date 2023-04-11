import ClientPrelude
import Cryptography

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
	public static let accountNameForbiddenCharReplacement = "_"
	public static let accountNameMaxLength = 30 // sync with profile!
	public enum Separator: Sendable, Hashable, CaseIterable {
		static let inter = "~"
		static let intra = "^"
		static let headerEnd = "]"
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

// MARK: - CAP33
public enum CAP33 {
	public enum Error: String, Swift.Error, Sendable, Hashable {
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

	internal static func deserializeHeaderAndContent(
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

	internal enum AccountOrRest {
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

	private static func _deserialize(
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
			let payload = try Self._deserialize(payload: payloadString, rest: rest)
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

	public static func _sanitize(name: NonEmptyString?) -> String {
		guard let name = name else { return "" }
		var truncated = String(name.rawValue.prefix(30))
		let forbiddenCharacters: [String] = Olympia.Export.Separator.allCases
		for forbiddenChar in forbiddenCharacters {
			truncated = truncated.replacingOccurrences(of: forbiddenChar, with: Olympia.Export.accountNameForbiddenCharReplacement)
		}
		return truncated
	}
}
