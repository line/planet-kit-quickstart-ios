// Copyright 2024 LINE Plus Corporation
//
// LINE Plus Corporation licenses this file to you under the Apache License,
// version 2.0 (the "License"); you may not use this file except in compliance
// with the License. You may obtain a copy of the License at:
//
//   https://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
// WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
// License for the specific language governing permissions and limitations
// under the License.

import UIKit
import PlanetKit

class ViewController: UIViewController {
    
    let myUserId = PlanetKitUserId(id: "", serviceId: "planet-kit-quick-start")
    let roomServiceId = "planet-kit-quick-start"
    let accessToken = ""
    
    @IBOutlet var roomIdLabel: UILabel!
    @IBOutlet var conferenceStateLabel: UILabel!
    @IBOutlet var participantCountLabel: UILabel!
    @IBOutlet var roomIdTextField: UITextField!
    
    var participantCount: Int = 0 {
        didSet {
            participantCountLabel.text = "Participant count: \(String(describing: participantCount))"
        }
    }
    
    var state: String = "" {
        didSet {
            conferenceStateLabel.text = "Conference state: \(state)"
        }
    }
    
    
    @IBAction func joinConference(_ sender: Any) {
        guard let roomId = roomIdTextField.text, roomId.count > 0 else {
            NSLog("please enter room id")
            return
        }
        
        let param = PlanetKitConferenceParam(myUserId: myUserId, roomId: roomId, roomServiceId: roomServiceId, displayName: nil, delegate: self, accessToken: accessToken)
        let result = PlanetKitManager.shared.joinConference(param: param, settings: nil)
        
        
        NSLog("join conference result: \(result.reason)")
    }
    
    @IBAction func leaveConference(_ sender: Any) {
        PlanetKitManager.shared.conference?.leaveConference()
        NSLog("leave conference")
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        participantCount = 0
        state = ""
        roomIdLabel.text = "Room ID"
        // Do any additional setup after loading the view.
    }
}


extension ViewController: PlanetKitConferenceDelegate {
    func didConnect(_ conference: PlanetKit.PlanetKitConference, connected: PlanetKit.PlanetKitConferenceConnectedParam) {
        DispatchQueue.main.async {
            self.state = "connected"
            self.participantCount = 1
        }
    }
    
    func didDisconnect(_ conference: PlanetKitConference, disconnected: PlanetKitDisconnectedParam) {
        DispatchQueue.main.async {
            self.state = "disconnected"
            self.participantCount = 0
            NSLog("disconnected: \(disconnected.reason)")
        }
    }
    
    func peerListDidUpdate(_ conference: PlanetKitConference, updated: PlanetKitConferencePeerListUpdateParam) {
        DispatchQueue.main.async {
            self.participantCount = updated.totalPeersCount + 1
        }
    }
    
    func peersVideoDidUpdate(_ conference: PlanetKitConference, updated: PlanetKitConferenceVideoUpdateParam) {
        // do nothing.
    }
}

