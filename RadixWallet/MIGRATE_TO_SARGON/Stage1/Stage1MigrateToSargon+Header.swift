import Foundation
import Sargon

// MARK: - Header + Identifiable
extension Header: Identifiable {
	public typealias ID = ProfileID
}

extension ProfileSnapshotVersion {
	public static let minimum = Self(rawValue: 100)!
}

// MARK: - ProfileSnapshotVersion + Comparable
extension ProfileSnapshotVersion: Comparable {}

extension Header {
	public typealias Version = ProfileSnapshotVersion

	public func isVersionCompatible() -> Bool {
		snapshotVersion >= .minimum
	}
}
