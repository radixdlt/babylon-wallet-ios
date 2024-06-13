// MARK: - P2P.Dapp
extension P2P {
	/// Just a namespace
	public enum Dapp {}
}

// From WalletInteraction.swift
extension P2P.Dapp {
	//    public typealias Version = Tagged<Self, UInt>
	/// Temporarily disables Dapp communication.
	/// Should be reverted as soon as we implement [ABW-1872](https://radixdlt.atlassian.net/browse/ABW-1872)
	public static let currentVersion: WalletInteractionVersion = 2
}

// MARK: - SignedAuthChallenge
public struct SignedAuthChallenge: Sendable, Hashable {
	public let challenge: DappToWalletInteractionAuthChallengeNonce
	public let entitySignatures: Set<SignatureOfEntity>
	public init(challenge: DappToWalletInteractionAuthChallengeNonce, entitySignatures: Set<SignatureOfEntity>) {
		self.challenge = challenge
		self.entitySignatures = entitySignatures
	}
}
