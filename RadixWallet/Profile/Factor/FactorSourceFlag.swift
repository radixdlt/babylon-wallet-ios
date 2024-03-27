

public enum FactorSourceFlag: String, Sendable, Hashable, Codable {
	/// Until we have implemented "proper" deletion, we will "flag" a
	/// FactorSource as deleted by the user and hide it, meaning e.g.
	/// that in Multi-Factor Setup flows it will not show up.
	case deletedByUser

	/// Used to mark a "babylon" `.device` FactorSource as "main". All new accounts
	/// and Personas are created using the `main` `DeviceFactorSource`.
	///
	/// We can only ever have one.
	/// We might have zero `main` flags across all  `DeviceFactorSource`s if and only if we have only one  `DeviceFactorSource`s. If we have two or more  `DeviceFactorSource`s one of them MUST
	/// be marked with `main`.
	case main
}
