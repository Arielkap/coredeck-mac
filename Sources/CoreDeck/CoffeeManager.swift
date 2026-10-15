import Foundation
import SwiftUI
import Combine
import IOKit.pwr_mgt

public enum CoffeeDuration: String, CaseIterable, Sendable, Identifiable {
    case indefinite = "indefinite"
    case minutes15 = "15m"
    case minutes30 = "30m"
    case minutes60 = "1h"
    case minutes120 = "2h"
    
    public var id: String { rawValue }
    
    public var seconds: Int? {
        switch self {
        case .indefinite: return nil
        case .minutes15: return 15 * 60
        case .minutes30: return 30 * 60
        case .minutes60: return 60 * 60
        case .minutes120: return 120 * 60
        }
    }
    
    public func title(lang: AppLanguage) -> String {
        switch self {
        case .indefinite:
            return lang == .en ? "Indefinite (Until toggled off)" : "Bez limitu (Do wyłączenia)"
        case .minutes15:
            return lang == .en ? "15 Minutes (Espresso)" : "15 Minut (Espresso)"
        case .minutes30:
            return lang == .en ? "30 Minutes" : "30 Minut"
        case .minutes60:
            return lang == .en ? "1 Hour" : "1 Godzina"
        case .minutes120:
            return lang == .en ? "2 Hours" : "2 Godziny"
        }
    }
    
    public var shortBadge: String {
        switch self {
        case .indefinite: return "∞"
        case .minutes15: return "15m"
        case .minutes30: return "30m"
        case .minutes60: return "1h"
        case .minutes120: return "2h"
        }
    }
}

@MainActor
public final class CoffeeManager: ObservableObject {
    public static let shared = CoffeeManager()
    
    @Published public private(set) var isActive: Bool = false
    @Published public private(set) var currentDuration: CoffeeDuration = .indefinite
    @Published public private(set) var remainingSeconds: Int? = nil
    
    private var assertionID: IOPMAssertionID = 0
    private var countdownTimer: AnyCancellable?
    
    private init() {}
    
    deinit {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
        }
    }
    
    public func toggle(duration: CoffeeDuration = .indefinite) {
        if isActive {
            stop()
        } else {
            start(duration: duration)
        }
    }
    
    public func start(duration: CoffeeDuration = .indefinite) {
        releaseAssertion()
        
        let reason = "CoreDeck: Coffee Mode Active" as CFString
        let success = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleDisplaySleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &assertionID
        )
        
        if success == kIOReturnSuccess {
            self.isActive = true
            self.currentDuration = duration
            self.remainingSeconds = duration.seconds
            startTimer()
        } else {
            self.isActive = false
            self.assertionID = 0
        }
    }
    
    public func stop() {
        countdownTimer?.cancel()
        countdownTimer = nil
        releaseAssertion()
        self.isActive = false
        self.remainingSeconds = nil
    }
    
    private func releaseAssertion() {
        if assertionID != 0 {
            IOPMAssertionRelease(assertionID)
            assertionID = 0
        }
    }
    
    private func startTimer() {
        countdownTimer?.cancel()
        guard let initial = remainingSeconds else {
            countdownTimer = nil
            return
        }
        
        var current = initial
        countdownTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                current -= 1
                if current <= 0 {
                    self.stop()
                } else {
                    self.remainingSeconds = current
                }
            }
    }
    
    public func formattedRemaining(lang: AppLanguage) -> String {
        guard let secs = remainingSeconds else {
            return lang == .en ? "Awake (Infinite)" : "Czuwa (Bez limitu)"
        }
        let mins = secs / 60
        let s = secs % 60
        if mins >= 60 {
            let hours = mins / 60
            let remMins = mins % 60
            return String(format: "%dh %02dm", hours, remMins)
        } else {
            return String(format: "%02d:%02d", mins, s)
        }
    }
    
    public func statusSubtitle(lang: AppLanguage) -> String {
        if !isActive {
            return lang == .en ? "Display sleep enabled (normal)" : "Uśpienie ekranu aktywne"
        }
        if let formatted = remainingSeconds {
            let mins = formatted / 60
            let secs = formatted % 60
            return lang == .en ? "Display awake for \(String(format: "%02d:%02d", mins, secs))" : "Ekran nie zaśnie przez \(String(format: "%02d:%02d", mins, secs))"
        } else {
            return lang == .en ? "Display & system will stay awake" : "Ekran i system nie zasną (∞)"
        }
    }
}
