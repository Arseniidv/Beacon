import Foundation
import SwiftUI

public struct Device:Identifiable,Codable,Hashable{
    public let name:String
    public let ip:String
    public let ping:Int
    public let macAdress:String
    public let status:DeviceStatus

}

