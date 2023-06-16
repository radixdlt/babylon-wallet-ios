import CasePaths
import Foundation

// MARK: - Enum
public struct Enum: ValueProtocol, Sendable, Codable, Hashable {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .enum
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.enum

	// MARK: Stored properties

	public let variant: EnumDiscriminator
	public let fields: [ManifestASTValue]

	// MARK: Init

	public init(_ variant: EnumDiscriminator) {
		self.variant = variant
		self.fields = []
	}

	public init(_ variant: EnumDiscriminator, fields: [ManifestASTValue]) {
		self.variant = variant
		self.fields = fields
	}

	public init(_ variant: EnumDiscriminator.KnownStringDescriminators) {
		self.init(.string(variant))
	}

	public init(_ variant: EnumDiscriminator.KnownStringDescriminators, fields: [ManifestASTValue]) {
		self.init(.string(variant), fields: fields)
	}

	public init(_ variant: UInt8) {
		self.init(.u8(variant))
	}

	public init(_ variant: UInt8, fields: [ManifestASTValue]) {
		self.init(.u8(variant), fields: fields)
	}

	public init(
		_ variant: EnumDiscriminator,
		@ValuesBuilder fields: () throws -> [any ValueProtocol]
	) rethrows {
		try self.init(variant, fields: fields().map { $0.embedValue() })
	}
}

extension Enum {
	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case variant
		case fields
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(variant, forKey: .variant)
		try container.encode(fields, forKey: .fields)
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)
		try self.init(
			container.decode(EnumDiscriminator.self, forKey: .variant),
			fields: container.decodeIfPresent([ManifestASTValue].self, forKey: .fields) ?? []
		)
	}
}

// MARK: - EnumDiscriminator
public enum EnumDiscriminator: Sendable, Codable, Hashable {
	/// Based on: https://github.com/radixdlt/radixdlt-scrypto/blob/birch-d988ac200/transaction/src/manifest/enums.rs
	public enum KnownStringDescriminators: String, CaseIterable, Codable, Sendable {
		case option_None = "Option::None"
		case option_Some = "Option::Some"

		case result_Ok = "Result::Ok"
		case result_Err = "Result::Err"

		case metadata_String = "Metadata::String"
		case metadata_Bool = "Metadata::Bool"
		case metadata_U8 = "Metadata::U8"
		case metadata_U32 = "Metadata::U32"
		case metadata_U64 = "Metadata::U64"
		case metadata_I32 = "Metadata::I32"
		case metadata_I64 = "Metadata::I64"
		case metadata_Decimal = "Metadata::Decimal"
		case metadata_Address = "Metadata::Address"
		case metadata_PublicKey = "Metadata::PublicKey"
		case metadata_NonFungibleGlobalId = "Metadata::NonFungibleGlobalId"
		case metadata_NonFungibleLocalId = "Metadata::NonFungibleLocalId"
		case metadata_Instant = "Metadata::Instant"
		case metadata_Url = "Metadata::Url"
		case metadata_Origin = "Metadata::Origin"
		case metadata_PublicKeyHash = "Metadata::PublicKeyHash"
		case metadata_StringArray = "Metadata::StringArray"
		case metadata_BoolArray = "Metadata::BoolArray"
		case metadata_U8Array = "Metadata::U8Array"
		case metadata_U32Array = "Metadata::U32Array"
		case metadata_U64Array = "Metadata::U64Array"
		case metadata_I32Array = "Metadata::I32Array"
		case metadata_I64Array = "Metadata::I64Array"
		case metadata_DecimalArray = "Metadata::DecimalArray"
		case metadata_AddressArray = "Metadata::AddressArray"
		case metadata_PublicKeyArray = "Metadata::PublicKeyArray"
		case metadata_NonFungibleGlobalIdArray = "Metadata::NonFungibleGlobalIdArray"
		case metadata_NonFungibleLocalIdArray = "Metadata::NonFungibleLocalIdArray"
		case metadata_InstantArray = "Metadata::InstantArray"
		case metadata_UrlArray = "Metadata::UrlArray"
		case metadata_OriginArray = "Metadata::OriginArray"
		case metadata_PublicKeyHashArray = "Metadata::PublicKeyHashArray"

		case accessRule_AllowAll = "AccessRule::AllowAll"
		case accessRule_DenyAll = "AccessRule::DenyAll"
		case accessRule_Protected = "AccessRule::Protected"

		case accessRuleNode_Authority = "AccessRuleNode::Authority"
		case accessRuleNode_ProofRule = "AccessRuleNode::ProofRule"
		case accessRuleNode_AnyOf = "AccessRuleNode::AnyOf"
		case accessRuleNode_AllOf = "AccessRuleNode::AllOf"

		case proofRule_Require = "ProofRule::Require"
		case proofRule_AmountOf = "ProofRule::AmountOf"
		case proofRule_CountOf = "ProofRule::CountOf"
		case proofRule_AllOf = "ProofRule::AllOf"
		case proofRule_AnyOf = "ProofRule::AnyOf"

		case moduleId_Main = "ModuleId::Main"
		case moduleId_Metadata = "ModuleId::Metadata"
		case moduleId_Royalty = "ModuleId::Royalty"
		case moduleId_AccessRules = "ModuleId::AccessRules"

		case resourceMethodAuthKey_Mint = "ResourceMethodAuthKey::Mint"
		case resourceMethodAuthKey_Burn = "ResourceMethodAuthKey::Burn"
		case resourceMethodAuthKey_UpdateNonFungibleData = "ResourceMethodAuthKey::UpdateNonFungibleData"
		case resourceMethodAuthKey_UpdateMetadata = "ResourceMethodAuthKey::UpdateMetadata"
		case resourceMethodAuthKey_Withdraw = "ResourceMethodAuthKey::Withdraw"
		case resourceMethodAuthKey_Deposit = "ResourceMethodAuthKey::Deposit"
		case resourceMethodAuthKey_Recall = "ResourceMethodAuthKey::Recall"

		case nonFungibleIdType_String = "NonFungibleIdType::String"
		case nonFungibleIdType_Integer = "NonFungibleIdType::Integer"
		case nonFungibleIdType_Bytes = "NonFungibleIdType::Bytes"
		case nonFungibleIdType_UUID = "NonFungibleIdType::UUID"

		case accountDefaultDepositRule_Accept = "AccountDefaultDepositRule::Accept"
		case accountDefaultDepositRule_Reject = "AccountDefaultDepositRule::Reject"
		case accountDefaultDepositRule_AllowExisting = "AccountDefaultDepositRule::AllowExisting"

		case resourceDepositRule_Neither = "ResourceDepositRule::Neither"
		case resourceDepositRule_Allowed = "ResourceDepositRule::Allowed"
		case resourceDepositRule_Disallowed = "ResourceDepositRule::Disallowed"

		case publicKey_Secp256k1 = "PublicKey::Secp256k1"
		case publicKey_Ed25519 = "PublicKey::Ed25519"

		case publicKeyHash_Secp256k1 = "PublicKeyHash::Secp256k1"
		case publicKeyHash_Ed25519 = "PublicKeyHash::Ed25519"
	}

	case string(KnownStringDescriminators)
	case u8(UInt8)

	// MARK: Init

	public init(_ discriminator: KnownStringDescriminators) {
		self = .string(discriminator)
	}

	public init(_ discriminator: UInt8) {
		self = .u8(discriminator)
	}
}

extension EnumDiscriminator {
	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	public static let metadataEntry: Self = .u8(0x01)

	/// https://rdxworks.slack.com/archives/C031A0V1A1W/p1683275008777499?thread_ts=1683221252.228129&cid=C031A0V1A1W
	public static let publicKey: Self = .u8(0x09)
}

extension EnumDiscriminator {
	private enum Kind: String, Codable {
		case u8 = "U8"
		case string = "String"
	}

	// MARK: CodingKeys

	private enum CodingKeys: String, CodingKey {
		case type
		case discriminator
	}

	// MARK: Codable

	public func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		switch self {
		case let .u8(discriminator):
			try container.encode(Kind.u8, forKey: .type)
			try container.encode(String(discriminator), forKey: .discriminator)
		case let .string(discriminator):
			try container.encode(Kind.string, forKey: .type)
			try container.encode(discriminator, forKey: .discriminator)
		}
	}

	public init(from decoder: Decoder) throws {
		// Checking for type discriminator
		let container = try decoder.container(keyedBy: CodingKeys.self)

		let type = try container.decode(Kind.self, forKey: .type)
		switch type {
		case .u8:
			self = try .u8(decodeAndConvertToNumericType(container: container, key: .discriminator))
		case .string:
			self = try .string(container.decode(KnownStringDescriminators.self, forKey: .discriminator))
		}
	}
}
