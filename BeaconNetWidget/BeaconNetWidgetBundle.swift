//
//  BeaconNetWidgetBundle.swift
//  BeaconNetWidget
//
//  Created by Arsenii Dvornichenko on 26.10.2026.
//

import WidgetKit
import SwiftUI

@main
struct BeaconNetWidgetBundle: WidgetBundle {
    var body: some Widget {
        BeaconNetWidget()
        BeaconNetWidgetControl()
        BeaconNetWidgetLiveActivity()
    }
}
