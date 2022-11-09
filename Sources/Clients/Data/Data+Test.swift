import Dependencies
import Foundation
import XCTestDynamicOverlay

public extension DependencyValues {
	var data: DataEffect {
		get { self[DataEffect.self] }
		set { self[DataEffect.self] = newValue }
	}
}

// MARK: - DataEffect + TestDependencyKey
extension DataEffect: TestDependencyKey {
	public static let previewValue = Self(
		contentsOfURL: { _, _ in Data() }
	)

	public static let testValue = Self(
		contentsOfURL: unimplemented("\(Self.self).contentsOfURL")
	)
}
