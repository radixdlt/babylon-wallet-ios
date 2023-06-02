import Prelude

extension Profile {
	public struct EntitySecurityStructure {
		public enum PrimaryTag {}
		public struct Role<RoleKind>: Sendable, Hashable, Codable {
			public let factorInstanceID
		}

		public typealias PrimaryRole = Role<PrimaryTag>
		public let primaryRole: PrimaryRole
	}
}
