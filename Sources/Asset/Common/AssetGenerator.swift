#if DEBUG
import Foundation

public enum AssetGenerator {
	public static var mockAssets: [[any Asset]] {
		[
			[
				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "Bitcoin",
					code: "BTC",
					iconURL: nil
				),

				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "Polkadot",
					code: "DOT",
					iconURL: nil
				),

				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "Ethereum",
					code: "ETH",
					iconURL: nil
				),

				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "Litecoin",
					code: "LTC",
					iconURL: nil
				),

				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "Solana",
					code: "SOL",
					iconURL: nil
				),

				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "Tether",
					code: "USDT",
					iconURL: nil
				),

				FungibleToken.xrd,
				FungibleToken(
					address: .random,
					totalSupplyAttos: .init(stringLiteral: .random),
					totalMintedAttos: .init(stringLiteral: .random),
					totalBurntAttos: .init(stringLiteral: .random),
					tokenDescription: nil,
					name: "XRP token",
					code: "XRP",
					iconURL: nil
				),
			],
			[
				NonFungibleToken(address: .random, iconURL: "nft"),
				NonFungibleToken(address: .random, iconURL: "nft"),
				NonFungibleToken(address: .random, iconURL: "nft"),
			],
		]
	}
}
#endif
