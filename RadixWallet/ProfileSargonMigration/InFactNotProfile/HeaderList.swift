import Foundation
import Sargon

public typealias DeviceID = UUID

// MARK: - Sargon.Header + Identifiable
extension Sargon.Header: Identifiable {
	public typealias ID = ProfileID
}

extension Sargon.Profile {
	public typealias Header = Sargon.Header
	public typealias HeaderList = NonEmpty<IdentifiedArrayOf<Sargon.Header>>
}
