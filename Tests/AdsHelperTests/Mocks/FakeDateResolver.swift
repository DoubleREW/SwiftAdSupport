import Foundation
@testable import AdsHelper

class FakeDateResolver : DateResolver {
    var resolvedDate: Date = Date()
    
    func now() -> Date {
        return resolvedDate
    }
    
    func setResolvedDate(isoDate: String) {
        let formatter = ISO8601DateFormatter()
        
        self.resolvedDate = formatter.date(from: isoDate)!
    }
}
