//
//  Haptics.swift
//  ARDummy
//
//  Created by Adeel Tahir on 26/12/2022.
//

import Foundation
import AudioToolbox

struct Haptics {

    static func weakBoom() {
        AudioServicesPlaySystemSound(1519) // Actuate `Peek` feedback (weak boom)
    }

    static func strongBoom() {
        AudioServicesPlaySystemSound(1520) // Actuate `Pop` feedback (strong boom)
    }

    static func threeWeakBooms() {
        AudioServicesPlaySystemSound(1521) // Actuate `Nope` feedback (series of three weak booms)
    }
}
