import AuthorizedDappsClient
import ClientPrelude

extension AuthorizedDappsClient: DependencyKey {
	public typealias Value = AuthorizedDappsClient

	public static let liveValue = Self()
}
