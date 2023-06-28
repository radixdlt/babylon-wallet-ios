import AsyncExtensions
import ComposableArchitecture
import Dependencies
import DesignSystem
import Resources
import SwiftUI

// MARK: - OverlayWindowClient
public struct OverlayWindowClient: Sendable {
	public var scheduledItems: ScheduledItems
	public var scheduleAlert: ScheduleAlert
	public var scheduleHUD: ScheduleHUD
	public var sendAlertAction: SendAlertAction

	var onAlertAction: OnAlertAction
}

extension OverlayWindowClient {
	public typealias ScheduleAlert = @Sendable (Item.AlertState) -> Void
	public typealias ScheduleHUD = @Sendable (Item.HUD) -> Void
	public typealias SendAlertAction = @Sendable (Item.AlertAction, Item.AlertState.ID) -> Void
	public typealias ScheduledItems = @Sendable () -> AnyAsyncSequence<Item>
	typealias OnAlertAction = @Sendable (Item.AlertState.ID) async -> Item.AlertAction
}

// MARK: OverlayWindowClient.Item
extension OverlayWindowClient {
	public enum Item: Sendable, Hashable {
		public typealias AlertState = ComposableArchitecture.AlertState<AlertAction>
		public enum AlertAction: Equatable {
			case primaryButtonTapped
			case secondaryButtonTapped
			case dismissed
		}

		public struct HUD: Sendable, Hashable {
			public enum Icon: Sendable, Hashable {
				case asset(ImageAsset)
				case system(String)
			}

			public let text: String
			public let icon: Icon?
			public let iconForegroundColor: Color?

			public init(text: String, icon: Icon?, iconForegroundColor: Color?) {
				self.text = text
				self.icon = icon
				self.iconForegroundColor = iconForegroundColor
			}
		}

		case hud(HUD)
		case alert(AlertState)
	}
}

extension OverlayWindowClient {
	public func schedule(hud: Item.HUD) {
		scheduleHUD(hud)
	}

	public func schedule(alert: Item.AlertState) async -> Item.AlertAction {
		scheduleAlert(alert)
		return await onAlertAction(alert.id)
	}

	public func scheduleCopiedItem() {
		schedule(hud:
			.init(
				text: "Copied",
				icon: .system("checkmark.circle.fill"),
				iconForegroundColor: .app.green1
			)
		)
	}
}

// MARK: - ImageAsset + Hashable
extension ImageAsset: Hashable {
	public static func == (lhs: ImageAsset, rhs: ImageAsset) -> Bool {
		lhs.name == rhs.name
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.name)
	}
}

extension DependencyValues {
	public var overlayWindowClient: OverlayWindowClient {
		get { self[OverlayWindowClient.self] }
		set { self[OverlayWindowClient.self] = newValue }
	}
}
