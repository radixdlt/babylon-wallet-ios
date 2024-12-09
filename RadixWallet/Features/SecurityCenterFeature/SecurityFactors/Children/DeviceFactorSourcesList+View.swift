// MARK: - DeviceFactorSourcesList.View
extension DeviceFactorSourcesList {
	@MainActor
	struct View: SwiftUI.View {
		let store: StoreOf<DeviceFactorSourcesList>

		var body: some SwiftUI.View {
			WithViewStore(store, observe: { $0 }) { viewStore in
				ScrollView {
					VStack(spacing: .large3) {
						header("Use phone biometrics/PIN to approve")
							.padding(.bottom, .medium3)

						if let main = viewStore.main {
							section(text: "Default", rows: [main])

							if !viewStore.others.isEmpty {
								section(text: "Others", rows: viewStore.others)
							}
						}

						Button("Add Biometrics/PIN") {}
							.buttonStyle(.secondaryRectangular)

						InfoButton(.accounts, label: "Learn about Biometrics/PIN") // TODO: Update
					}
					.padding(.medium3)
					.padding(.bottom, .medium2)
				}
				.background(.app.gray5)
				.radixToolbar(title: "Biometrics/PIN")
				.task {
					store.send(.view(.task))
				}
			}
		}

		private func header(_ text: String) -> some SwiftUI.View {
			Text(text)
				.textStyle(.body1Header)
				.foregroundStyle(.app.gray2)
				.flushedLeft
		}

		private func section(text: String, rows: [State.Row]) -> some SwiftUI.View {
			VStack(spacing: .small1) {
				header(text)

				ForEachStatic(rows) { row in
					card(row)
				}
			}
		}

		private func card(_ row: State.Row) -> some SwiftUI.View {
			FactorSourceCard(
				kind: .instance(factorSource: row.factorSource.asGeneral, kind: .extended(accounts: row.accounts, personas: row.personas)),
				mode: .display,
				messages: [row.message]
			)
			.onTapGesture {}
		}
	}
}

private extension DeviceFactorSourcesList.State {
	var main: Row? {
		rows.first(where: \.factorSource.isExplicitMain)
	}

	var others: [Row] {
		rows
			.filter { !$0.factorSource.isExplicitMain }
			.sorted(by: { l, r in
				let lhs = l.factorSource
				let rhs = r.factorSource
				if lhs.isBDFS, rhs.isBDFS {
					return lhs.common.addedOn < rhs.common.addedOn
				} else {
					return lhs.isBDFS
				}
			})
	}
}

private extension DeviceFactorSourcesList.State.Row {
	var message: FactorSourceCardDataSource.Message {
		switch status {
		case .noProblem:
			.init(text: "This seed phrase has been written down", type: .success)
		case .hasProblem3:
			.init(text: "Write down seed phrase to make this factor recoverable", type: .warning)
		case .hasProblem9:
			.init(text: "This factor has been lost", type: .error)
		}
	}
}
