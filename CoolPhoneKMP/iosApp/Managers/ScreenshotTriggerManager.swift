//
//  ScreenshotTriggerManager.swift
//  hackthon_cool_phone
//
//  Created by leslie liu on 2026/1/17.
//

import Foundation
import UIKit
import Combine

final class ScreenshotTriggerManager: ObservableObject {
    static let shared = ScreenshotTriggerManager()

    @Published var shouldTriggerCall = false

    private var observer: NSObjectProtocol?

    private init() {}

    func start() {
        guard observer == nil else { return }

        observer = NotificationCenter.default.addObserver(
            forName: UIApplication.userDidTakeScreenshotNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            self.shouldTriggerCall = true

            // 让下一次截屏还能再次触发
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.shouldTriggerCall = false
            }
        }
    }

    func stop() {
        if let observer {
            NotificationCenter.default.removeObserver(observer)
            self.observer = nil
        }
    }
}
