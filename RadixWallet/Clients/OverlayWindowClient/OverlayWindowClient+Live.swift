// MARK: - OverlayWindowClient + DependencyKey
extension OverlayWindowClient: DependencyKey {
	static let liveValue: Self = {
		let contentItems = AsyncPassthroughSubject<Item.Content>()
		let statusItems = AsyncPassthroughSubject<Item.Status>()
		let alertActions = AsyncPassthroughSubject<(action: Item.AlertAction, id: Item.AlertState.ID)>()
		let fullScreenActions = AsyncPassthroughSubject<(action: FullScreenAction, id: FullScreenID)>()
		let sheetActions = AsyncPassthroughSubject<(action: SheetAction, id: SheetID)>()
		let isContentUserInteractionEnabled = AsyncPassthroughSubject<Bool>()
		let isStatusUserInteractionEnabled = AsyncPassthroughSubject<Bool>()

		@Dependency(\.errorQueue) var errorQueue
		@Dependency(\.pasteboardClient) var pasteBoardClient

		errorQueue.errors().map { error in
			if let sargonError = error as? SargonError {
				#if DEBUG
				let message = switch sargonError {
				case .NfcSessionLostTagConnection:
					"Lost NFC Connection, please retry"
				case .WrongArculusCard:
					"Wrong Arculus Card was used, either it is a different card or the card has a different seed phrase configured"
				default:
					error.localizedDescription
				}
				#else

				let message = switch sargonError {
				case .NfcSessionLostTagConnection:
					"Lost NFC Connection, please retry"
				case .WrongArculusCard:
					"Wrong Arculus Card was used, either it is a different card or the card has a different seed phrase configured"
				default:
					L10n.Error.emailSupportMessage(sargonError.errorCode)
				}
				#endif
				return Item.Status.alert(.init(
					title: { TextState(L10n.Common.errorAlertTitle) },
					actions: {
						ButtonState(role: .cancel, action: .dismissed) {
							TextState(L10n.Common.cancel)
						}
						ButtonState(action: .emailSupport(additionalInfo: error.localizedDescription)) { TextState(L10n.Error.emailSupportButtonTitle)
						}
					},
					message: { TextState(message) }
				))
			} else {
				return Item.Status.alert(.init(
					title: { TextState(L10n.Common.errorAlertTitle) },
					message: { TextState(error.localizedDescription) }
				))
			}
		}
		.subscribe(statusItems)

		pasteBoardClient.copyEvents().map { _ in Item.Status.hud(.copied) }.subscribe(statusItems)

		let scheduleAlertAndIgnoreAction: ScheduleAlertAndIgnoreAction = { alert in
			statusItems.send(.alert(alert))
		}

		return .init(
			scheduledContent: { contentItems.eraseToAnyAsyncSequence() },
			scheduledStatus: { statusItems.eraseToAnyAsyncSequence() },
			scheduleAlert: { alert in
				scheduleAlertAndIgnoreAction(alert)
				return await alertActions.first { $0.id == alert.id }?.action ?? .dismissed
			},
			scheduleAlertAndIgnoreAction: scheduleAlertAndIgnoreAction,
			scheduleHUD: { statusItems.send(.hud($0)) },
			scheduleSheet: { sheet in
				contentItems.send(.sheet(sheet))
				return await sheetActions.first { $0.id == sheet.id }?.action ?? .dismiss
			},
			scheduleFullScreen: { fullScreen in
				contentItems.send(.fullScreen(fullScreen))
				return await fullScreenActions.first { $0.id == fullScreen.id }?.action ?? .dismiss
			},
			sendAlertAction: { action, id in alertActions.send((action, id)) },
			sendFullScreenAction: { action, id in fullScreenActions.send((action, id)) },
			sendSheetAction: { action, id in sheetActions.send((action, id)) },
			setIsContentUserIteractionEnabled: { isContentUserInteractionEnabled.send($0) },
			isContentUserInteractionEnabled: { isContentUserInteractionEnabled.eraseToAnyAsyncSequence() },
			setIsStatusUserIteractionEnabled: { isStatusUserInteractionEnabled.send($0) },
			isStatusUserInteractionEnabled: { isStatusUserInteractionEnabled.eraseToAnyAsyncSequence() }
		)
	}()
}

extension OverlayWindowClient.Item.HUD {
	static let copied = Self(text: L10n.AddressAction.copiedToClipboard)
	static let seedPhraseImported = Self(text: L10n.ImportMnemonic.seedPhraseImported)
	static let thankYou = Self(text: "Thank you!")
}
