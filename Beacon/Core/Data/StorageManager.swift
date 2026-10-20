import Foundation

struct StorageManager{
    static func getTotalDiskSpace() -> String {
            guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
                  let space = attrs[.systemSize] as? Int64 else {
                return "0 ГБ"
            }
            return ByteCountFormatter.string(fromByteCount: space, countStyle: .file)
        }
        // Возвращает строку со свободным объемом диска, доступным для приложения
        static func getFreeDiskSpace() -> String {
            let fileURL = URL(fileURLWithPath: NSTemporaryDirectory())
            do {
                // Ключ для запроса остается прежним (со словом Key)
                let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

                // ИСПРАВЛЕНО: Свойство структуры вызывается без слова Key в конце
                if let capacity = values.volumeAvailableCapacityForImportantUsage {
                    return ByteCountFormatter.string(fromByteCount: capacity, countStyle: .file)
                }
            } catch {
                if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
                   let freeSpace = attrs[.systemFreeSize] as? Int64 {
                    return ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
                }
            }
            return "0 ГБ"
        }
    }

