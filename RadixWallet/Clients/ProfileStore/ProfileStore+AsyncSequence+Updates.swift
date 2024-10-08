

// MARK: Public
extension ProfileStore {
	/// The current network if any
	public func network() throws -> ProfileNetwork {
		try profile.network(id: profile.networkID)
	}

	/// A multicasting replaying AsyncSequence of distinct Profile.
	public func values() -> AnyAsyncSequence<Profile> {
		_lens { $0 }
	}

	/// A multicasting replaying AsyncSequence of distinct Accounts for the currently selected network.
	public func accountValues() -> AnyAsyncSequence<Accounts> {
		_lens {
			$0.network?.getAccounts()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Personas for the currently selected network.
	public func personaValues() -> AnyAsyncSequence<Personas> {
		_lens {
			$0.network?.getPersonas()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Personas for the currently selected network.
	public func hiddenResourcesValues() -> AnyAsyncSequence<[ResourceIdentifier]> {
		_lens {
			$0.network?.getHiddenResources()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Gateways
	public func currentGatewayValues() -> AnyAsyncSequence<Gateway> {
		_lens {
			$0.appPreferences.gateways.current
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Gateways
	public func gatewaysValues() -> AnyAsyncSequence<SavedGateways> {
		_lens {
			$0.appPreferences.gateways
		}
	}

	/// A multicasting replaying AsyncSequence of distinct FactorSources
	public func factorSourcesValues() -> AnyAsyncSequence<FactorSources> {
		_lens {
			$0.factorSources.asIdentified()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct AppPreferences.
	public func appPreferencesValues() -> AnyAsyncSequence<AppPreferences> {
		_lens {
			$0.appPreferences
		}
	}

	/// A multicasting replaying AsyncSequence of distinct AuthorizedDapp for the currently selected network.
	public func authorizedDappValues() -> AnyAsyncSequence<AuthorizedDapps> {
		_lens {
			$0.network?.getAuthorizedDapps()
		}
	}

	@_disfavoredOverload
	private func lens<Property>(
		_ keyPath: KeyPath<Profile, Property?>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		_lens { $0[keyPath: keyPath] }
	}

	private func lens<Property>(
		_ keyPath: KeyPath<Profile, Property>
	) -> AnyAsyncSequence<Property> where Property: Sendable & Equatable {
		_lens { $0[keyPath: keyPath] }
	}
}
