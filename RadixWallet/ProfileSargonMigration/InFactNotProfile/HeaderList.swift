import Foundation
import Sargon

public typealias DeviceID = UUID

// MARK: - Header + Identifiable
extension Header: Identifiable {
	public typealias ID = ProfileID
}

extension Profile {
	public typealias Header = Sargon.Header
	public typealias HeaderList = NonEmpty<IdentifiedArrayOf<Header>>
}
