import Prelude

// MARK: - AccessController
public struct AccessController: Sendable, Hashable, Codable {
	// FIXME: Replace with AccessControllerAddress from RET?
	public struct Address: Sendable, Hashable, Codable {}

	/// On ledger component address
	public let address: Address

	public let securityStructure: ProfileSnapshot.AppliedSecurityStructure
}

// MARK: - ProfileSnapshot.AppliedSecurityStructure
extension ProfileSnapshot {
	/// A version of `AppliedSecurityStructure` which only contains IDs of factor sources, suitable for storage in Profile Snapshot.
	public typealias AppliedSecurityStructure = AbstractSecurityStructure<FactorInstance.ID>
}
