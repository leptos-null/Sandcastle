//
//  AVAudioSession+State.swift
//  Sandcastle
//
//  Created by Leptos on 3/3/26.
//

#if os(iOS) || os(watchOS) || os(tvOS) || os(visionOS)

import AVFoundation

extension AVAudioSession {
    struct State {
        let category: AVAudioSession.Category
        let mode: AVAudioSession.Mode
        let routeSharingPolicy: AVAudioSession.RouteSharingPolicy
        let categoryOptions: AVAudioSession.CategoryOptions
    }
    
    var state: State {
        .init(
            category: self.category,
            mode: self.mode,
            routeSharingPolicy: self.routeSharingPolicy,
            categoryOptions: self.categoryOptions
        )
    }
    
    func setState(_ state: State) throws {
        try self.setCategory(
            state.category,
            mode: state.mode,
            policy: state.routeSharingPolicy,
            options: state.categoryOptions
        )
    }
}

#endif
