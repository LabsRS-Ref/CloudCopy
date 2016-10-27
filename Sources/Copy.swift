/*
 * Copyright 2016 Coodly LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import Foundation
import TalkToCloud
import SWLogger

private struct CloudObject: RemoteRecord, RawFieldsCopy {
    fileprivate var proposedName: String?
    fileprivate var recordChangeTag: String?
    fileprivate var recordName: String?
    fileprivate static var recordType: String {
        return Copy.Static.recordType
    }
    fileprivate var rawFields: [String : AnyObject]!
    
    fileprivate mutating func load(fields: [String : AnyObject]) -> Bool {
        rawFields = fields
        return true
    }
}

class Copy {
    struct Static {
        static var recordType: String = ""
    }
    private let production: CloudContainer
    private let development: CloudContainer
    
    init(production: CloudContainer, development: CloudContainer, record: String) {
        self.production = production
        self.development = development
        Static.recordType = record
    }
    
    func execute() {
        Log.debug("Execute")
        
        let completion: ((CloudResult<CloudObject>) -> ()) = {
            result in
            
            switch result {
            case .success(let fetched, let continuation):
                Log.debug("Fetched \(fetched.count) objects")
                
                var toSave = [CloudObject]()
                for c in fetched {
                    var saved = c
                    saved.recordChangeTag = nil
                    saved.proposedName = saved.recordName
                    saved.recordName = nil
                    toSave.append(saved)
                }
                
                let saveCompletion: ((CloudResult<CloudObject>) -> ()) = {
                    result in
                    
                    switch result {
                    case .success(let saved, _):
                        Log.debug("Saved \(saved.count)")
                        if let c = continuation {
                            Log.debug("Fetch next batch")
                            c()
                        } else {
                            Log.debug("All copied")
                        }
                    case .failure:
                        Log.debug("Save failed")
                    }
                }
                
                self.development.save(records: toSave, completion: saveCompletion)
            case .failure:
                Log.debug("Fetch failed")
            }
        }
        
        production.fetch(completion: completion)
    }
}
