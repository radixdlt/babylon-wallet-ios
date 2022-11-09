import Dependencies
import Foundation

extension DataEffect: DependencyKey {
	public static let liveValue = Self(
		contentsOfURL: { url, options in try Data(contentsOf: url, options: options) }
	)
}
