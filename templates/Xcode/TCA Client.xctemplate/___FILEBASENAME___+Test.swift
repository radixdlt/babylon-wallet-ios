import ClientPrelude

public extension DependencyValues {
	var ___VARIABLE_dependencyKey___: ___VARIABLE_clientName___ {
		get { self[___VARIABLE_clientName___.self] }
		set { self[___VARIABLE_clientName___.self] = newValue }
	}
}

// MARK: - ___VARIABLE_clientName___ + TestDependencyKey
extension ___VARIABLE_clientName___: TestDependencyKey {
	public static let previewValue = Self()
	public static let testValue = Self()
}
