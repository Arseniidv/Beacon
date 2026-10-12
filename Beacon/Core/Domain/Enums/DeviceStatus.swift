import Foundation
import SwiftUI

enum DeviceStatus:String,Codable,Hashable{
    case free = "Свободен"
    case busy = "Занятой"
    case offline = "Недоступен"

    public var color:Color{
        switch self{
        case .free:
            return AppColors.statusSuccess
        case .busy:
            return AppColors.statusDanger
        case .offline:
            return AppColors.statusOffline
        }
    }
}
