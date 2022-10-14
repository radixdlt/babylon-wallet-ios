import BigInt
import Foundation
import GatewayAPI

// MARK: - FungibleToken
public struct FungibleToken: Asset, Token {
	public let address: ComponentAddress
	public let totalSupplyAttos: BigUInt
	public let totalMintedAttos: BigUInt
	public let totalBurntAttos: BigUInt

	/// An optional desciption of this token.
	public let tokenDescription: String?

	/// Short token name.
	public let name: String?

	/// Token code.
	public let code: String?

	/// Token icon URL.
	public var iconURL: String?

	public init(
		address: ComponentAddress,
		totalSupplyAttos: BigUInt,
		totalMintedAttos: BigUInt,
		totalBurntAttos: BigUInt,
		tokenDescription: String?,
		name: String?,
		code: String?,
		iconURL: String?
	) {
		self.address = address
		self.totalSupplyAttos = totalSupplyAttos
		self.totalMintedAttos = totalMintedAttos
		self.totalBurntAttos = totalBurntAttos
		self.tokenDescription = tokenDescription
		self.name = name
		self.code = code
		self.iconURL = iconURL
	}
}

// MARK: - Convenience
public extension FungibleToken {
	init(
		address: ComponentAddress,
		details: EntityDetailsResponseFungibleDetails
	) {
		self.init(
			address: address,
			totalSupplyAttos: .init(stringLiteral: details.totalSupplyAttos),
			totalMintedAttos: .init(stringLiteral: details.totalMintedAttos),
			totalBurntAttos: .init(stringLiteral: details.totalBurntAttos),
			// TODO: update when API is ready
			tokenDescription: nil,
			name: nil,
			code: nil,
			iconURL: nil
		)
	}
}

// MARK: - FungibleTokenContainer
public struct FungibleTokenContainer: AssetContainer, Equatable {
	public typealias T = FungibleToken
	public let asset: FungibleToken

	/// Token amount held in one account.
	public var amount: Float?
	/// Token worth in currently selected currency.
	public var worth: Float?

	public init(
		asset: FungibleToken,
		amount: Float?,
		worth: Float?
	) {
		self.asset = asset
		self.amount = amount
		self.worth = worth
	}
}

public extension FungibleToken {
	/// The native token of the Radix Ledger
	static let xrd = Self(
		address: "unknown at this point",
        totalSupplyAttos: .init(stringLiteral: "24000000000"),
		totalMintedAttos: .init(stringLiteral: "0"),
		totalBurntAttos: .init(stringLiteral: "0"),
		tokenDescription: "The native token of the Radix Ledger",
		name: "RAD",
		code: "XRD",
		iconURL: nil
	)
}
