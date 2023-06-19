import CasePaths
import Foundation

/// Based on https://github.com/radixdlt/radixdlt-scrypto/blob/9ecc54ee658c77e5fc4e6776b06286c01ed70a35/radix-engine-common/src/data/manifest/model/manifest_expression.rs#L11
public enum ManifestExpression: String, Sendable, Codable, Hashable, ValueProtocol {
	// Type name, used as a discriminator
	public static let kind: ManifestASTValueKind = .expression
	public static var casePath: CasePath<ManifestASTValue, Self> = /ManifestASTValue.expression

	case entireWorktop = "ENTIRE_WORKTOP"
	case entireAuthZone = "ENTIRE_AUTH_ZONE"
}
