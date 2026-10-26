
import Foundation
import Darwin

struct StorageSnapshot {
    /// Общий объём доступной файловой системы в байтах.
    let totalBytes: Int64

    /// Свободное место в файловой системе в байтах.
    let freeBytes: Int64

    /// Занятое место в файловой системе в байтах.
    var usedBytes: Int64 {
        max(0, totalBytes - freeBytes)
    }

    /// Процент занятого места.
    var usagePercentage: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(usedBytes) / Double(totalBytes) * 100
    }

    var formattedUsed: String {
        ByteCountFormatter.string(
            fromByteCount: usedBytes,
            countStyle: .file
        )
    }

    var formattedTotal: String {
        ByteCountFormatter.string(
            fromByteCount: totalBytes,
            countStyle: .file
        )
    }

    var formattedFree: String {
        ByteCountFormatter.string(
            fromByteCount: freeBytes,
            countStyle: .file
        )
    }
}

struct MemorySnapshot {
    /// Объём физической RAM в байтах.
    let totalBytes: UInt64

    /// Объём RAM, занятый текущим процессом.
    let processResidentBytes: UInt64

    var formattedTotal: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(clamping: totalBytes),
            countStyle: .memory
        )
    }

    var formattedProcessResident: String {
        ByteCountFormatter.string(
            fromByteCount: Int64(clamping: processResidentBytes),
            countStyle: .memory
        )
    }
}

enum StorageManagerError: LocalizedError {
    case unavailableFileSystem
    case memoryReadFailed

    var errorDescription: String? {
        switch self {
        case .unavailableFileSystem:
            return "Не удалось получить данные файловой системы."
        case .memoryReadFailed:
            return "Не удалось получить данные оперативной памяти."
        }
    }
}

final class StorageManager {

    /// Получает объём файловой системы, доступной приложению.
    func fetchStorageSnapshot() throws -> StorageSnapshot {
        let fileURL = URL(
            fileURLWithPath: NSHomeDirectory(),
            isDirectory: true
        )

        let values = try fileURL.resourceValues(
            forKeys: [
                .volumeTotalCapacityKey,
                .volumeAvailableCapacityForImportantUsageKey
            ]
        )

        guard
            let total = values.volumeTotalCapacity,
            total > 0
        else {
            throw StorageManagerError.unavailableFileSystem
        }

        let free: Int64

        if let available = values.volumeAvailableCapacityForImportantUsage {
            free = min(max(0, available), Int64(total))
        } else {
            // Запасной вариант для файловых систем,
            // где показатель important usage недоступен.
            let fallback = try fileURL.resourceValues(
                forKeys: [.volumeAvailableCapacityKey]
            )

            guard let available = fallback.volumeAvailableCapacity else {
                throw StorageManagerError.unavailableFileSystem
            }

            free = min(max(0, Int64(available)), Int64(total))
        }

        return StorageSnapshot(
            totalBytes: Int64(total),
            freeBytes: free
        )
    }

    // MARK: - RAM

    /// Получает общий объём физической RAM и память текущего процесса.
    func fetchMemorySnapshot() throws -> MemorySnapshot {
        let totalMemory = ProcessInfo.processInfo.physicalMemory

        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(
            MemoryLayout<mach_task_basic_info>.size
                / MemoryLayout<natural_t>.size
        )

        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(
                to: integer_t.self,
                capacity: Int(count)
            ) { reboundPointer in
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    reboundPointer,
                    &count
                )
            }
        }

        guard result == KERN_SUCCESS else {
            throw StorageManagerError.memoryReadFailed
        }

        return MemorySnapshot(
            totalBytes: totalMemory,
            processResidentBytes: UInt64(info.resident_size)
        )
    }
}
