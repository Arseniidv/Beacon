import Foundation


public final class CompletionGate<T > : Any{
    private let lock = NSLock()
    private var isCompleted = false

    public init() {}

    public func tryFinish() -> Bool {
        lock.lock()
        defer { lock.unlock() }

        // Если затвор уже сработал ранее, возвращаем false, чтобы проигнорировать повторный вызов
        guard !isCompleted else { return false }

        isCompleted = true
        return true
    }
}
