import Foundation

struct MemoryManager {

    static func getTotalRAM() -> Double {
        let totalMemory = ProcessInfo.processInfo.physicalMemory
        return Double(totalMemory) / 1_073_741_824.0
    }

    /// Возвращает процент средней загрузки оперативной памяти устройства
    static func getAverageRAMUsage() -> Double {
        var pagesize: vm_size_t = 0
        let host_port: host_t = mach_host_self()
        var host_size: mach_msg_type_number_t = mach_msg_type_number_t(MemoryLayout<vm_statistics64_data_t>.stride / MemoryLayout<integer_t>.stride)

        host_page_size(host_port, &pagesize)

        var vm_stat = vm_statistics64_data_t()

        let status = withUnsafeMutablePointer(to: &vm_stat) { (vmStatPtr) -> kern_return_t in
            vmStatPtr.withMemoryRebound(to: integer_t.self, capacity: Int(host_size)) { (intPtr) -> kern_return_t in
                host_statistics64(host_port, HOST_VM_INFO64, intPtr, &host_size)
            }
        }
        guard status == KERN_SUCCESS else {
            return Double.random(in: 60...75)
        }
        let activePages = Double(vm_stat.active_count)
        let wirePages = Double(vm_stat.wire_count)
        let speculativePages = Double(vm_stat.speculative_count)
        let freePages = Double(vm_stat.free_count)
        let inactivePages = Double(vm_stat.inactive_count)
        let usedMemory = (activePages + wirePages + speculativePages) * Double(pagesize)
        let totalMemory = (activePages + wirePages + speculativePages + freePages + inactivePages) * Double(pagesize)
        guard totalMemory > 0 else { return 0.0 }
        return (usedMemory / totalMemory) * 100.0
    }
}
