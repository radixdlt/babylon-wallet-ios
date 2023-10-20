
// MARK: - KeychainClient + DependencyKey
extension KeychainClient: DependencyKey {
	public static let liveValue: Self = .liveValue()

	@_spi(KeychainInternal)
	public static func liveValue(
		keychainHolder: KeychainHolder = .shared
	) -> Self {
		Self(
			getServiceAndAccessGroup: {
				let (service, accessGroup) = keychainHolder.getServiceAndAccessGroup()
				return KeychainServiceAndAccessGroup(service: service, accessGroup: accessGroup)
			},
			containsDataForKey: { key, showAuthPrompt in
				try keychainHolder.contains(key, showAuthPrompt: showAuthPrompt)
			},
			setDataWithoutAuthForKey: { data, key, attributes in
				try keychainHolder.setDataWithoutAuth(
					data,
					forKey: key,
					attributes: attributes
				)
			},
			setDataWithAuthForKey: { data, key, attributes in
				try keychainHolder.setDataWithAuth(
					data,
					forKey: key,
					attributes: attributes
				)
			},
			getDataWithoutAuthForKeySetIfNil: { key, ifNilSet in
				try keychainHolder.getDataWithoutAuth(
					forKey: key,
					ifNilSet: ifNilSet
				)
			},
			getDataWithAuthForKeySetIfNil: { key, authenticationPrompt, ifNilSet in
				try keychainHolder.getDataWithAuth(
					forKey: key,
					authenticationPrompt: authenticationPrompt,
					ifNilSet: ifNilSet
				)
			},
			getDataWithoutAuthForKey: {
				try keychainHolder.getDataWithoutAuth(forKey: $0)
			},
			getDataWithAuthForKey: { key, authenticationPrompt in
				try keychainHolder.getDataWithAuth(
					forKey: key,
					authenticationPrompt: authenticationPrompt
				)
			},
			removeDataForKey: {
				try keychainHolder.removeData(forKey: $0)
			},
			removeAllItems: {
				try keychainHolder.removeAllItems()
			}
		)
	}
}
