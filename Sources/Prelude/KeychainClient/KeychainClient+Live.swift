import Dependencies
import Foundation
import KeychainAccess

// MARK: - KeychainClient + DependencyKey
extension KeychainClient: DependencyKey {
	public static let liveValue: Self = .liveValue()

	@_spi(KeychainInternal)
	public static func liveValue(actor: KeychainActor = .shared) -> Self {
		Self(
			getServiceAndAccessGroup: {
				let (service, accessGroup) = actor.getServiceAndAccessGroup()
				return KeychainServiceAndAccessGroup(service: service, accessGroup: accessGroup)
			},
			containsDataForKey: { key, showAuthPrompt in
				try await actor.contains(key, showAuthPrompt: showAuthPrompt)
			},
			setDataWithoutAuthForKey: { data, key, attributes in
				try await actor.setDataWithoutAuth(
					data,
					forKey: key,
					attributes: attributes
				)
			},
			setDataWithAuthForKey: { data, key, attributes in
				try await actor.setDataWithAuth(
					data,
					forKey: key,
					attributes: attributes
				)
			},
			getDataWithoutAuthForKeySetIfNil: { key, ifNilSet in
				try await actor.getDataWithoutAuthForKeySetIfNil(
					forKey: key,
					ifNilSet: ifNilSet
				)
			},
			getDataWithAuthForKeySetIfNil: { key, authenticationPrompt, ifNilSet in
				try await actor.getDataWithAuthForKeySetIfNil(
					forKey: key,
					authenticationPrompt: authenticationPrompt,
					ifNilSet: ifNilSet
				)
			},
			getDataWithoutAuthForKey: {
				try await actor.getDataWithoutAuth(forKey: $0)
			},
			getDataWithAuthForKey: { key, authenticationPrompt in
				try await actor.getDataWithAuth(
					forKey: key,
					authenticationPrompt: authenticationPrompt
				)
			},
			removeDataForKey: {
				try await actor.removeData(forKey: $0)
			},
			removeAllItems: {
				try await actor.removeAllItems()
			}
		)
	}
}
