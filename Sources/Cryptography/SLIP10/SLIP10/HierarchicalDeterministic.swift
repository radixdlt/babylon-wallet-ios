import Foundation

// MARK: - HierarchicalDeterministic
/// Namespace for Hierarchical Deterministic keys and paths.
public enum HierarchicalDeterministic {}

public typealias HD = HierarchicalDeterministic

// MARK: HD.DerivationError
extension HD {
	public enum DerivationError: Swift.Error, Equatable {
		case curve25519RequiresHardenedPath
		case curve25519LacksPublicParentKeyToPublicChildKeyInSlip10
	}
}
