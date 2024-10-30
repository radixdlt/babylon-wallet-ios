import Foundation
import RegexBuilder
import Sargon
import SwiftUI

extension Olympia {
	enum Export {}
	struct Parsed: Sendable, Hashable {
		let mnemonicWordCount: BIP39WordCount
		let accounts: NonEmpty<OrderedSet<Olympia.Parsed.ParsedAccount>>

		struct ParsedAccount: Sendable, Hashable {
			let accountType: Olympia.AccountType
			let publicKey: Secp256k1PublicKey
			let displayName: NonEmptyString?
			let addressIndex: HdPathComponent
		}
	}
}

extension Olympia.Export {
	static let accountNameForbiddenCharReplacement = "_"
	static let accountNameMaxLength = Account.nameMaxLength

	enum Separator: Sendable, Hashable, CaseIterable {
		static let inter = "~"
		static let intra = "^"
		static let headerEnd = "]"
		static let accountNameEnd = "}"

		static let allCases: [String] = [
			inter, intra, headerEnd, accountNameEnd,
		]

		static var regex: some RegexComponent {
			ChoiceOf {
				inter
				intra
				headerEnd
				accountNameEnd
			}
		}
	}

	struct Payload: Sendable, Hashable {
		let header: Header
		let contents: Contents

		struct Header: Sendable, Hashable {
			let payloadCount: Int
			let payloadIndex: Int
			let mnemonicWordCount: Int
		}

		struct Contents: Sendable, Hashable {
			let accounts: OrderedSet<Olympia.Parsed.ParsedAccount>
			let rest: NonEmptyString?
		}
	}
}

// MARK: - CAP33
enum CAP33 {
	static func deserializeHeader(payload: NonEmptyString) throws -> Olympia.Export.Payload.Header {
		try deserializeHeaderAndContent(payload: payload).header
	}

	static func deserialize(
		payloads payloadStrings: NonEmpty<OrderedSet<NonEmptyString>>
	) throws -> Olympia.Parsed {
		var accounts: OrderedSet<Olympia.Parsed.ParsedAccount> = []
		var mnemonicWordCount: BIP39WordCount? = nil
		var rest: NonEmptyString? = nil

		for payloadString in payloadStrings.rawValue.elements {
			let payload = try _deserialize(payload: payloadString, rest: rest)
			if mnemonicWordCount == nil {
				mnemonicWordCount = BIP39WordCount(wordCount: payload.header.mnemonicWordCount)!
			}
			accounts.append(contentsOf: payload.contents.accounts)
			rest = payload.contents.rest
		}

		guard let nonEmpty = NonEmpty<OrderedSet<Olympia.Parsed.ParsedAccount>>(rawValue: accounts) else {
			throw ParseFailure.anyAccount
		}

		return .init(
			mnemonicWordCount: mnemonicWordCount!,
			accounts: nonEmpty
		)
	}
}

// MARK: - Helpers

// MARK: -
extension CAP33 {
	// MARK: Parse Header & Content
	static func deserializeHeaderAndContent(
		payload payloadNonEmpty: NonEmptyString
	) throws -> (header: Olympia.Export.Payload.Header, content: NonEmptyString) {
		let payload = payloadNonEmpty.rawValue

		guard payload.contains(Olympia.Export.Separator.headerEnd) else {
			throw ParseFailure.headerDoesNotContainEndSeparator
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
			throw ParseFailure.payloadDidNotContainHeaderAndContent
		}
		guard !headerComponent.isEmpty else {
			throw ParseFailure.headerCannotBeEmpty
		}

		guard !components[1].isEmpty else {
			throw ParseFailure.headerContentCannotBeEmpty
		}

		guard
			case let headerComponents = headerComponent.split(
				separator: Olympia.Export.Separator.intra,
				omittingEmptySubsequences: true
			),
			headerComponents.count == 3,
			headerComponents.allSatisfy({ !$0.isEmpty })
		else {
			throw ParseFailure.headerDoesNotContainThreeComponents
		}

		guard let payloadCount = Int(headerComponents[0]) else {
			throw ParseFailure.headerDoesNotContainPayloadCount
		}

		guard let payloadIndex = Int(headerComponents[1]) else {
			throw ParseFailure.headerDoesNotContainPayloadIndex
		}

		guard let mnemonicWordCount = Int(headerComponents[2]) else {
			throw ParseFailure.headerDoesNotContainMnemonicWordCount
		}

		let header = Olympia.Export.Payload.Header(
			payloadCount: payloadCount,
			payloadIndex: payloadIndex,
			mnemonicWordCount: mnemonicWordCount
		)

		return (header: header, content: content)
	}

	enum AccountOrRest {
		case account(Olympia.Parsed.ParsedAccount)
		case rest(NonEmptyString)
	}

	// MARK: Parse Account
	private static func _deserializeAccount(
		accountComponent: String
	) throws -> AccountOrRest {
		let components = accountComponent.split(
			separator: Olympia.Export.Separator.intra,
			omittingEmptySubsequences: true // account name is always suffix with an `accountNameEnd`
		)

		guard components.count == 4, components[3].hasSuffix(Olympia.Export.Separator.accountNameEnd) else {
			if let rest = NonEmptyString(rawValue: accountComponent) {
				return .rest(rest)
			} else {
				assertionFailure("Empty rest found in account component")
				throw ParseFailure.accountNameDidNotEndWithExpectedSeparator
			}
		}

		guard
			components[0].count == 1,
			let accountType = Olympia.AccountType(rawValue: String(components[0]))
		else {
			throw ParseFailure.accountBadAccountTypeValue
		}
		guard
			case let publicKeyCompressedBase64 = String(components[1]),
			let publicKeyData = Data(base64Encoded: publicKeyCompressedBase64)
		else {
			throw ParseFailure.accountPublicKeyInvalidBase64String
		}

		guard publicKeyData.count == 33 else {
			throw ParseFailure.accountPublicKeyInvalidByteCount
		}

		let publicKey: Secp256k1PublicKey
		do {
			publicKey = try Secp256k1PublicKey(bytes: publicKeyData)
		} catch {
			throw ParseFailure.accountPublicKeyInvalidSecp256k1PublicKey
		}

		guard let bip44LikeAddressIndex = UInt32(components[2]) else {
			throw ParseFailure.accountAddressIndex
		}

		guard
			case var accountName = String(components[3]),
			accountName.hasSuffix(Olympia.Export.Separator.accountNameEnd)
		else {
			throw ParseFailure.accountNameDidNotEndWithExpectedSeparator
		}

		accountName.removeLast()

		let maybeName = NonEmptyString(rawValue: accountName)

		let account = try Olympia.Parsed.ParsedAccount(
			accountType: accountType,
			publicKey: publicKey,
			displayName: maybeName,
			addressIndex: HdPathComponent(localKeySpace: bip44LikeAddressIndex, keySpace: .unsecurified(isHardened: true))
		)

		return .account(account)
	}

	static func _sanitize(name: NonEmptyString?) -> String {
		guard let name else { return "" }

		let result = String(name
			.prefix(Olympia.Export.accountNameMaxLength))
			.replacing(
				Olympia.Export.Separator.regex,
				with: Olympia.Export.accountNameForbiddenCharReplacement
			)

		return String(result)
	}

	static func _deserialize(payloadsStrings: [String]) throws -> Olympia.Parsed {
		try deserialize(
			payloads: .init(rawValue: OrderedSet(
				uncheckedUniqueElements: payloadsStrings.compactMap(NonEmptyString.init(rawValue:))
			))!
		)
	}

	// MARK: Parse Payload & Rest
	private static func _deserialize(
		payload: NonEmptyString,
		rest maybeRest: NonEmptyString?
	) throws -> Olympia.Export.Payload {
		let (header, contentNonEmpty) = try deserializeHeaderAndContent(payload: payload)
		let content = (maybeRest?.rawValue ?? "") + contentNonEmpty.rawValue

		guard
			case let accountComponentsAndMaybeRest = content.split(
				separator: Olympia.Export.Separator.inter,
				omittingEmptySubsequences: true
			),
			accountComponentsAndMaybeRest.allSatisfy({ !$0.isEmpty })
		else {
			throw ParseFailure.payloadDidNotContainHeaderAndContent
		}

		var accounts: OrderedSet<Olympia.Parsed.ParsedAccount> = .init()

		for (index, accountComponent) in accountComponentsAndMaybeRest.enumerated() {
			let accountOrRest = try _deserializeAccount(
				accountComponent: String(accountComponent)
			)
			switch accountOrRest {
			case let .account(account):
				accounts.append(account)

			case let .rest(rest):
				guard index == accountComponentsAndMaybeRest.count - 1 else {
					throw ParseFailure.payloadFoundPartialAccount
				}
				return .init(
					header: header,
					contents: .init(
						accounts: accounts,
						rest: rest
					)
				)
			}
		}

		return .init(
			header: header,
			contents: .init(
				accounts: accounts,
				rest: nil
			)
		)
	}
}

// MARK: CAP33.ParseFailure
extension CAP33 {
	enum ParseFailure: String, Swift.Error, Sendable, Hashable {
		case headerDoesNotContainEndSeparator
		case payloadDidNotContainHeaderAndContent
		case anyAccount
		case headerCannotBeEmpty
		case headerContentCannotBeEmpty
		case headerDoesNotContainThreeComponents
		case headerDoesNotContainPayloadCount
		case headerDoesNotContainPayloadIndex
		case headerDoesNotContainMnemonicWordCount
		case payloadsFoundDuplicates
		case accountBadAccountTypeValue
		case accountPublicKeyInvalidBase64String
		case accountPublicKeyInvalidByteCount
		case accountPublicKeyInvalidSecp256k1PublicKey
		case accountAddressIndex
		case accountNameDidNotEndWithExpectedSeparator
		case payloadFoundPartialAccount
	}
}
