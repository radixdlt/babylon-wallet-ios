

// MARK: Public
extension ProfileStore {
	/// The current network if any
	public func network() throws -> Profile.Network {
		try profile.network(id: profile.networkID)
	}

	/// A multicasting replaying AsyncSequence of distinct Profile.
	public func values() -> AnyAsyncSequence<Profile> {
		_lens { $0 }
	}

	/// A multicasting replaying AsyncSequence of distinct Accounts for the currently selected network.
	public func accountValues() -> AnyAsyncSequence<Profile.Network.Accounts> {
		_lens {
			$0.network?.getAccounts()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Personas for the currently selected network.
	public func personaValues() -> AnyAsyncSequence<Profile.Network.Personas> {
		_lens {
			$0.network?.getPersonas()
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Gateways
	public func currentGatewayValues() -> AnyAsyncSequence<Radix.Gateway> {
		_lens {
			$0.appPreferences.gateways.current
		}
	}

	/// A multicasting replaying AsyncSequence of distinct Gateways
	public func gatewaysValues() -> AnyAsyncSequence<Gateways> {
		_lens {
			$0.appPreferences.gateways
		}
	}

	/// A multicasting replaying AsyncSequence of distinct FactorSources
	public func factorSourcesValues() -> AnyAsyncSequence<FactorSources> {
		_lens {
			$0.factorSources
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
