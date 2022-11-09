import Dependencies
import Foundation

extension ReadDataEffect: DependencyKey {
	public static let liveValue = Self(
		dataFromURL: { url, options in try Data(contentsOf: url, options: options) }
	)
}
