

// MARK: Public
extension ProfileStore {
	/// The current network if any
	func network() throws -> ProfileNetwork {
		let profile = self.profile()
		return try profile.network(id: profile.networkID)
	}

	/// A multicasting replaying AsyncSequence of distinct Profile.
	func values() -> AnyAsyncSequence<Profile> {
		_lens { $0 }
	}

	/// A multicasting replaying AsyncSequence of distinct Accounts for the currently selected network.
	func accountValues() -> AnyAsyncSequence<Accounts> {
		_lens {
			$0.network?.getAccounts()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Personas for the currently selected network.
	func personaValues() -> AnyAsyncSequence<Personas> {
		_lens {
			$0.network?.getPersonas()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Personas for the currently selected network.
	func hiddenResourcesValues() -> AnyAsyncSequence<[ResourceIdentifier]> {
		_lens {
			$0.network?.getHiddenResources()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Gateways
	func currentGatewayValues() -> AnyAsyncSequence<Gateway> {
		_lens {
			$0.appPreferences.gateways.current
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Gateways
	func gatewaysValues() -> AnyAsyncSequence<SavedGateways> {
		_lens {
			$0.appPreferences.gateways
		}
	}

	/// A multicasting replaying AsyncSequence of distinct FactorSources
	func factorSourcesValues() -> AnyAsyncSequence<FactorSources> {
		_lens {
			$0.factorSources.asIdentified()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct AppPreferences.
	func appPreferencesValues() -> AnyAsyncSequence<AppPreferences> {
		_lens {
			$0.appPreferences
		}
	}

	/// A multicasting replaying AsyncSequence of distinct AuthorizedDapp for the currently selected network.
	func authorizedDappValues() -> AnyAsyncSequence<AuthorizedDapps> {
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
